# ──────────────────────────────────────────────────────────────────────────────
# micro-monorepo — top-level Makefile
#
# Prerequisites: podman, podman-compose (or docker compose), pnpm, node
#
# Environments: local | staging | production
# Pass ENV=staging to override, e.g.:  make deploy ENV=staging
# ──────────────────────────────────────────────────────────────────────────────

ENV         ?= local
COMPOSE_CMD ?= podman-compose --podman-pull-args="--tls-verify=false"
COMPOSE_FILE = infra/compose.yaml
ENV_FILE     = infra/env/.env.$(ENV)

# Load env file if it exists (silently skip if not)
ifneq (,$(wildcard $(ENV_FILE)))
  include $(ENV_FILE)
  export
endif

.DEFAULT_GOAL := help

# ── Help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help:
	@echo ""
	@echo "Usage: make <target> [ENV=local|staging|production]"
	@echo ""
	@echo "  ── Local development ───────────────────────────────"
	@echo "  dev              Start all apps in watch mode (turbo)"
	@echo "  install          Install pnpm dependencies"
	@echo "  build            Build all packages and apps"
	@echo "  test             Run all tests"
	@echo "  lint             Lint all packages"
	@echo "  clean            Remove build artefacts"
	@echo ""
	@echo "  ── Infrastructure (Podman) ─────────────────────────"
	@echo "  infra-up         Start postgres only (for local dev with pnpm run dev)"
	@echo "  infra-up-full    Build images locally then start full stack"
	@echo "  infra-down       Stop and remove containers"
	@echo "  infra-logs       Tail container logs"
	@echo "  infra-ps         Show running containers"
	@echo "  infra-reset      Stop containers AND delete volumes (destructive)"
	@echo ""
	@echo "  ── Database ────────────────────────────────────────"
	@echo "  db-shell         Open psql inside the postgres container"
	@echo "  db-url           Print the DATABASE_URL for ENV=$(ENV)"
	@echo ""
	@echo "  ── Images ──────────────────────────────────────────"
	@echo "  build-images     Build OCI images for all apps"
	@echo "  push-images      Push images to registry (requires REGISTRY set)"
	@echo ""
	@echo "  ── Deploy ──────────────────────────────────────────"
	@echo "  deploy           SSH deploy via podman compose (needs DEPLOY_HOST)"
	@echo "  deploy-help      Show deploy usage and required variables"
	@echo ""
	@echo "  ENV defaults to 'local'. Use ENV=staging or ENV=production."
	@echo ""

# ── Dependencies ──────────────────────────────────────────────────────────────

.PHONY: install
install:
	pnpm install

# ── Dev ───────────────────────────────────────────────────────────────────────

.PHONY: dev
dev: infra-up
	pnpm run dev

# ── Build / Test / Lint ───────────────────────────────────────────────────────

.PHONY: build
build:
	pnpm run build

.PHONY: test
test:
	pnpm run test

.PHONY: lint
lint:
	pnpm run lint

.PHONY: clean
clean:
	pnpm run clean

# ── Infrastructure ────────────────────────────────────────────────────────────

.PHONY: infra-up
infra-up:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d postgres
	@echo "Waiting for postgres to be healthy..."
	@$(COMPOSE_CMD) -f $(COMPOSE_FILE) exec postgres pg_isready -U $${POSTGRES_USER:-micro} || true

# Builds all app images locally then starts the full stack (postgres + heimdall + references-api)
LOCAL_REGISTRY_OWNER = $(shell git config user.name | tr '[:upper:] ' '[:lower:]-' | tr -cd '[:alnum:]-' | tr -s '-' | sed 's/^-//;s/-$$//')

.PHONY: infra-up-full
infra-up-full:
	$(MAKE) build-images IMAGE_TAG=local
	IMAGE_TAG=local REGISTRY_OWNER=$(LOCAL_REGISTRY_OWNER) \
	  $(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d
	@echo "Stack is up. Services:"
	@$(COMPOSE_CMD) -f $(COMPOSE_FILE) ps

.PHONY: infra-down
infra-down:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) down

.PHONY: infra-logs
infra-logs:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) logs -f

.PHONY: infra-ps
infra-ps:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) ps

.PHONY: infra-reset
infra-reset:
	@echo "WARNING: This will delete all container volumes for ENV=$(ENV)."
	@read -p "Continue? [y/N] " ans && [ "$$ans" = "y" ]
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) down -v

# ── Database ──────────────────────────────────────────────────────────────────

.PHONY: db-shell
db-shell:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) exec postgres \
	  psql -U $${POSTGRES_USER:-micro} -d $${POSTGRES_DB:-micro_dev}

.PHONY: db-url
db-url:
	@echo "postgresql://$${POSTGRES_USER:-micro}:$${POSTGRES_PASSWORD:-micro}@localhost:$${POSTGRES_PORT:-5432}/$${POSTGRES_DB:-micro_dev}"

# ── OCI Images ────────────────────────────────────────────────────────────────

REGISTRY  ?= ghcr.io/$(shell git config user.name | tr '[:upper:] ' '[:lower:]-' | tr -cd '[:alnum:]-' | tr -s '-' | sed 's/^-//;s/-$$//')
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")

APPS = heimdall references-api bifrost

.PHONY: build-images
build-images: $(addprefix build-image-,$(APPS))

build-image-%:
	podman build \
	  --tls-verify=false \
	  -f infra/containerfiles/Containerfile.$* \
	  -t $(REGISTRY)/$*:$(IMAGE_TAG) \
	  .

.PHONY: push-images
push-images: build-images
	@for app in $(APPS); do \
	  podman push $(REGISTRY)/$$app:$(IMAGE_TAG); \
	done

# ── Deploy ────────────────────────────────────────────────────────────────────
# Requires:
#   DEPLOY_HOST  — user@host of the target server
#   IMAGE_TAG    — defaults to current git SHA
#   REGISTRY     — defaults to ghcr.io/<git-user>
#   ENV          — local | staging | production (default: local)
#
# The remote server must have:
#   - podman + podman-compose installed
#   - infra/compose.yaml and infra/env/.env.<ENV> present at ~/infra/
#   - the deploy SSH key in ~/.ssh/authorized_keys

DEPLOY_HOST    ?=
REGISTRY_OWNER  = $(shell echo "$(REGISTRY)" | sed 's|ghcr.io/||')

.PHONY: deploy
deploy:
	@test -n "$(DEPLOY_HOST)" || (echo "Error: DEPLOY_HOST is required, e.g. make deploy DEPLOY_HOST=user@host ENV=staging" && exit 1)
	@echo "Deploying $(IMAGE_TAG) to $(DEPLOY_HOST) [ENV=$(ENV)]"
	ssh $(DEPLOY_HOST) \
	  "IMAGE_TAG=$(IMAGE_TAG) \
	   REGISTRY_OWNER=$(REGISTRY_OWNER) \
	   NODE_ENV=$(ENV) \
	   podman compose -f ~/infra/compose.yaml --env-file ~/infra/env/.env.$(ENV) pull && \
	   podman compose -f ~/infra/compose.yaml --env-file ~/infra/env/.env.$(ENV) up -d --remove-orphans"
	@echo "Deploy complete."

.PHONY: deploy-help
deploy-help:
	@echo ""
	@echo "  ── Deploy ──────────────────────────────────────────"
	@echo "  deploy           SSH into DEPLOY_HOST and run podman compose up"
	@echo ""
	@echo "  Required vars:"
	@echo "    DEPLOY_HOST    user@host of the target server"
	@echo "    ENV            staging | production"
	@echo ""
	@echo "  Example:"
	@echo "    make deploy DEPLOY_HOST=deploy@staging.example.com ENV=staging"
	@echo ""

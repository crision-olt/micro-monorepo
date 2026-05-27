import Fastify from "fastify";
import sensible from "@fastify/sensible";

const app = Fastify({ logger: true });

void app.register(sensible);

app.get("/", async () => {
  return { message: "Hello from Fastify!" };
});

const start = async () => {
  try {
    await app.listen({ port: 3002, host: "0.0.0.0" });
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

void start();

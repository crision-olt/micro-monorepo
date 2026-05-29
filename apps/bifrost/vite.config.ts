import { defineConfig } from "vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import react from "@vitejs/plugin-react";
import federation from "@originjs/vite-plugin-federation";

// Local dev default; overridden at build time via VITE_MFE_REMOTE_URL.
// CI sets this to the GitHub Pages URL of himinbjorg-portal.
const mfeRemoteUrl =
  process.env.VITE_MFE_REMOTE_URL ?? "http://localhost:4001/assets/remoteEntry.js";

export default defineConfig(({ isSsrBuild }) => ({
  server: {
    port: 4000,
  },
  plugins: [
    tanstackStart({ customViteReactPlugin: true }),
    react(),
    !isSsrBuild &&
      federation({
        name: "bifrost",
        remotes: {
          himinbjorgPortal: mfeRemoteUrl,
        },
      }),
  ],
  build: {
    target: "esnext",
  },
}));

import { defineConfig } from "@tanstack/start/config";
import federation from "@originjs/vite-plugin-federation";

// Local dev default; overridden at build time via VITE_MFE_REMOTE_URL.
// CI sets this to the GitHub Pages URL of himinbjorg-portal.
const mfeRemoteUrl =
  process.env.VITE_MFE_REMOTE_URL ?? "http://localhost:4001/assets/remoteEntry.js";

export default defineConfig({
  server: {
    port: 4000,
  },
  vite: {
    plugins: [
      federation({
        name: "bifrost",
        remotes: {
          himinbjorgPortal: mfeRemoteUrl,
        },
        shared: ["react", "react-dom"],
      }),
    ],
    build: {
      target: "esnext",
    },
  },
  routers: {
    ssr: {
      entry: "./src/entry-server.tsx",
    },
    client: {
      entry: "./src/entry-client.tsx",
    },
  },
});

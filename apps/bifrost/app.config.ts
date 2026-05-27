import { defineConfig } from "@tanstack/start/config";
import federation from "@originjs/vite-plugin-federation";

export default defineConfig({
  server: {
    port: 4000,
  },
  vite: {
    plugins: [
      federation({
        name: "bifrost",
        remotes: {
          himinbjorgPortal: "http://localhost:4001/assets/remoteEntry.js",
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

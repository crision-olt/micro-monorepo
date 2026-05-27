import { createFileRoute } from "@tanstack/react-router";
import { Suspense, lazy } from "react";

const RemoteApp = lazy(() => import("himinbjorgPortal/App"));

export const Route = createFileRoute("/mfe")({
  component: () => (
    <Suspense fallback={<div>Loading MFE...</div>}>
      <RemoteApp />
    </Suspense>
  ),
});

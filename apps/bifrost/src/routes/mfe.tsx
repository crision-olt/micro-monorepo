import { createFileRoute } from "@tanstack/react-router";
import { Suspense, lazy, useEffect, useState } from "react";

// Loaded only on the client — avoids SSR hydration mismatches because the
// remote entry is fetched at runtime from a separate origin.
const RemoteApp = lazy(() => import("himinbjorgPortal/App"));

function MfePage() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <div>Loading MFE...</div>;
  }

  return (
    <Suspense fallback={<div>Loading MFE...</div>}>
      <RemoteApp />
    </Suspense>
  );
}

export const Route = createFileRoute("/mfe")({
  component: MfePage,
});

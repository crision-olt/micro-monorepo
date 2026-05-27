import { createRootRoute, Outlet } from "@tanstack/react-router";
import { Meta, Scripts } from "@tanstack/start";
import { Button } from "@repo/ui";
import type { ReactNode } from "react";

function RootDocument({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Shell App</title>
        <Meta />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootLayout() {
  return (
    <RootDocument>
      <nav>
        <Button>Shell Nav</Button>
      </nav>
      <Outlet />
    </RootDocument>
  );
}

export const Route = createRootRoute({
  component: RootLayout,
});

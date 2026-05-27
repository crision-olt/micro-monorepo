import type { HTMLAttributes } from "react";

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  title?: string;
}

export function Card({ title, children, ...props }: CardProps) {
  return (
    <div {...props}>
      {title && <h3>{title}</h3>}
      {children}
    </div>
  );
}

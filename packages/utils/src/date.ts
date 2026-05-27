export function formatDate(date: Date, locale = "en-US"): string {
  return date.toLocaleDateString(locale);
}

export function isValidDate(value: unknown): value is Date {
  return value instanceof Date && !isNaN(value.getTime());
}

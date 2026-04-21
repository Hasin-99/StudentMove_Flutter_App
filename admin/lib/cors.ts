import { getRequestId } from "@/lib/request-context";

/** CORS for Flutter web calling public API routes on this origin. */
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Request-Id, X-Correlation-Id",
  "Access-Control-Expose-Headers": "X-Request-Id",
} as const;

export function jsonWithCors(data: unknown, init?: ResponseInit) {
  const headers = new Headers(init?.headers);
  for (const [k, v] of Object.entries(corsHeaders)) {
    headers.set(k, v);
  }
  const requestId = getRequestId();
  if (requestId) {
    headers.set("X-Request-Id", requestId);
  }
  headers.set("Content-Type", "application/json; charset=utf-8");
  return new Response(JSON.stringify(data), { ...init, headers });
}

export function noContentWithCors(init?: ResponseInit) {
  const headers = new Headers(init?.headers);
  for (const [k, v] of Object.entries(corsHeaders)) {
    headers.set(k, v);
  }
  const requestId = getRequestId();
  if (requestId) {
    headers.set("X-Request-Id", requestId);
  }
  return new Response(null, { ...init, status: init?.status ?? 204, headers });
}

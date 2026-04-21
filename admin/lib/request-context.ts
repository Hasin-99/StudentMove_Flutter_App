import { AsyncLocalStorage } from "node:async_hooks";
import { randomUUID } from "node:crypto";

type RequestContext = {
  requestId: string;
};

const store = new AsyncLocalStorage<RequestContext>();

function extractRequestId(request?: Request) {
  const headerValue =
    request?.headers.get("x-request-id")?.trim() ||
    request?.headers.get("x-correlation-id")?.trim() ||
    "";
  return headerValue || randomUUID();
}

export async function withRequestContext<T>(
  request: Request | undefined,
  fn: () => Promise<T>,
): Promise<T> {
  const requestId = extractRequestId(request);
  return store.run({ requestId }, fn);
}

export function getRequestId(): string | undefined {
  return store.getStore()?.requestId;
}

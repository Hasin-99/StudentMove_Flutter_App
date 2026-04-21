type HybridPath = "firebase" | "prisma_fallback" | "prisma";
import { getRequestId } from "@/lib/request-context";

function diagnosticsEnabled() {
  const raw = String(process.env.ADMIN_RUNTIME_DIAGNOSTICS ?? "1").toLowerCase();
  return raw !== "0" && raw !== "false" && raw !== "off";
}

export function logHybridPath(input: {
  store: string;
  operation: string;
  path: HybridPath;
  reason?: string;
}) {
  if (!diagnosticsEnabled()) return;
  const reasonPart = input.reason ? ` reason=${input.reason}` : "";
  const reqId = getRequestId();
  const reqPart = reqId ? ` req=${reqId}` : "";
  // Keep logs compact so they are easy to query in production logs.
  console.info(
    `[hybrid-diagnostics]${reqPart} store=${input.store} op=${input.operation} path=${input.path}${reasonPart}`,
  );
}

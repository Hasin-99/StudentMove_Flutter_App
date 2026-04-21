import { jsonWithCors } from "@/lib/cors";
import { getRequestId } from "@/lib/request-context";

type ApiErrorInput = {
  code: string;
  message: string;
  status: number;
  details?: Record<string, unknown>;
};

export function apiError(input: ApiErrorInput) {
  return jsonWithCors(
    {
      error: {
        code: input.code,
        message: input.message,
        requestId: getRequestId() ?? null,
        ...(input.details ?? {}),
      },
    },
    { status: input.status },
  );
}

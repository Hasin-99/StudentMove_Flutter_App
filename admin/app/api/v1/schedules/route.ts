import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";
import { listSchedulesForAdmin, scheduleToFlutterSlot } from "@/lib/transit-store";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function GET(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const rows = await listSchedulesForAdmin();
      return jsonWithCors(rows.map(scheduleToFlutterSlot));
    } catch (error) {
      console.error("[api/schedules] GET failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Schedules are temporarily unavailable.",
        status: 503,
      });
    }
  });
}

import { listLiveAnnouncementsForUserFilter } from "@/lib/announcements-store";
import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function GET(request: Request) {
  return withRequestContext(request, async () => {
    try {
      const url = new URL(request.url);
      const email = (url.searchParams.get("email") ?? "").trim().toLowerCase();
      const department = (url.searchParams.get("department") ?? "").trim().toLowerCase();
      const routeCsv = (url.searchParams.get("routes") ?? "").trim();
      const routeSet = new Set<string>(
        routeCsv
          .split(",")
          .map((v) => v.trim().toLowerCase())
          .filter(Boolean),
      );
      const filtered = await listLiveAnnouncementsForUserFilter({
        email,
        department,
        routes: [...routeSet],
      });

      return jsonWithCors(
        filtered.map((r) => ({
          id: r.id,
          title: r.title,
          body: r.body,
          is_pinned: r.isPinned,
          publish_at: r.publishAt.toISOString(),
        })),
      );
    } catch (error) {
      console.error("[api/announcements] GET failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Announcements are temporarily unavailable.",
        status: 503,
      });
    }
  });
}

import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";
import { getPreferredRoutesByEmail, setPreferredRoutesByEmail } from "@/lib/users-store";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function GET(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const url = new URL(req.url);
      const email = String(url.searchParams.get("email") ?? "")
        .trim()
        .toLowerCase();
      if (!email || !email.includes("@")) {
        return apiError({
          code: "invalid_payload",
          message: "A valid email is required.",
          status: 400,
        });
      }

      const routes = await getPreferredRoutesByEmail(email);
      if (routes === null) {
        return apiError({
          code: "user_not_found",
          message: "User not found.",
          status: 404,
        });
      }
      return jsonWithCors({ routes });
    } catch (error) {
      console.error("[api/users/preferences/routes] GET failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Could not load route preferences right now.",
        status: 503,
      });
    }
  });
}

export async function POST(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const body = (await req.json()) as {
        email?: string;
        routes?: string[];
      };
      const email = String(body?.email ?? "").trim().toLowerCase();
      if (!email || !email.includes("@")) {
        return apiError({
          code: "invalid_payload",
          message: "A valid email is required.",
          status: 400,
        });
      }

      const routes = Array.isArray(body?.routes) ? body!.routes : [];
      const ok = await setPreferredRoutesByEmail(email, routes);
      if (!ok) {
        return apiError({
          code: "user_not_found",
          message: "User not found.",
          status: 404,
        });
      }

      return jsonWithCors({ ok: true });
    } catch (error) {
      console.error("[api/users/preferences/routes] POST failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Could not update route preferences right now.",
        status: 503,
      });
    }
  });
}

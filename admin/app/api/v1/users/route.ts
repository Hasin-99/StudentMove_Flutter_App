import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";
import { createPublicUser, mapKnownCreateError } from "@/lib/users-store";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function POST(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const body = (await req.json()) as {
        full_name?: string;
        email?: string;
        phone?: string;
        student_id?: string;
        department?: string;
        password?: string;
      };

      const fullName = String(body?.full_name ?? "").trim();
      const email = String(body?.email ?? "")
        .trim()
        .toLowerCase();
      const phone = String(body?.phone ?? "").trim() || null;
      const studentId = String(body?.student_id ?? "").trim() || null;
      const department = String(body?.department ?? "").trim() || null;
      const password = String(body?.password ?? "");

      if (!fullName || !email || !email.includes("@") || password.length < 8) {
        return apiError({
          code: "invalid_payload",
          message: "Invalid signup payload.",
          status: 400,
        });
      }

      const user = await createPublicUser({
        fullName,
        email,
        phone,
        studentId,
        department,
        password,
      });

      return jsonWithCors({ ok: true, user }, { status: 201 });
    } catch (error) {
      console.error("[api/users] POST failed", error);
      const mapped = mapKnownCreateError(error);
      if (mapped === "user_already_exists") {
        return apiError({
          code: "user_already_exists",
          message: "A user already exists with this email or identifier.",
          status: 409,
        });
      }
      return apiError({
        code: "service_unavailable",
        message: "User signup service is temporarily unavailable.",
        status: 503,
      });
    }
  });
}

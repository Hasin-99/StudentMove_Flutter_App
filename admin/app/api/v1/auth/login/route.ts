import bcrypt from "bcryptjs";
import { prisma } from "@/lib/prisma";
import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function POST(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const body = (await req.json()) as {
        email?: string;
        password?: string;
      };
      const email = String(body?.email ?? "")
        .trim()
        .toLowerCase();
      const password = String(body?.password ?? "");

      if (!email || !password) {
        return apiError({
          code: "invalid_credentials",
          message: "Email and password are required.",
          status: 400,
        });
      }

      const user = await prisma.appUser.findUnique({ where: { email } });
      if (!user || !user.isActive || !user.passwordHash) {
        return apiError({
          code: "invalid_credentials",
          message: "Invalid email or password.",
          status: 401,
        });
      }

      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) {
        return apiError({
          code: "invalid_credentials",
          message: "Invalid email or password.",
          status: 401,
        });
      }

      await prisma.appUser.update({
        where: { id: user.id },
        data: { lastSeenAt: new Date() },
      });

      return jsonWithCors({
        ok: true,
        user: {
          id: user.id,
          full_name: user.fullName,
          email: user.email,
          student_id: user.studentId,
          department: user.department,
        },
      });
    } catch (error) {
      console.error("[api/auth/login] POST failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Login service is temporarily unavailable.",
        status: 503,
      });
    }
  });
}

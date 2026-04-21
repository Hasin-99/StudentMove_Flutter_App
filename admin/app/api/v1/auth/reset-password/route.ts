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
        token?: string;
        new_password?: string;
      };
      const email = String(body?.email ?? "").trim().toLowerCase();
      const token = String(body?.token ?? "").trim();
      const newPassword = String(body?.new_password ?? "");

      if (!email || !token || newPassword.length < 8) {
        return apiError({
          code: "invalid_payload",
          message: "Email, token, and a valid new password are required.",
          status: 400,
        });
      }

      const user = await prisma.appUser.findUnique({ where: { email } });
      if (
        !user ||
        !user.isActive ||
        !user.resetTokenHash ||
        !user.resetTokenExpiresAt ||
        user.resetTokenExpiresAt.getTime() < Date.now()
      ) {
        return apiError({
          code: "invalid_or_expired_token",
          message: "Reset token is invalid or expired.",
          status: 401,
        });
      }

      const tokenOk = await bcrypt.compare(token, user.resetTokenHash);
      if (!tokenOk) {
        return apiError({
          code: "invalid_or_expired_token",
          message: "Reset token is invalid or expired.",
          status: 401,
        });
      }

      const passwordHash = await bcrypt.hash(newPassword, 12);
      await prisma.appUser.update({
        where: { id: user.id },
        data: {
          passwordHash,
          resetTokenHash: null,
          resetTokenExpiresAt: null,
        },
      });

      return jsonWithCors({ ok: true });
    } catch (error) {
      console.error("[api/auth/reset-password] POST failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Password reset service is temporarily unavailable.",
        status: 503,
      });
    }
  });
}

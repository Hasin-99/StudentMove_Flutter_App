"use server";

import { redirect } from "next/navigation";
import { validateAdminLogin } from "@/lib/admin-auth";
import { getSession } from "@/lib/session";

export type LoginState = { error?: string } | null;

export async function loginAction(
  _prev: LoginState,
  formData: FormData,
): Promise<LoginState> {
  let shouldRedirect = false;
  try {
    const email = String(formData.get("email") || "")
      .replace(/\u200B/g, "")
      .trim()
      .toLowerCase();
    const rawPassword = String(formData.get("password") || "");
    // Safari/keychain/paste can occasionally include invisible whitespace.
    const password = rawPassword.replace(/\u200B/g, "").trim();
    const account = await validateAdminLogin(email, password);
    if (!account) {
      return { error: "Invalid email or password." };
    }

    const session = await getSession();
    session.isAdmin = true;
    session.email = account.email;
    session.role = account.role;
    await session.save();
    shouldRedirect = true;
  } catch (error) {
    console.error("[admin-login] loginAction failed", error);
    return { error: "Sign in failed. Please try again." };
  }

  // redirect() throws a special Next.js control-flow error; keep it outside try/catch.
  if (shouldRedirect) {
    redirect("/admin");
  }
  return null;
}

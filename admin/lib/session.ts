import { getIronSession, type SessionOptions } from "iron-session";
import { cookies } from "next/headers";

export type SessionData = {
  isAdmin?: boolean;
  role?: "super_admin" | "transport_admin" | "viewer";
  email?: string;
};

export const sessionOptions: SessionOptions = {
  cookieName: "studentmove_admin",
  password: process.env.ADMIN_SESSION_SECRET ?? "",
  cookieOptions: {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 14,
  },
};

export async function getSession() {
  return getIronSession<SessionData>(await cookies(), sessionOptions);
}

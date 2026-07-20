import { getSession } from "@/lib/session";

export type AdminRole = "super_admin" | "transport_admin" | "viewer";

const rank: Record<AdminRole, number> = {
  viewer: 1,
  transport_admin: 2,
  super_admin: 3,
};

export async function requireRole(minRole: AdminRole) {
  const s = await getSession();
  if (!s.isAdmin) throw new Error("Unauthorized");
  // Missing role must not escalate privileges.
  const role = (s.role ?? "viewer") as AdminRole;
  if (rank[role] < rank[minRole]) throw new Error("Forbidden");
  return role;
}

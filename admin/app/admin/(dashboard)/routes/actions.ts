"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import { requireRole } from "@/lib/permissions";
import { createRouteRecord, deleteRouteById, getRouteById } from "@/lib/transit-store";

async function guard() {
  await requireRole("transport_admin");
}

export async function createRoute(formData: FormData) {
  try {
    await guard();
    const name = String(formData.get("name") || "").trim();
    if (!name) return;
    const code = String(formData.get("code") || "").trim() || null;
    const route = await createRouteRecord(name, code);
    await writeAuditLog({
      action: "route.create",
      targetType: "bus_route",
      targetId: route.id,
      metadata: { name: route.name, code: route.code },
    });
    revalidatePath("/admin/routes");
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_route") {
      console.error("[routes] duplicate route blocked");
      return;
    }
    console.error("[routes] createRoute failed", error);
  }
}

export async function deleteRoute(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return;
    const existing = await getRouteById(id);
    await deleteRouteById(id);
    await writeAuditLog({
      action: "route.delete",
      targetType: "bus_route",
      targetId: id,
      metadata: existing ? { name: existing.name, code: existing.code } : undefined,
    });
    revalidatePath("/admin/routes");
  } catch (error) {
    console.error("[routes] deleteRoute failed", error);
  }
}

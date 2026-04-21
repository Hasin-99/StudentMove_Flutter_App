"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import { requireRole } from "@/lib/permissions";
import { createBusRecord, deleteBusById, getBusById } from "@/lib/transit-store";

async function guard() {
  await requireRole("transport_admin");
}

export async function createBus(formData: FormData) {
  try {
    await guard();
    const code = String(formData.get("code") || "").trim();
    if (!code) return;
    const bus = await createBusRecord(code);
    await writeAuditLog({
      action: "bus.create",
      targetType: "bus",
      targetId: bus.id,
      metadata: { code: bus.code },
    });
    revalidatePath("/admin/buses");
  } catch (error) {
    console.error("[buses] createBus failed", error);
  }
}

export async function deleteBus(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return;
    const existing = await getBusById(id);
    if (!existing) return;
    if (existing.scheduleCount > 0) return;
    await deleteBusById(id);
    await writeAuditLog({
      action: "bus.delete",
      targetType: "bus",
      targetId: id,
      metadata: existing ? { code: existing.code } : undefined,
    });
    revalidatePath("/admin/buses");
  } catch (error) {
    console.error("[buses] deleteBus failed", error);
  }
}

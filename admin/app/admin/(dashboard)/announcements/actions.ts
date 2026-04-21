"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import {
  createAnnouncementRecord,
  deleteAnnouncementById,
  getAnnouncementById,
  updateAnnouncementById,
} from "@/lib/announcements-store";
import { requireRole } from "@/lib/permissions";

export type CreateAnnouncementState = {
  error?: string;
  success?: string;
};

export type UpdateAnnouncementState = {
  error?: string;
  success?: string;
};

async function guard() {
  await requireRole("transport_admin");
}

function parseCsv(raw: string): string[] {
  return raw
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
}

export async function createAnnouncement(
  _prevState: CreateAnnouncementState | null,
  formData: FormData,
): Promise<CreateAnnouncementState | null> {
  try {
    await guard();
    const title = String(formData.get("title") || "").trim();
    const body = String(formData.get("body") || "").trim();
    const publishAtRaw = String(formData.get("publishAt") || "").trim();
    const expiresAtRaw = String(formData.get("expiresAt") || "").trim();
    const targetDepartmentsRaw = String(formData.get("targetDepartments") || "").trim();
    const targetRoutesRaw = String(formData.get("targetRoutes") || "").trim();
    const isPinned = String(formData.get("isPinned") || "") === "on";
    const isActive = String(formData.get("isActive") || "") === "on";

    if (!title || !body) return { error: "Title and body are required." };

    const publishAt = publishAtRaw ? new Date(publishAtRaw) : new Date();
    const expiresAt = expiresAtRaw ? new Date(expiresAtRaw) : null;
    if (Number.isNaN(publishAt.getTime())) return { error: "Invalid publish time." };
    if (expiresAt && Number.isNaN(expiresAt.getTime())) return { error: "Invalid expiry time." };

    const targetDepartments = parseCsv(targetDepartmentsRaw);
    const targetRoutes = parseCsv(targetRoutesRaw);

    const id = await createAnnouncementRecord({
      title,
      body,
      targetDepartments,
      targetRoutes,
      isPinned,
      isActive,
      publishAt,
      expiresAt,
    });

    await writeAuditLog({
      action: "announcement.create",
      targetType: "announcement",
      targetId: id,
      metadata: {
        title,
        isPinned,
        isActive,
        publishAt,
        expiresAt,
        targetDepartments,
        targetRoutes,
      },
    });

    revalidatePath("/admin/announcements");
    return { success: "Announcement created successfully." };
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_announcement") {
      return {
        error:
          "Duplicate announcement blocked for the same publish date/time minute. Change publish time or content.",
      };
    }
    console.error("[announcements] createAnnouncement failed", error);
    return { error: "Could not create announcement. Please try again." };
  }
}

export async function updateAnnouncement(
  _prevState: UpdateAnnouncementState | null,
  formData: FormData,
): Promise<UpdateAnnouncementState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "").trim();
    const title = String(formData.get("title") || "").trim();
    const body = String(formData.get("body") || "").trim();
    const publishAtRaw = String(formData.get("publishAt") || "").trim();
    const expiresAtRaw = String(formData.get("expiresAt") || "").trim();
    const targetDepartmentsRaw = String(formData.get("targetDepartments") || "").trim();
    const targetRoutesRaw = String(formData.get("targetRoutes") || "").trim();
    const isPinned = String(formData.get("isPinned") || "") === "on";
    const isActive = String(formData.get("isActive") || "") === "on";

    if (!id || !title || !body) return { error: "Title and body are required." };
    const publishAt = publishAtRaw ? new Date(publishAtRaw) : new Date();
    const expiresAt = expiresAtRaw ? new Date(expiresAtRaw) : null;
    if (Number.isNaN(publishAt.getTime())) return { error: "Invalid publish time." };
    if (expiresAt && Number.isNaN(expiresAt.getTime())) return { error: "Invalid expiry time." };

    const targetDepartments = parseCsv(targetDepartmentsRaw);
    const targetRoutes = parseCsv(targetRoutesRaw);

    await updateAnnouncementById(id, {
      title,
      body,
      publishAt,
      expiresAt,
      targetDepartments,
      targetRoutes,
      isPinned,
      isActive,
    });
    await writeAuditLog({
      action: "announcement.update",
      targetType: "announcement",
      targetId: id,
      metadata: { title, publishAt, expiresAt, targetDepartments, targetRoutes, isPinned, isActive },
    });
    revalidatePath("/admin/announcements");
    return { success: "Announcement updated successfully." };
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_announcement") {
      return {
        error:
          "Duplicate announcement blocked for the same publish date/time minute. Change publish time or content.",
      };
    }
    console.error("[announcements] updateAnnouncement failed", error);
    return { error: "Could not update announcement. Please try again." };
  }
}

export async function publishAnnouncementNow(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "").trim();
    if (!id) return;
    await updateAnnouncementById(id, { isActive: true, publishAt: new Date() });
    await writeAuditLog({
      action: "announcement.publish_now",
      targetType: "announcement",
      targetId: id,
    });
    revalidatePath("/admin/announcements");
  } catch (error) {
    console.error("[announcements] publishAnnouncementNow failed", error);
  }
}

export async function toggleAnnouncementActive(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return;
    const row = await getAnnouncementById(id);
    if (!row) return;
    await updateAnnouncementById(id, { isActive: !row.isActive });
    await writeAuditLog({
      action: "announcement.toggle_active",
      targetType: "announcement",
      targetId: id,
      metadata: { from: row.isActive, to: !row.isActive, title: row.title },
    });
    revalidatePath("/admin/announcements");
  } catch (error) {
    console.error("[announcements] toggleAnnouncementActive failed", error);
  }
}

export async function deleteAnnouncement(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return;
    const row = await getAnnouncementById(id);
    await deleteAnnouncementById(id);
    await writeAuditLog({
      action: "announcement.delete",
      targetType: "announcement",
      targetId: id,
      metadata: row ? { title: row.title } : undefined,
    });
    revalidatePath("/admin/announcements");
  } catch (error) {
    console.error("[announcements] deleteAnnouncement failed", error);
  }
}

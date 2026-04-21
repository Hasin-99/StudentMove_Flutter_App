"use server";

import { writeAuditLog } from "@/lib/audit-log";
import { changeAdminPassword, resetAdminPasswordBySuperAdmin } from "@/lib/security-store";
import { getSession } from "@/lib/session";

export type ChangePasswordState = {
  error?: string;
  success?: string;
} | null;

export type ResetAdminPasswordState = {
  error?: string;
  success?: string;
} | null;

export async function changePasswordAction(
  _prev: ChangePasswordState,
  formData: FormData,
): Promise<ChangePasswordState> {
  try {
    const session = await getSession();
    if (!session.isAdmin || !session.email) {
      return { error: "Unauthorized session. Please sign in again." };
    }

    const currentPassword = String(formData.get("currentPassword") || "");
    const newPassword = String(formData.get("newPassword") || "");
    const confirmPassword = String(formData.get("confirmPassword") || "");

    if (!currentPassword || !newPassword || !confirmPassword) {
      return { error: "All fields are required." };
    }
    if (newPassword.length < 8) {
      return { error: "New password must be at least 8 characters." };
    }
    if (newPassword !== confirmPassword) {
      return { error: "New password and confirm password do not match." };
    }
    if (newPassword === currentPassword) {
      return { error: "New password must be different from current password." };
    }

    const result = await changeAdminPassword(
      session.email.toLowerCase(),
      currentPassword,
      newPassword,
    );
    if (!result.ok) {
      if (result.reason === "invalid_current") {
        return { error: "Current password is incorrect." };
      }
      return { error: "Admin account not found or inactive." };
    }
    await writeAuditLog({
      action: "admin.change_password",
      targetType: "admin_account",
      targetId: result.id,
      metadata: { email: result.email },
    });

    return { success: "Password updated successfully." };
  } catch (error) {
    console.error("[security] changePasswordAction failed", error);
    return { error: "Could not update password. Please try again." };
  }
}

export async function resetAdminPasswordAction(
  _prev: ResetAdminPasswordState,
  formData: FormData,
): Promise<ResetAdminPasswordState> {
  try {
    const session = await getSession();
    if (!session.isAdmin || session.role !== "super_admin") {
      return { error: "Only super admins can reset admin passwords." };
    }

    const targetEmail = String(formData.get("targetEmail") || "").trim().toLowerCase();
    const newPassword = String(formData.get("newPassword") || "");
    const confirmPassword = String(formData.get("confirmPassword") || "");

    if (!targetEmail || !targetEmail.includes("@")) {
      return { error: "A valid target admin email is required." };
    }
    if (!newPassword || !confirmPassword) {
      return { error: "All fields are required." };
    }
    if (newPassword.length < 8) {
      return { error: "New password must be at least 8 characters." };
    }
    if (newPassword !== confirmPassword) {
      return { error: "New password and confirm password do not match." };
    }

    const result = await resetAdminPasswordBySuperAdmin(targetEmail, newPassword);
    if (!result.ok) {
      if (result.reason === "not_admin") {
        return { error: "Target account is not an admin." };
      }
      return { error: "Target admin account not found or inactive." };
    }

    await writeAuditLog({
      action: "admin.super_reset_password",
      targetType: "admin_account",
      targetId: result.id,
      metadata: { email: result.email, issuedBy: session.email },
    });
    return { success: "Admin password reset successfully." };
  } catch (error) {
    console.error("[security] resetAdminPasswordAction failed", error);
    return { error: "Could not reset admin password. Please try again." };
  }
}

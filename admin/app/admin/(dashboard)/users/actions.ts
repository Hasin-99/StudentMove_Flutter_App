"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import { requireRole } from "@/lib/permissions";
import {
  createUserRecord,
  deleteUserById,
  resetUserPasswordById,
  setUserResetTokenById,
  toggleUserActiveById,
  updateUserById,
} from "@/lib/users-store";

export type CreateUserState = {
  error?: string;
  success?: string;
};

export type UpdateUserState = {
  error?: string;
  success?: string;
};

export type UserActionState = {
  error?: string;
  success?: string;
};

async function guard() {
  await requireRole("super_admin");
}

function parseRole(raw: string) {
  if (raw === "SUPER_ADMIN" || raw === "TRANSPORT_ADMIN") return raw;
  return "VIEWER";
}

export async function createUser(
  _prevState: CreateUserState | null,
  formData: FormData,
): Promise<CreateUserState | null> {
  try {
    await guard();
    const fullName = String(formData.get("fullName") || "").trim();
    const email = String(formData.get("email") || "")
      .trim()
      .toLowerCase();
    const phone = String(formData.get("phone") || "").trim() || null;
    const studentId = String(formData.get("studentId") || "").trim() || null;
    const department = String(formData.get("department") || "").trim() || null;
    const role = parseRole(String(formData.get("role") || "VIEWER"));
    const password = String(formData.get("password") || "");

    if (!fullName || !email) return { error: "Full name and email are required." };
    const created = await createUserRecord({
      fullName,
      email,
      phone,
      studentId,
      department,
      role,
      password: password.length >= 8 ? password : undefined,
    });
    await writeAuditLog({
      action: "user.create",
      targetType: "app_user",
      targetId: created.id,
      metadata: { email: created.email, role: created.role },
    });
    revalidatePath("/admin/users");
    revalidatePath("/admin");
    return { success: "User created successfully." };
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_email") {
      return { error: "A user with this email already exists." };
    }
    if (error instanceof Error && error.message === "duplicate_student_id") {
      return { error: "A user with this Student ID already exists." };
    }
    console.error("[users] createUser failed", error);
    return { error: "Could not create user. Please try again." };
  }
}

export async function toggleUserActive(
  _prevState: UserActionState | null,
  formData: FormData,
): Promise<UserActionState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return { error: "User ID is required." };

    const updated = await toggleUserActiveById(id);
    await writeAuditLog({
      action: "user.toggle_active",
      targetType: "app_user",
      targetId: id,
      metadata: { from: updated.from, to: updated.to, email: updated.email },
    });
    revalidatePath("/admin/users");
    revalidatePath("/admin");
    return { success: updated.to ? "User activated." : "User deactivated." };
  } catch (error) {
    console.error("[users] toggleUserActive failed", error);
    return { error: "Could not update active status. Please try again." };
  }
}

export async function updateUser(
  _prevState: UpdateUserState | null,
  formData: FormData,
): Promise<UpdateUserState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    const fullName = String(formData.get("fullName") || "").trim();
    const email = String(formData.get("email") || "")
      .trim()
      .toLowerCase();
    const phone = String(formData.get("phone") || "").trim() || null;
    const studentId = String(formData.get("studentId") || "").trim() || null;
    const department = String(formData.get("department") || "").trim() || null;
    const role = parseRole(String(formData.get("role") || "VIEWER"));

    if (!id || !fullName || !email) return { error: "Full name and email are required." };

    await updateUserById(id, { fullName, email, phone, studentId, department, role });
    await writeAuditLog({
      action: "user.update",
      targetType: "app_user",
      targetId: id,
      metadata: { email, role, fullName, studentId, department },
    });
    revalidatePath("/admin/users");
    revalidatePath("/admin");
    return { success: "User updated successfully." };
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_email") {
      return { error: "A user with this email already exists." };
    }
    if (error instanceof Error && error.message === "duplicate_student_id") {
      return { error: "A user with this Student ID already exists." };
    }
    console.error("[users] updateUser failed", error);
    return { error: "Could not update user. Please try again." };
  }
}

export async function deleteUser(
  _prevState: UserActionState | null,
  formData: FormData,
): Promise<UserActionState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return { error: "User ID is required." };
    const existing = await deleteUserById(id);
    await writeAuditLog({
      action: "user.delete",
      targetType: "app_user",
      targetId: id,
      metadata: existing
        ? { email: existing.email, fullName: existing.fullName, role: existing.role }
        : undefined,
    });
    revalidatePath("/admin/users");
    revalidatePath("/admin");
    return { success: "User deleted." };
  } catch (error) {
    console.error("[users] deleteUser failed", error);
    return { error: "Could not delete user. Please try again." };
  }
}

export async function resetUserPassword(
  _prevState: UserActionState | null,
  formData: FormData,
): Promise<UserActionState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    const newPassword = String(formData.get("newPassword") || "");
    if (!id) return { error: "User ID is required." };
    if (newPassword.length < 8) return { error: "Password must be at least 8 characters." };

    await resetUserPasswordById(id, newPassword);
    await writeAuditLog({
      action: "user.set_password",
      targetType: "app_user",
      targetId: id,
    });
    revalidatePath("/admin/users");
    return { success: "Password updated." };
  } catch (error) {
    console.error("[users] resetUserPassword failed", error);
    return { error: "Could not set password. Please try again." };
  }
}

export async function setUserResetToken(
  _prevState: UserActionState | null,
  formData: FormData,
): Promise<UserActionState | null> {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    const resetToken = String(formData.get("resetToken") || "").trim();
    const validMinutes = Number(String(formData.get("validMinutes") || "30"));
    if (!id) return { error: "User ID is required." };
    if (resetToken.length < 4) return { error: "Reset token must be at least 4 characters." };

    const ttl = await setUserResetTokenById(id, resetToken, validMinutes);
    await writeAuditLog({
      action: "user.set_reset_token",
      targetType: "app_user",
      targetId: id,
      metadata: { validMinutes: ttl },
    });
    revalidatePath("/admin/users");
    return { success: `Reset token saved for ${ttl} minutes.` };
  } catch (error) {
    console.error("[users] setUserResetToken failed", error);
    return { error: "Could not save reset token. Please try again." };
  }
}

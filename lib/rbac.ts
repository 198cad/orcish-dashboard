// lib/rbac.ts
import { db } from "@/database/connection/postgres";
import { userRoles, roles, rolePermissions, permissions } from "@/database/schema/schema";
import { eq, inArray } from "drizzle-orm";

export async function getUserPermissions(userId: string) {
  const userRolesData = await db
    .select({
      roleId: userRoles.roleId,
    })
    .from(userRoles)
    .where(eq(userRoles.userId, userId));

  const roleIds = userRolesData.map((ur) => ur.roleId);

  const permissionsData = await db
    .select({
      permissionName: permissions.permissionName,
    })
    .from(rolePermissions)
    .innerJoin(permissions, eq(rolePermissions.permissionId, permissions.permissionId))
    .where(inArray(rolePermissions.roleId, roleIds));

  return permissionsData.map((p) => p.permissionName);
}

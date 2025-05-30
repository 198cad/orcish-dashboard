// scripts/seed.ts

import { db } from "@/database/connection/postgres";
import { users, roles, userRoles } from "@/database/schema/schema";
import { hashPassword } from "@/lib/hash";
import { eq } from "drizzle-orm";

async function seed() {
  const superadminEmail = "superadmin@example.com";
  const superadminUsername = "superadmin";
  const superadminPassword = "supersecure123";

  const existingUser = await db.query.users.findFirst({
    where: eq(users.email, superadminEmail),
  });

  if (existingUser) {
    console.log("✅ Superadmin already exists");
    return;
  }

  const hashedPassword = await hashPassword(superadminPassword);

  // Buat user baru
  const [createdUser] = await db
    .insert(users)
    .values({
      email: superadminEmail,
      username: superadminUsername,
      passwordHash: hashedPassword,
      isActive: true,
    })
    .returning();

  // Cek atau buat role superadmin
  let superadminRole = await db.query.roles.findFirst({
    where: eq(roles.roleName, "superadmin"),
  });

  if (!superadminRole) {
    const [createdRole] = await db
      .insert(roles)
      .values({
        roleName: "superadmin",
        description: "Super Admin with all permissions",
        createdBy: createdUser.userId,
      })
      .returning();
    superadminRole = createdRole;
  }

  // Assign role ke user
  await db.insert(userRoles).values({
    userId: createdUser.userId,
    roleId: superadminRole.roleId,
    assignedBy: createdUser.userId,
  });

  console.log("🎉 Superadmin seeded");
}

seed()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

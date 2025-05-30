import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  timestamp,
  primaryKey,
  jsonb,
  index,
  unique,
} from "drizzle-orm/pg-core";

export const users = pgTable(
  "users",
  {
    userId: uuid("user_id").primaryKey().defaultRandom(),
    username: varchar("username", { length: 255 }).notNull().unique(),
    email: varchar("email", { length: 255 }).notNull().unique(),
    passwordHash: text("password_hash").notNull(),
    isActive: boolean("is_active").default(true),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid("created_by").references((): any => users.userId, {
      onDelete: "set null",
    }),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow()
      .$onUpdate(() => new Date()),
    updatedBy: uuid("updated_by").references((): any => users.userId, {
      onDelete: "set null",
    }),
  },
  (table) => {
    return {
      usernameIdx: unique("idx_users_username").on(table.username),
      emailIdx: unique("idx_users_email").on(table.email),
    };
  }
);

export const roles = pgTable(
  "roles",
  {
    roleId: uuid("role_id").primaryKey().defaultRandom(),
    roleName: varchar("role_name", { length: 100 }).notNull().unique(),
    description: text("description"),
    parentRoleId: uuid("parent_role_id").references((): any => roles.roleId, {
      onDelete: "set null",
    }),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid("created_by").references(() => users.userId, {
      onDelete: "set null",
    }),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow()
      .$onUpdate(() => new Date()),
    updatedBy: uuid("updated_by").references(() => users.userId, {
      onDelete: "set null",
    }),
  },
  (table) => {
    return {
      roleNameIdx: unique("idx_roles_role_name").on(table.roleName),
      parentRoleIdIdx: index("idx_roles_parent_role_id").on(table.parentRoleId),
    };
  }
);

export const permissions = pgTable(
  "permissions",
  {
    permissionId: uuid("permission_id").primaryKey().defaultRandom(),
    permissionName: varchar("permission_name", { length: 100 }).notNull().unique(),
    description: text("description"),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid("created_by").references(() => users.userId, {
      onDelete: "set null",
    }),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow()
      .$onUpdate(() => new Date()),
    updatedBy: uuid("updated_by").references(() => users.userId, {
      onDelete: "set null",
    }),
  },
  (table) => {
    return {
      permissionNameIdx: unique("idx_permissions_permission_name").on(table.permissionName),
    };
  }
);

export const userRoles = pgTable(
  "user_roles",
  {
    userId: uuid("user_id")
      .notNull()
      .references(() => users.userId, { onDelete: "cascade" }),
    roleId: uuid("role_id")
      .notNull()
      .references(() => roles.roleId, { onDelete: "cascade" }),
    assignedAt: timestamp("assigned_at", { withTimezone: true }).notNull().defaultNow(),
    assignedBy: uuid("assigned_by").references(() => users.userId, {
      onDelete: "set null",
    }),
  },
  (table) => {
    return {
      pk: primaryKey({ columns: [table.userId, table.roleId] }),
      userIdIdx: index("idx_user_roles_user_id").on(table.userId),
      roleIdIdx: index("idx_user_roles_role_id").on(table.roleId),
    };
  }
);

export const rolePermissions = pgTable(
  "role_permissions",
  {
    roleId: uuid("role_id")
      .notNull()
      .references(() => roles.roleId, { onDelete: "cascade" }),
    permissionId: uuid("permission_id")
      .notNull()
      .references(() => permissions.permissionId, { onDelete: "cascade" }),
    assignedAt: timestamp("assigned_at", { withTimezone: true }).notNull().defaultNow(),
    assignedBy: uuid("assigned_by").references(() => users.userId, {
      onDelete: "set null",
    }),
  },
  (table) => {
    return {
      pk: primaryKey({ columns: [table.roleId, table.permissionId] }),
      roleIdIdx: index("idx_role_permissions_role_id").on(table.roleId),
      permissionIdIdx: index("idx_role_permissions_permission_id").on(table.permissionId),
    };
  }
);

export const objectTypes = pgTable(
  "object_types",
  {
    objectTypeId: uuid("object_type_id").primaryKey().defaultRandom(),
    typeName: varchar("type_name", { length: 100 }).notNull().unique(),
    description: text("description"),
  },
  (table) => {
    return {
      typeNameIdx: unique("idx_object_types_type_name").on(table.typeName),
    };
  }
);

export const objectPermissions = pgTable(
  "object_permissions",
  {
    objectPermissionId: uuid("object_permission_id").primaryKey().defaultRandom(),
    userId: uuid("user_id").references(() => users.userId, {
      onDelete: "cascade",
    }),
    roleId: uuid("role_id").references(() => roles.roleId, {
      onDelete: "cascade",
    }),
    objectTypeId: uuid("object_type_id")
      .notNull()
      .references(() => objectTypes.objectTypeId, { onDelete: "cascade" }),
    objectId: text("object_id").notNull(),
    permissionId: uuid("permission_id")
      .notNull()
      .references(() => permissions.permissionId, { onDelete: "cascade" }),
    grantedAt: timestamp("granted_at", { withTimezone: true }).notNull().defaultNow(),
    grantedBy: uuid("granted_by").references(() => users.userId, {
      onDelete: "set null",
    }),
    revokedAt: timestamp("revoked_at", { withTimezone: true }),
    isActive: boolean("is_active").notNull().default(true),
    appliesTo: varchar("applies_to", { length: 10 }).notNull(),
  },
  (table) => {
    return {
      userIdIdx: index("idx_obj_perm_user_id").on(table.userId),
      roleIdIdx: index("idx_obj_perm_role_id").on(table.roleId),
      objectTypeIdIdx: index("idx_obj_perm_object_type_id").on(table.objectTypeId),
      objectIdIdx: index("idx_obj_perm_object_id").on(table.objectId),
      permissionIdIdx: index("idx_obj_perm_permission_id").on(table.permissionId),
    };
  }
);

export const auditLog = pgTable(
  "audit_log",
  {
    logId: uuid("log_id").primaryKey().defaultRandom(),
    userId: uuid("user_id").references(() => users.userId, {
      onDelete: "set null",
    }),
    actionType: varchar("action_type", { length: 100 }).notNull(),
    tableName: varchar("table_name", { length: 100 }),
    recordId: text("record_id"),
    oldValue: jsonb("old_value"),
    newValue: jsonb("new_value"),
    timestamp: timestamp("timestamp", { withTimezone: true }).notNull().defaultNow(),
    ipAddress: text("ip_address"), // Menggunakan text karena tidak ada tipe inet bawaan
    userAgent: text("user_agent"),
  },
  (table) => {
    return {
      userIdIdx: index("idx_audit_log_user_id").on(table.userId),
      actionTypeIdx: index("idx_audit_log_action_type").on(table.actionType),
      timestampIdx: index("idx_audit_log_timestamp").on(table.timestamp),
    };
  }
);

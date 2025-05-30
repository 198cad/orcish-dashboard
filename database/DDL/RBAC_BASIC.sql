-- Pastikan ekstensi 'uuid-ossp' terinstal jika Anda ingin menggunakan UUID yang dihasilkan oleh database.
-- Anda bisa menginstalnya dengan perintah ini jika belum ada:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

---
-- Tabel: users
---
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Menggunakan UUID untuk fleksibilitas
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NULL, -- Akan direferensikan sendiri, jadi biarkan NULLable dulu, akan diupdate
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NULL, -- Akan direferensikan sendiri, jadi biarkan NULLable dulu, akan diupdate

    -- Self-referencing Foreign Keys untuk audit trails
    CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Menambahkan indeks pada kolom yang sering diakses
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

---
-- Tabel: roles
---
CREATE TABLE IF NOT EXISTS roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    parent_role_id UUID NULL, -- Untuk hierarki peran
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NULL,

    CONSTRAINT fk_roles_parent_role FOREIGN KEY (parent_role_id) REFERENCES roles(role_id) ON DELETE SET NULL,
    CONSTRAINT fk_roles_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_roles_role_name ON roles (role_name);
CREATE INDEX IF NOT EXISTS idx_roles_parent_role_id ON roles (parent_role_id);

---
-- Tabel: permissions
---
CREATE TABLE IF NOT EXISTS permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NULL,

    CONSTRAINT fk_permissions_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_permissions_updated_by FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_permissions_permission_name ON permissions (permission_name);

---
-- Tabel: user_roles (Junction Table)
---
CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assigned_by UUID NULL,

    PRIMARY KEY (user_id, role_id), -- Komposit kunci utama
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

---
-- Tabel: role_permissions (Junction Table)
---
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assigned_by UUID NULL,

    PRIMARY KEY (role_id, permission_id), -- Komposit kunci utama
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions (role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions (permission_id);

---
-- Tabel: object_types (Untuk Contextual RBAC)
---
CREATE TABLE IF NOT EXISTS object_types (
    object_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_object_types_type_name ON object_types (type_name);

---
-- Tabel: object_permissions (Untuk Contextual RBAC - Izin per Objek)
---
CREATE TABLE IF NOT EXISTS object_permissions (
    object_permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NULL,
    role_id UUID NULL,
    object_type_id UUID NOT NULL,
    object_id TEXT NOT NULL, -- UUID atau BIGINT dari tabel objek eksternal, disimpan sebagai TEXT
    permission_id UUID NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    granted_by UUID NULL,
    revoked_at TIMESTAMP WITH TIME ZONE NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    applies_to VARCHAR(10) NOT NULL, -- 'USER' atau 'ROLE'

    CONSTRAINT fk_obj_perm_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_obj_perm_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_obj_perm_obj_type FOREIGN KEY (object_type_id) REFERENCES object_types(object_type_id) ON DELETE CASCADE,
    CONSTRAINT fk_obj_perm_permission FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT fk_obj_perm_granted_by FOREIGN KEY (granted_by) REFERENCES users(user_id) ON DELETE SET NULL,

    -- Constraint untuk memastikan hanya user_id ATAU role_id yang non-NULL
    CONSTRAINT chk_user_or_role_id CHECK (
        (user_id IS NOT NULL AND role_id IS NULL AND applies_to = 'USER') OR
        (user_id IS NULL AND role_id IS NOT NULL AND applies_to = 'ROLE')
    )
);

CREATE INDEX IF NOT EXISTS idx_obj_perm_user_id ON object_permissions (user_id);
CREATE INDEX IF NOT EXISTS idx_obj_perm_role_id ON object_permissions (role_id);
CREATE INDEX IF NOT EXISTS idx_obj_perm_object_type_id ON object_permissions (object_type_id);
CREATE INDEX IF NOT EXISTS idx_obj_perm_object_id ON object_permissions (object_id);
CREATE INDEX IF NOT EXISTS idx_obj_perm_permission_id ON object_permissions (permission_id);

---
-- Tabel: audit_log
---
CREATE TABLE IF NOT EXISTS audit_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NULL, -- Pengguna yang melakukan aksi (bisa NULL jika aksi otomatis sistem)
    action_type VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NULL, -- Nama tabel yang terpengaruh
    record_id TEXT NULL, -- ID record yang terpengaruh (disimpan sebagai TEXT untuk fleksibilitas)
    old_value JSONB NULL, -- Data lama sebelum perubahan
    new_value JSONB NULL, -- Data baru setelah perubahan
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address INET NULL,
    user_agent TEXT NULL,
    
    CONSTRAINT fk_audit_log_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action_type ON audit_log (action_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log (timestamp);
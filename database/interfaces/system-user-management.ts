import { z } from "zod";

// 1. Users Schema
export const UserSchema = z.object({
  user_id: z.string().uuid().optional(), // UUID, opsional untuk input baru
  username: z
    .string()
    .min(3, "Username harus memiliki minimal 3 karakter")
    .max(50, "Username tidak boleh lebih dari 50 karakter"),
  password_hash: z
    .string()
    .min(8, "Password hash harus memiliki minimal 8 karakter"), // Ini untuk hash, bukan password mentah
  email: z
    .string()
    .email("Format email tidak valid")
    .max(255, "Email tidak boleh lebih dari 255 karakter"),
  full_name: z
    .string()
    .max(150, "Nama lengkap tidak boleh lebih dari 150 karakter")
    .nullable()
    .optional(),
  phone_number: z
    .string()
    .max(50, "Nomor telepon tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  is_active: z.boolean().default(true).optional(),
  last_login_at: z.string().datetime().nullable().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// Schema untuk input form user (tanpa user_id, created_at, updated_at, last_login_at, password_hash)
export const UserFormSchema = z.object({
  username: z
    .string()
    .min(3, "Username harus memiliki minimal 3 karakter")
    .max(50, "Username tidak boleh lebih dari 50 karakter"),
  password: z.string().min(8, "Password harus memiliki minimal 8 karakter"), // Ini untuk password mentah
  email: z
    .string()
    .email("Format email tidak valid")
    .max(255, "Email tidak boleh lebih dari 255 karakter"),
  full_name: z
    .string()
    .max(150, "Nama lengkap tidak boleh lebih dari 150 karakter")
    .nullable()
    .optional(),
  phone_number: z
    .string()
    .max(50, "Nomor telepon tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  is_active: z.boolean().default(true).optional(),
});

// 2. Roles Schema
export const RoleSchema = z.object({
  role_id: z.string().uuid().optional(),
  role_name: z
    .string()
    .min(1, "Nama peran tidak boleh kosong")
    .max(50, "Nama peran tidak boleh lebih dari 50 karakter"),
  description: z.string().nullable().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 3. Permissions Schema
export const PermissionSchema = z.object({
  permission_id: z.string().uuid().optional(),
  permission_name: z
    .string()
    .min(1, "Nama izin tidak boleh kosong")
    .max(100, "Nama izin tidak boleh lebih dari 100 karakter"),
  description: z.string().nullable().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 4. UserRoles Schema (Junction Table)
export const UserRoleSchema = z.object({
  user_id: z.string().uuid(),
  role_id: z.string().uuid(),
});

// 5. RolePermissions Schema (Junction Table)
export const RolePermissionSchema = z.object({
  role_id: z.string().uuid(),
  permission_id: z.string().uuid(),
});

// 6. AuditLogs Schema
export const AuditLogSchema = z.object({
  log_id: z.number().int().positive().optional(), // BIGSERIAL
  user_id: z.string().uuid().nullable().optional(),
  action_type: z
    .string()
    .max(50, "Tipe aksi tidak boleh lebih dari 50 karakter"),
  table_name: z
    .string()
    .max(100, "Nama tabel tidak boleh lebih dari 100 karakter")
    .nullable()
    .optional(),
  record_id: z.string().uuid().nullable().optional(),
  old_data: z.record(z.string(), z.any()).nullable().optional(), // JSONB
  new_data: z.record(z.string(), z.any()).nullable().optional(), // JSONB
  ip_address: z.string().ip().nullable().optional(), // INET
  user_agent: z.string().nullable().optional(),
  additional_info: z.record(z.string(), z.any()).nullable().optional(), // JSONB
  timestamp: z.string().datetime().optional(),
});

// 7. DocumentVersions Schema
export const DocumentVersionSchema = z.object({
  version_id: z.number().int().positive().optional(), // BIGSERIAL
  document_type: z
    .string()
    .max(50, "Tipe dokumen tidak boleh lebih dari 50 karakter"),
  document_id: z.string().uuid(),
  version_number: z.number().int().positive(),
  changes: z.record(z.string(), z.any()).nullable().optional(), // JSONB
  full_document_snapshot: z.record(z.string(), z.any()).nullable().optional(), // JSONB
  changed_by: z.string().uuid().nullable().optional(),
  changed_at: z.string().datetime().optional(),
});

// 8. Notifications Schema
export const NotificationSchema = z.object({
  notification_id: z.string().uuid().optional(),
  user_id: z.string().uuid(),
  message: z.string().min(1, "Pesan notifikasi tidak boleh kosong"),
  notification_type: z
    .string()
    .max(50, "Tipe notifikasi tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  link: z.string().nullable().optional(),
  is_read: z.boolean().default(false).optional(),
  priority: z
    .enum(["High", "Medium", "Low", "Critical"])
    .default("Medium") // Mengubah default dari "Normal" menjadi "Medium" agar sesuai dengan enum
    .optional(),
  valid_until: z.string().datetime().nullable().optional(),
  created_at: z.string().datetime().optional(),
});

// 9. SystemSettings Schema
export const SystemSettingSchema = z.object({
  setting_key: z
    .string()
    .max(100, "Kunci pengaturan tidak boleh lebih dari 100 karakter"),
  setting_value: z.string().min(1, "Nilai pengaturan tidak boleh kosong"),
  description: z.string().nullable().optional(),
  value_type: z
    .string()
    .max(50, "Tipe nilai tidak boleh lebih dari 50 karakter")
    .default("text")
    .optional(),
  is_sensitive: z.boolean().default(false).optional(),
  last_updated_by: z.string().uuid().nullable().optional(),
  last_updated_at: z.string().datetime().optional(),
});

// 10. Tasks Schema
export const TaskSchema = z.object({
  task_id: z.string().uuid().optional(),
  title: z
    .string()
    .min(1, "Judul tugas tidak boleh kosong")
    .max(255, "Judul tugas tidak boleh lebih dari 255 karakter"),
  description: z.string().nullable().optional(),
  assignee_id: z.string().uuid().nullable().optional(),
  creator_id: z.string().uuid(),
  due_date: z
    .string()
    .regex(
      /^\d{4}-\d{2}-\d{2}$/,
      "Format tanggal jatuh tempo tidak valid (YYYY-MM-DD)"
    )
    .nullable()
    .optional(),
  completed_at: z.string().datetime().nullable().optional(),
  priority: z.enum(["High", "Medium", "Low"]).default("Medium").optional(),
  status: z
    .enum(["Pending", "In Progress", "Completed", "Cancelled"])
    .default("Pending")
    .optional(),
  related_document_type: z
    .string()
    .max(50, "Tipe dokumen terkait tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  related_document_id: z.string().uuid().nullable().optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 11. Employees Schema
export const EmployeeSchema = z.object({
  employee_id: z.string().uuid().optional(),
  user_id: z.string().uuid().nullable().optional(),
  employee_code: z
    .string()
    .min(1, "Kode karyawan tidak boleh kosong")
    .max(50, "Kode karyawan tidak boleh lebih dari 50 karakter"),
  full_name: z
    .string()
    .min(1, "Nama lengkap tidak boleh kosong")
    .max(150, "Nama lengkap tidak boleh lebih dari 150 karakter"),
  job_title: z
    .string()
    .max(100, "Jabatan tidak boleh lebih dari 100 karakter")
    .nullable()
    .optional(),
  department: z
    .string()
    .max(100, "Departemen tidak boleh lebih dari 100 karakter")
    .nullable()
    .optional(),
  hire_date: z
    .string()
    .regex(
      /^\d{4}-\d{2}-\d{2}$/,
      "Format tanggal mulai bekerja tidak valid (YYYY-MM-DD)"
    )
    .nullable()
    .optional(),
  termination_date: z
    .string()
    .regex(
      /^\d{4}-\d{2}-\d{2}$/,
      "Format tanggal berhenti bekerja tidak valid (YYYY-MM-DD)"
    )
    .nullable()
    .optional(),
  salary: z.number().positive("Gaji harus angka positif").nullable().optional(), // NUMERIC(19, 4)
  is_active: z.boolean().default(true).optional(),
  contact_email: z
    .string()
    .email("Format email kontak tidak valid")
    .max(100, "Email kontak tidak boleh lebih dari 100 karakter")
    .nullable()
    .optional(),
  contact_phone: z
    .string()
    .max(50, "Nomor telepon kontak tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 12. GamificationRewards Schema
export const GamificationRewardSchema = z.object({
  reward_id: z.string().uuid().optional(),
  reward_name: z
    .string()
    .min(1, "Nama reward tidak boleh kosong")
    .max(100, "Nama reward tidak boleh lebih dari 100 karakter"),
  description: z.string().nullable().optional(),
  points_awarded: z
    .number()
    .int()
    .min(0, "Poin yang diberikan tidak boleh negatif"),
  badge_image_url: z
    .string()
    .url("URL gambar badge tidak valid")
    .nullable()
    .optional(),
  is_active: z.boolean().default(true).optional(),
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 13. UserAchievements Schema
export const UserAchievementSchema = z.object({
  achievement_id: z.string().uuid().optional(),
  user_id: z.string().uuid(),
  reward_id: z.string().uuid(),
  achievement_date: z.string().datetime().optional(),
  earned_points: z.number().int(),
  notes: z.string().nullable().optional(),
});

// 14. ReportConfigurations Schema
export const ReportConfigurationSchema = z.object({
  report_config_id: z.string().uuid().optional(),
  user_id: z.string().uuid(),
  report_name: z
    .string()
    .min(1, "Nama laporan tidak boleh kosong")
    .max(100, "Nama laporan tidak boleh lebih dari 100 karakter"),
  description: z.string().nullable().optional(),
  base_table: z
    .string()
    .max(100, "Tabel dasar tidak boleh lebih dari 100 karakter"),
  columns_selected: z.array(z.string()).nullable().optional(), // JSONB array of strings
  filters: z.record(z.string(), z.any()).nullable().optional(), // JSONB object
  sorting_order: z.record(z.string(), z.any()).nullable().optional(), // JSONB object
  grouping_fields: z.array(z.string()).nullable().optional(), // JSONB array of strings
  is_public: z.boolean().default(false).optional(),
  shared_with: z.array(z.string().uuid()).nullable().optional(), // JSONB array of UUIDs
  created_at: z.string().datetime().optional(),
  updated_at: z.string().datetime().optional(),
});

// 15. LLMRequests Schema
export const LLMRequestSchema = z.object({
  request_id: z.string().uuid().optional(),
  user_id: z.string().uuid().nullable().optional(),
  request_timestamp: z.string().datetime().optional(),
  prompt_text: z.string().min(1, "Teks prompt tidak boleh kosong"),
  llm_response: z.string().nullable().optional(),
  model_used: z
    .string()
    .max(100, "Model yang digunakan tidak boleh lebih dari 100 karakter")
    .nullable()
    .optional(),
  temperature: z.number().min(0).max(1).nullable().optional(), // NUMERIC(5, 2)
  max_tokens: z.number().int().positive().nullable().optional(),
  usage_tokens: z.number().int().positive().nullable().optional(),
  cost: z.number().positive().nullable().optional(), // NUMERIC(10, 6)
  response_latency_ms: z.number().int().positive().nullable().optional(),
  feedback_rating: z.number().int().min(1).max(5).nullable().optional(),
  human_validated: z.boolean().default(false).optional(),
  validation_by: z.string().uuid().nullable().optional(),
  validation_at: z.string().datetime().nullable().optional(),
  error_message: z.string().nullable().optional(),
  related_document_type: z
    .string()
    .max(50, "Tipe dokumen terkait tidak boleh lebih dari 50 karakter")
    .nullable()
    .optional(),
  related_document_id: z.string().uuid().nullable().optional(),
});

// Tipe inferensi dari skema untuk penggunaan di TypeScript
export type User = z.infer<typeof UserSchema>;
export type UserFormInput = z.infer<typeof UserFormSchema>;
export type Role = z.infer<typeof RoleSchema>;
export type Permission = z.infer<typeof PermissionSchema>;
export type UserRole = z.infer<typeof UserRoleSchema>;
export type RolePermission = z.infer<typeof RolePermissionSchema>;
export type AuditLog = z.infer<typeof AuditLogSchema>;
export type DocumentVersion = z.infer<typeof DocumentVersionSchema>;
export type Notification = z.infer<typeof NotificationSchema>;
export type SystemSetting = z.infer<typeof SystemSettingSchema>;
export type Task = z.infer<typeof TaskSchema>;
export type Employee = z.infer<typeof EmployeeSchema>;
export type GamificationReward = z.infer<typeof GamificationRewardSchema>;
export type UserAchievement = z.infer<typeof UserAchievementSchema>;
export type ReportConfiguration = z.infer<typeof ReportConfigurationSchema>;
export type LLMRequest = z.infer<typeof LLMRequestSchema>;

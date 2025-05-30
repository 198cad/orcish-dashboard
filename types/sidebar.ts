import { Icon } from "@tabler/icons-react";

export interface SidebarMenuItem {
  title: string;
  url: string;
  icon: Icon; // Mengubah icon menjadi wajib
  permission?: string; // Nama izin yang diperlukan untuk melihat menu ini
  items?: SidebarMenuItem[]; // Untuk sub-menu
}

export interface SidebarMenuCategory {
  title: string;
  items: SidebarMenuItem[];
}

export interface UserPermissions {
  permissions: string[]; // Daftar nama izin yang dimiliki pengguna
}

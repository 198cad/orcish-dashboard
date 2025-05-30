import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Asumsi: Anda memiliki fungsi atau cara untuk memeriksa status otentikasi pengguna.
// Ini bisa berupa membaca cookie sesi, token JWT, dll.
// Untuk tujuan contoh ini, kita akan menggunakan placeholder.
function isAuthenticated(request: NextRequest): boolean {
  // Implementasi logika otentikasi Anda di sini.
  // Contoh sederhana: memeriksa keberadaan cookie 'session_token'
  const sessionToken = request.cookies.get("session_token");
  return !!sessionToken; // Mengembalikan true jika token ada, false jika tidak
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Daftar rute yang dilindungi (membutuhkan otentikasi)
  // Ini termasuk halaman utama dan semua rute di bawah /dashboard
  const protectedRoutes = ["/", "/dashboard"];

  // Daftar rute publik (tidak membutuhkan otentikasi)
  const publicRoutes = ["/login", "/api/auth"];

  // Periksa apakah rute saat ini adalah rute yang dilindungi
  const isProtectedRoute = protectedRoutes.some((route) => pathname === route || pathname.startsWith(`${route}/`));

  // Periksa apakah rute saat ini adalah rute publik
  const isPublicRoute = publicRoutes.some((route) => pathname === route || pathname.startsWith(`${route}/`));

  // Jika pengguna mencoba mengakses rute yang dilindungi dan tidak terotentikasi,
  // arahkan mereka ke halaman login.
  if (isProtectedRoute && !isAuthenticated(request)) {
    const loginUrl = new URL("/login", request.url);
    // Tambahkan parameter 'from' agar setelah login bisa kembali ke halaman sebelumnya
    loginUrl.searchParams.set("from", pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Jika pengguna terotentikasi dan mencoba mengakses halaman login,
  // arahkan mereka ke halaman utama (dashboard).
  if (isPublicRoute && isAuthenticated(request) && pathname === "/login") {
    return NextResponse.redirect(new URL("/", request.url));
  }

  return NextResponse.next();
}

// Konfigurasi matcher untuk middleware
// Ini menentukan rute mana yang akan menjalankan middleware.
// Pastikan untuk tidak menyertakan rute API atau file statis yang tidak perlu diotentikasi.
export const config = {
  matcher: [
    /*
     * Cocokkan semua jalur permintaan kecuali yang memiliki ekstensi file
     * atau berada di dalam folder `_next` atau `api`.
     */
    "/((?!api|_next/static|_next/image|favicon.ico|.*\\..*).*)",
  ],
};

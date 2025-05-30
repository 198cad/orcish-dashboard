"use client";
import Link from "next/link";
import { usePathname } from "next/navigation"; // Import usePathname
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function NotFound() {
  const pathname = usePathname();

  return (
    <div className="flex flex-col items-center justify-center py-10">
      <Card className="w-full max-w-md text-center">
        <CardHeader>
          <CardTitle className="text-6xl font-bold text-primary">404</CardTitle>
          <CardDescription className="text-xl text-muted-foreground">Halaman Tidak Ditemukan</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-foreground">
            Maaf, halaman yang Anda cari tidak ada. Mungkin Anda salah mengetik alamat, atau halaman tersebut telah
            dipindahkan.
          </p>
          {pathname && ( // Tampilkan URL jika tersedia
            <p className="text-sm text-muted-foreground break-all">
              URL yang diminta: <code className="font-mono bg-muted px-2 py-1 rounded">{pathname}</code>
            </p>
          )}
          <Link href="/" passHref>
            <Button className="mt-4">Kembali ke Beranda</Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  );
}

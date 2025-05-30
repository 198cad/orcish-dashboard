import { Client } from "pg";
import readline from "readline";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

async function deleteDatabase() {
  const databaseName = process.argv[2];

  if (!databaseName) {
    console.error("Penggunaan: ts-node delete_database.ts <nama_database>");
    process.exit(1);
  }

  rl.question(`Apakah Anda yakin ingin menghapus database '${databaseName}'? (ya/tidak): `, async (answer) => {
    if (answer.toLowerCase() === "ya") {
      const client = new Client({
        user: "postgres",
        host: "localhost",
        database: "postgres", // Connect to 'postgres' database to drop another database
        password: "password",
        port: 5432,
      });

      try {
        await client.connect();
        console.log(`Menghapus database: ${databaseName}...`);
        await client.query(`DROP DATABASE IF EXISTS "${databaseName}";`);
        console.log(`Database '${databaseName}' berhasil dihapus.`);
      } catch (err) {
        console.error("Gagal menghapus database:", err);
      } finally {
        await client.end();
        rl.close();
      }
    } else {
      console.log("Penghapusan database dibatalkan.");
      rl.close();
    }
  });
}

deleteDatabase();

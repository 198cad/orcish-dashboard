import { Client } from "pg";
import readline from "readline";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

async function createDatabase() {
  const databaseName = process.argv[2];

  if (!databaseName) {
    console.error("Penggunaan: ts-node create_database.ts <nama_database>");
    process.exit(1);
  }

  rl.question(`Apakah Anda yakin ingin membuat database '${databaseName}'? (ya/tidak): `, async (answer) => {
    if (answer.toLowerCase() === "ya") {
      const client = new Client({
        user: "postgres",
        host: "localhost",
        database: "postgres", // Connect to 'postgres' database to create another database
        password: "password",
        port: 5432,
      });

      try {
        await client.connect();
        console.log(`Membuat database: ${databaseName}...`);
        await client.query(`CREATE DATABASE "${databaseName}";`);
        console.log(`Database '${databaseName}' berhasil dibuat.`);
      } catch (err) {
        console.error("Gagal membuat database:", err);
      } finally {
        await client.end();
        rl.close();
      }
    } else {
      console.log("Pembuatan database dibatalkan.");
      rl.close();
    }
  });
}

createDatabase();

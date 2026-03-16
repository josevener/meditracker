const mysql = require('mysql2/promise');
require('dotenv').config();

async function initDb() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '12345678'
    });

    console.log('Connecting to MySQL...');
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME || 'medtrack'}\`;`);
    console.log(`Database "${process.env.DB_NAME || 'medtrack'}" checked/created.`);
    await connection.end();
    process.exit(0);
  }
  catch (error) {
    console.log(`${new Date().toISOString()} >> Database initialization failed: ${error}`);
    process.exit(1);
  }
}

initDb();

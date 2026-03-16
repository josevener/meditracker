const knex = require('./src/config/db');

async function checkTables() {
  try {
    const tables = await knex.raw('SHOW TABLES');
    console.log('Tables in database:', JSON.stringify(tables[0], null, 2));
    process.exit(0);
  } catch (error) {
    console.error('Error checking tables:', error);
    process.exit(1);
  }
}

checkTables();

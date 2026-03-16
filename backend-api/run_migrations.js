const knex = require('./src/config/db');

async function runMigrations() {
  try {
    console.log('Running migrations...');
    await knex.migrate.latest();
    console.log('Migrations completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigrations();

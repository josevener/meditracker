/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  await knex.schema.createTable('users', (table) => {
    table.increments('id').primary();
    table.string('email').unique().notNullable();
    table.string('password').notNullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('medications', (table) => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().notNullable()
      .references('id').inTable('users').onDelete('CASCADE');
    table.string('name').notNullable();
    table.string('dosage');
    table.integer('frequency_per_day').notNullable();
    table.string('start_date').notNullable();
    table.string('end_date');
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('schedules', (table) => {
    table.increments('id').primary();
    table.integer('medication_id').unsigned().notNullable()
      .references('id').inTable('medications').onDelete('CASCADE');
    table.string('time_of_day').notNullable();
  });

  await knex.schema.createTable('intake_logs', (table) => {
    table.increments('id').primary();
    table.integer('medication_id').unsigned().notNullable()
      .references('id').inTable('medications').onDelete('CASCADE');
    table.string('scheduled_time').notNullable();
    table.timestamp('taken_at');
    table.string('date').notNullable();
    table.string('status').notNullable();
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('intake_logs')
    .dropTableIfExists('schedules')
    .dropTableIfExists('medications')
    .dropTableIfExists('users');
};

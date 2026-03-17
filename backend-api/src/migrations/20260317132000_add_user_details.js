/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.table('users', (table) => {
    table.string('first_name').notNullable();
    table.string('last_name').notNullable();
    table.string('gender').notNullable();
    table.string('birthdate').notNullable();
    table.text('address').nullable();
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.table('users', (table) => {
    table.dropColumn('first_name');
    table.dropColumn('last_name');
    table.dropColumn('gender');
    table.dropColumn('birthdate');
    table.dropColumn('address');
  });
};

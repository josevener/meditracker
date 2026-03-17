const db = require('../config/db');

const UserModel = {
  create: async (userData) => {
    const { email, hashedPassword, first_name, last_name, gender, birthdate, address } = userData;
    const [id] = await db('users').insert({
      email,
      password: hashedPassword,
      first_name,
      last_name,
      gender,
      birthdate,
      address
    });
    return id;
  },

  findByEmail: async (email) => {
    return db('users').where({ email }).first();
  },

  findById: async (id) => {
    return db('users').select('id', 'email', 'created_at').where({ id }).first();
  }
};

module.exports = UserModel;

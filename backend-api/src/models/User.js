const db = require('../config/db');

const UserModel = {
  create: async (email, hashedPassword) => {
    const [id] = await db('users').insert({
      email,
      password: hashedPassword
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

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/User');

const register = async (req, res) => {
  try {
    const { email, password, first_name, last_name, gender, birthdate, address } = req.body;

    if (!email || !password || !first_name || !last_name || !gender || !birthdate) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const existingUser = await UserModel.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({ error: 'User with this email address already exists.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = await UserModel.create({
      email,
      hashedPassword,
      first_name,
      last_name,
      gender,
      birthdate,
      address
    });

    const token = jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: { id: userId, email }
    });
  }
  catch (error) {
    console.log(new Date().toISOString() + " >> Registration error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await UserModel.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Email or password is incorrect.' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Email or password is incorrect.' });
    }

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, email: user.email }
    });
  }
  catch (error) {
    console.log(`${new Date().toISOString()} >> Login error: `, error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { register, login };

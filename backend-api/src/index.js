const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5500;

app.use(cors());
app.use(express.json());

// Basic health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Import and use routes
const authRoutes = require('./routes/authRoutes');
const medicationRoutes = require('./routes/medicationRoutes');
const intakeRoutes = require('./routes/intakeRoutes');
// const syncRoutes = require('./routes/syncRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/medications', medicationRoutes);
app.use('/api/intake-logs', intakeRoutes);
// app.use('/api/sync', syncRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

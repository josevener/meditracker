const db = require('../config/db');

const logIntake = async (req, res) => {
  try {
    const { medication_id, scheduled_time, status, date, taken_at } = req.body;

    if (!medication_id || !scheduled_time || !status || !date) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const [id] = await db('intake_logs').insert({
      medication_id,
      scheduled_time,
      status,
      date,
      taken_at: taken_at || null
    });

    const newLog = await db('intake_logs').where({ id }).first();
    res.status(201).json(newLog);
  }
  catch (error) {
    console.log(new Date().toISOString() + " >> Log intake error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getIntakeHistory = async (req, res) => {
  try {
    const userId = req.userId;
    const { date } = req.query; // Optional date filter

    let query = db('intake_logs')
      .join('medications', 'intake_logs.medication_id', 'medications.id')
      .where('medications.user_id', userId)
      .select('intake_logs.*', 'medications.name as medication_name');

    if (date) {
      query = query.where('intake_logs.date', date);
    }

    const logs = await query;
    res.json(logs);
  }
  catch (error) {
    console.log(new Date().toISOString() + " >> Fetch intake history error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  logIntake,
  getIntakeHistory
};

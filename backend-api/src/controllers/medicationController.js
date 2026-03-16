const db = require('../config/db');

const getAllMedications = async (req, res) => {
  try {
    const userId = req.userId;
    const medications = await db('medications').where({ user_id: userId });

    // For each medication, fetch its schedules
    const medsWithSchedules = await Promise.all(medications.map(async (med) => {
      const schedules = await db('schedules').where({ medication_id: med.id });
      return { ...med, schedules };
    }));

    res.json(medsWithSchedules);
  }
  catch (error) {
    console.log(new Date().toISOString() + " >> Fetch medications error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const createMedication = async (req, res) => {
  const trx = await db.transaction();
  try {
    const userId = req.userId;
    const { name, dosage, frequency_per_day, start_date, end_date, schedules } = req.body;

    if (!name || !frequency_per_day || !start_date) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const [medicationId] = await trx('medications').insert({
      user_id: userId,
      name,
      dosage,
      frequency_per_day,
      start_date,
      end_date
    });

    if (schedules && Array.isArray(schedules)) {
      const scheduleData = schedules.map(time => ({
        medication_id: medicationId,
        time_of_day: time
      }));
      await trx('schedules').insert(scheduleData);
    }

    await trx.commit();

    const newMedication = await db('medications').where({ id: medicationId }).first();
    const newSchedules = await db('schedules').where({ medication_id: medicationId });

    res.status(201).json({ ...newMedication, schedules: newSchedules });
  }
  catch (error) {
    await trx.rollback();
    console.log(new Date().toISOString() + " >> Create medication error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const updateMedication = async (req, res) => {
  const trx = await db.transaction();
  try {
    const userId = req.userId;
    const { id } = req.params;
    const { name, dosage, frequency_per_day, start_date, end_date, schedules } = req.body;

    const medication = await db('medications').where({ id, user_id: userId }).first();
    if (!medication) {
      return res.status(404).json({ error: 'Medication not found' });
    }

    await trx('medications').where({ id }).update({
      name,
      dosage,
      frequency_per_day,
      start_date,
      end_date
    });

    if (schedules && Array.isArray(schedules)) {
      await trx('schedules').where({ medication_id: id }).del();
      const scheduleData = schedules.map(time => ({
        medication_id: id,
        time_of_day: time
      }));
      await trx('schedules').insert(scheduleData);
    }

    await trx.commit();

    const updatedMedication = await db('medications').where({ id }).first();
    const updatedSchedules = await db('schedules').where({ medication_id: id });

    res.json({ ...updatedMedication, schedules: updatedSchedules });
  }
  catch (error) {
    await trx.rollback();
    console.log(new Date().toISOString() + " >> Update medication error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const deleteMedication = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const deletedCount = await db('medications').where({ id, user_id: userId }).del();
    if (deletedCount === 0) {
      return res.status(404).json({ error: 'Medication not found' });
    }

    res.json({ message: 'Medication deleted successfully' });
  }
  catch (error) {
    console.log(new Date().toISOString() + " >> Delete medication error: ", error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getAllMedications,
  createMedication,
  updateMedication,
  deleteMedication
};

const express = require('express');
const router = express.Router();
const intakeController = require('../controllers/intakeController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.post('/', intakeController.logIntake);
router.get('/', intakeController.getIntakeHistory);

module.exports = router;

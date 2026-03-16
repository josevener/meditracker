const express = require('express');
const router = express.Router();
const medicationController = require('../controllers/medicationController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.get('/', medicationController.getAllMedications);
router.post('/', medicationController.createMedication);
router.put('/:id', medicationController.updateMedication);
router.delete('/:id', medicationController.deleteMedication);

module.exports = router;

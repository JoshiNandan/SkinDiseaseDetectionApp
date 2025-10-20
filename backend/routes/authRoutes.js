const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const authController = require('../controllers/authController');
const apiKeyMiddleware = require('../middlewares/apiKeyMiddleware');

router.post('/register', register);
router.post('/login', login);

module.exports = router;

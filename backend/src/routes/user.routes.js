const express = require('express');
const { getProfile } = require('../controllers/user.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/profile', authMiddleware, getProfile);

module.exports = router;

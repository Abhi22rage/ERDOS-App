const express = require('express');
const { register, login, logout, listSessions, revokeSession, revokeOtherSessions } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/logout', authMiddleware, logout);

// Session management
router.get('/sessions', authMiddleware, listSessions);
router.delete('/sessions/:sessionId', authMiddleware, revokeSession);
router.delete('/sessions/other/all', authMiddleware, revokeOtherSessions);

module.exports = router;

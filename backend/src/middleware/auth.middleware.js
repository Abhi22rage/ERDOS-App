const jwt = require('jsonwebtoken');
const SessionService = require('../services/session.service');
const logger = require('../utils/logger');

const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'No token provided' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Attach user info to request
        req.user = decoded;

        // Verify session via SessionService
        const sessionId = decoded.sid;
        if (!sessionId) {
            return res.status(401).json({ success: false, message: 'Invalid session' });
        }

        const sessionData = await SessionService.validateSession(sessionId);
        
        if (sessionData) {
            // Session is valid
            return next();
        } else {
            return res.status(401).json({ success: false, message: 'Session expired or revoked' });
        }

    } catch (err) {
        logger.error('Auth middleware error: ' + err.message);
        return res.status(401).json({ success: false, message: 'Unauthorized: ' + err.message });
    }
};

const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ success: false, message: 'Forbidden: Access denied' });
        }
        next();
    };
};

module.exports = { authMiddleware, authorize };

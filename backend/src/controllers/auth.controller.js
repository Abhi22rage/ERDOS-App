const AuthService = require('../services/auth.service');
const SessionModel = require('../models/session.model');
const SessionService = require('../services/session.service');
const logger = require('../utils/logger');
const Joi = require('joi');

const registerSchema = Joi.object({
    name: Joi.string().required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid('user', 'admin').optional()
});

const loginSchema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
});

exports.register = async (req, res) => {
    try {
        const { error, value } = registerSchema.validate(req.body);
        if (error) return res.status(400).json({ success: false, message: error.details[0].message });

        const user = await AuthService.register(value.name, value.email, value.password, value.role);
        res.status(201).json({ success: true, data: user });
    } catch (err) {
        logger.error('Registration error: ' + err.message);
        res.status(400).json({ success: false, message: err.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { error, value } = loginSchema.validate(req.body);
        if (error) return res.status(400).json({ success: false, message: error.details[0].message });

        const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
        const userAgent = req.headers['user-agent'];

        const data = await AuthService.login(value.email, value.password, ipAddress, userAgent);
        res.status(200).json({ success: true, data });
    } catch (err) {
        logger.error('Login error: ' + err.message);
        res.status(401).json({ success: false, message: err.message });
    }
};

exports.logout = async (req, res) => {
    try {
        const sessionId = req.user.sid;
        const success = await AuthService.logout(sessionId);
        if (success) {
            res.status(200).json({ success: true, message: 'Logged out successfully' });
        } else {
            res.status(500).json({ success: false, message: 'Logout failed' });
        }
    } catch (err) {
        logger.error('Logout error: ' + err.message);
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.listSessions = async (req, res) => {
    try {
        const sessions = await SessionModel.findActiveByUserId(req.user.id);
        res.status(200).json({ success: true, data: sessions });
    } catch (err) {
        logger.error('List sessions error: ' + err.message);
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.revokeSession = async (req, res) => {
    try {
        const { sessionId } = req.params;
        // Verify session belongs to user
        const session = await SessionModel.findById(sessionId);
        if (!session || session.user_id !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Unauthorized to revoke this session' });
        }

        const success = await AuthService.logout(sessionId);
        if (success) {
            res.status(200).json({ success: true, message: 'Session revoked successfully' });
        } else {
            res.status(500).json({ success: false, message: 'Revocation failed' });
        }
    } catch (err) {
        logger.error('Revoke session error: ' + err.message);
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.revokeOtherSessions = async (req, res) => {
    try {
        const currentSessionId = req.user.sid;
        const userId = req.user.id;
        
        await SessionService.revokeOtherSessions(userId, currentSessionId);
        
        res.status(200).json({ success: true, message: `Logged out from all other devices` });
    } catch (err) {
        logger.error('Revoke other sessions error: ' + err.message);
        res.status(500).json({ success: false, message: err.message });
    }
};

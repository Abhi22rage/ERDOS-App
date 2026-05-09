const jwt = require('jsonwebtoken');
const UserModel = require('../models/user.model');
const SessionService = require('./session.service');
const logger = require('../utils/logger');

class AuthService {
    static async register(name, email, password, role = 'user', phone) {
        const existingUser = await UserModel.findByEmail(email);
        if (existingUser) {
            throw new Error('Email already in use');
        }

        const userId = await UserModel.create({ name, email, password, role, phone });
        
        return { id: userId, name, email, role };
    }

    static async login(email, password, ipAddress, userAgent) {
        const user = await UserModel.findByEmail(email);
        if (!user) {
            throw new Error('Invalid credentials');
        }

        const isMatch = await UserModel.verifyPassword(password, user.password);
        if (!isMatch) {
            throw new Error('Invalid credentials');
        }

        // Update last login
        await UserModel.updateLastLogin(user.id);

        // Create Session via SessionService
        const sessionId = await SessionService.createSession(
            user.id, 
            user.role, 
            user.email, 
            ipAddress, 
            userAgent
        );

        // Generate JWT including sessionId
        const payload = { 
            id: user.id, 
            email: user.email, 
            role: user.role,
            sid: sessionId 
        };
        
        const token = jwt.sign(payload, process.env.JWT_SECRET, { 
            expiresIn: process.env.JWT_EXPIRES_IN || '24h' 
        });

        return {
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        };
    }

    static async logout(sessionId) {
        try {
            await SessionService.revokeSession(sessionId);
            return true;
        } catch (err) {
            logger.error('Logout error: ' + err.message);
            return false;
        }
    }
}

module.exports = AuthService;

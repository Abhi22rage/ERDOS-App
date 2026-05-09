const SessionModel = require('../models/session.model');
const { redisClient } = require('../config/redis');
const logger = require('../utils/logger');

class SessionService {
    static async createSession(userId, role, email, ipAddress, userAgent) {
        const expiresInSeconds = parseInt(process.env.JWT_EXPIRES_IN_SECONDS) || 86400;
        const expiresAt = new Date(Date.now() + expiresInSeconds * 1000);

        // 1. Create in MySQL
        const sessionId = await SessionModel.create(userId, ipAddress, userAgent, expiresAt);

        // 2. Cache in Redis
        const sessionData = { userId, role, email };
        await redisClient.setEx(`session:${sessionId}`, expiresInSeconds, JSON.stringify(sessionData));

        return sessionId;
    }

    static async validateSession(sessionId) {
        // 1. Try Redis
        const cached = await redisClient.get(`session:${sessionId}`);
        if (cached) return JSON.parse(cached);

        // 2. Fallback to MySQL
        const session = await SessionModel.findById(sessionId);
        if (session && session.is_active) {
            // Re-cache in Redis
            const expiresInSeconds = Math.floor((new Date(session.expires_at) - new Date()) / 1000);
            if (expiresInSeconds > 0) {
                const sessionData = { userId: session.user_id };
                await redisClient.setEx(`session:${sessionId}`, expiresInSeconds, JSON.stringify(sessionData));
                return sessionData;
            }
        }
        return null;
    }

    static async revokeSession(sessionId) {
        await SessionModel.deactivate(sessionId);
        await redisClient.del(`session:${sessionId}`);
    }

    static async revokeOtherSessions(userId, currentSessionId) {
        const sessions = await SessionModel.findActiveByUserId(userId);
        for (const session of sessions) {
            if (session.id !== currentSessionId) {
                await this.revokeSession(session.id);
            }
        }
    }
}

module.exports = SessionService;

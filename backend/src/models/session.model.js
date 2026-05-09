const db = require('../config/db');
const crypto = require('crypto');

class SessionModel {
    static async create(userId, ipAddress, userAgent, expiresAt) {
        const id = crypto.randomUUID();
        await db.execute(
            'INSERT INTO user_sessions (id, user_id, ip_address, user_agent, expires_at) VALUES (?, ?, ?, ?, ?)',
            [id, userId, ipAddress, userAgent, expiresAt]
        );
        return id;
    }

    static async findById(id) {
        const [rows] = await db.execute(
            'SELECT * FROM user_sessions WHERE id = ? AND is_active = TRUE AND expires_at > CURRENT_TIMESTAMP',
            [id]
        );
        return rows[0];
    }

    static async deactivate(id) {
        await db.execute('UPDATE user_sessions SET is_active = FALSE WHERE id = ?', [id]);
    }

    static async deactivateAllByUserId(userId) {
        await db.execute('UPDATE user_sessions SET is_active = FALSE WHERE user_id = ?', [userId]);
    }

    static async findActiveByUserId(userId) {
        const [rows] = await db.execute(
            'SELECT * FROM user_sessions WHERE user_id = ? AND is_active = TRUE AND expires_at > CURRENT_TIMESTAMP',
            [userId]
        );
        return rows;
    }
}

module.exports = SessionModel;

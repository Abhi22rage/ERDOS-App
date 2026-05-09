const db = require('../config/db');
const crypto = require('crypto');
const bcrypt = require('bcrypt');

class UserModel {
    static async findByEmail(email) {
        const [rows] = await db.execute(
            `SELECT u.*, r.name as role 
             FROM users u 
             JOIN roles r ON u.role_id = r.id 
             WHERE u.email = ?`, 
            [email]
        );
        return rows[0];
    }

    static async findById(id) {
        const [rows] = await db.execute(
            `SELECT u.id, u.name, u.email, r.name as role, u.status, u.is_verified, u.created_at 
             FROM users u 
             JOIN roles r ON u.role_id = r.id 
             WHERE u.id = ?`, 
            [id]
        );
        return rows[0];
    }

    static async create(userData) {
        const { name, email, password, role = 'user', phone } = userData;
        const id = crypto.randomUUID();
        
        // Handle password hashing
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Map role string to role_id
        const [roles] = await db.execute('SELECT id FROM roles WHERE name = ?', [role]);
        const roleId = roles.length > 0 ? roles[0].id : (await this._getDefaultRoleId());

        await db.execute(
            'INSERT INTO users (id, name, email, phone, password, role_id) VALUES (?, ?, ?, ?, ?, ?)',
            [id, name, email, phone, hashedPassword, roleId]
        );
        return id;
    }

    static async verifyPassword(plainPassword, hashedPassword) {
        return await bcrypt.compare(plainPassword, hashedPassword);
    }

    static async updateLastLogin(id) {
        await db.execute('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?', [id]);
    }

    static async _getDefaultRoleId() {
        const [roles] = await db.execute('SELECT id FROM roles WHERE name = "user" LIMIT 1');
        return roles.length > 0 ? roles[0].id : 1;
    }
}

module.exports = UserModel;

const AuthService = require('./src/services/auth.service');
const UserModel = require('./src/models/user.model');
const SessionModel = require('./src/models/session.model');
const { redisClient, connectRedis } = require('./src/config/redis');
const db = require('./src/config/db');
const logger = require('./src/utils/logger');
const bcrypt = require('bcrypt');

async function verifySessionFlow() {
    try {
        console.log('--- Starting Session Flow Verification ---');

        // 1. Setup
        await connectRedis();
        const testEmail = 'test_session@example.com';
        const testPassword = 'password123';
        const testPhone = '9999900000';

        // 2. Cleanup existing test user
        console.log('Cleaning up old test data...');
        await db.execute('DELETE FROM users WHERE email = ?', [testEmail]);

        // 3. Create Test User
        console.log('Creating test user...');
        const hashedPassword = await bcrypt.hash(testPassword, 10);
        // Get admin role ID for test
        const [roles] = await db.execute('SELECT id FROM roles WHERE name = "admin" LIMIT 1');
        const roleId = roles[0].id;
        
        const userId = require('crypto').randomUUID();
        await db.execute(
            'INSERT INTO users (id, name, email, phone, password, role_id, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [userId, 'Test User', testEmail, testPhone, hashedPassword, roleId, 'active']
        );

        // 4. Test Login
        console.log('Testing login...');
        const loginData = await AuthService.login(
            testEmail, 
            testPassword, 
            '127.0.0.1', 
            'Mozilla/5.0 (Test-Agent)'
        );
        
        const sessionId = loginData.token.split('.')[1]; // This isn't the SID, let's get it from the decoded token
        const jwt = require('jsonwebtoken');
        const decoded = jwt.decode(loginData.token);
        const sid = decoded.sid;

        console.log('Login successful. Session ID:', sid);

        // 5. Verify Redis
        const redisData = await redisClient.get(`session:${sid}`);
        if (redisData) {
            console.log('✅ Session found in Redis:', redisData);
        } else {
            throw new Error('❌ Session NOT found in Redis');
        }

        // 6. Verify MySQL
        const mysqlSession = await SessionModel.findById(sid);
        if (mysqlSession) {
            console.log('✅ Session found in MySQL. Active:', mysqlSession.is_active === 1);
        } else {
            throw new Error('❌ Session NOT found in MySQL');
        }

        // 7. Test Logout
        console.log('Testing logout...');
        await AuthService.logout(sid);

        // 8. Verify Cleanup
        const redisDataAfter = await redisClient.get(`session:${sid}`);
        if (!redisDataAfter) {
            console.log('✅ Session removed from Redis');
        } else {
            throw new Error('❌ Session still exists in Redis after logout');
        }

        const mysqlSessionAfter = await SessionModel.findById(sid);
        if (!mysqlSessionAfter) {
            console.log('✅ Session deactivated/removed from MySQL lookup');
        } else {
            throw new Error('❌ Session still active in MySQL after logout');
        }

        console.log('--- Verification Successful! ---');
        process.exit(0);
    } catch (error) {
        console.error('--- Verification Failed! ---');
        console.error(error);
        process.exit(1);
    }
}

verifySessionFlow();

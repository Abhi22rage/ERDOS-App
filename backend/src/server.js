const { connectRedis } = require('./config/redis');
const logger = require('./utils/logger');
const db = require('./config/db');

const PORT = process.env.PORT || 3000;

const startServer = async () => {
    try {
        // Connect to Redis
        await connectRedis();

        // Now that Redis is connected, we can load the app (which uses Redis for rate limiting)
        const app = require('./app');

        // Check DB Connection
        const connection = await db.getConnection();
        logger.info('Database connected successfully');
        connection.release();

        // Start Express server
        app.listen(PORT, () => {
            logger.info(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
};

startServer();

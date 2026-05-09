const UserModel = require('../models/user.model');
const logger = require('../utils/logger');

exports.getProfile = async (req, res) => {
    try {
        const user = await UserModel.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        res.status(200).json({ success: true, data: user });
    } catch (err) {
        logger.error('Get profile error: ' + err.message);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

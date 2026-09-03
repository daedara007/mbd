const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

const validasiToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ status: 'error', pesan: 'Akses ditolak. Token tidak ditemukan atau format salah.' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ status: 'error', pesan: 'Token tidak valid atau sudah kadaluwarsa.' });
    }
};

const validasiAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ status: 'error', pesan: 'Akses ditolak. Fitur ini khusus admin.' });
    }
};

module.exports = {
    validasiToken,
    validasiAdmin,
    JWT_SECRET
};

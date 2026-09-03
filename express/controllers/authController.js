const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { JWT_SECRET } = require('../middlewares/authMiddleware');

const register = async (req, res) => {
    try {
        const { nama, email, password } = req.body;
        
        if (!nama || !email || !password) {
            return res.status(400).json({ status: 'error', pesan: 'Nama, email, dan password wajib diisi.' });
        }

        if (password.length < 8) {
            return res.status(400).json({ status: 'error', pesan: 'Password minimal harus 8 karakter.' });
        }

        const password_hash = await bcrypt.hash(password, 10);
        const query = `CALL sp_register_pengguna('${nama}', '${email}', '${password_hash}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ status: 'error', pesan: 'Email dan password wajib diisi.' });
        }

        const result = await pool.query(`CALL sp_get_pengguna_login('${email}', NULL)`);
        
        if (!result.rows[0].p_response) {
            return res.status(401).json({ status: 'error', pesan: 'Email atau password salah.' });
        }

        const pengguna = result.rows[0].p_response;
        const isMatch = await bcrypt.compare(password, pengguna.password_hash);

        if (!isMatch) {
            return res.status(401).json({ status: 'error', pesan: 'Email atau password salah.' });
        }

        const payload = {
            id_pengguna: pengguna.id_pengguna,
            email: pengguna.email,
            role: pengguna.role
        };

        const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '24h' });

        res.json({
            status: 'success',
            pesan: 'Login berhasil.',
            token: token
        });

    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

module.exports = { register, login };

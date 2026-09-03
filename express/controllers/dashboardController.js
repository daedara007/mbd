const pool = require('../config/db');

const getDashboard = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const query = `CALL sp_get_dashboard_json('${id_pengguna}', NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getSaldo = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const query = `CALL sp_cek_saldo_pengguna('${id_pengguna}', NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const topupSaldo = async (req, res) => {
    try {
        const { id_pengguna_tujuan, nominal } = req.body;
        if (!id_pengguna_tujuan || !nominal) {
            return res.status(400).json({ status: 'error', pesan: 'id_pengguna_tujuan dan nominal wajib diisi.' });
        }
        
        const query = `CALL sp_topup_saldo('${id_pengguna_tujuan}', ${nominal}, NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getDaftarPengguna = async (req, res) => {
    try {
        const query = `CALL sp_get_daftar_pengguna(NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getRiwayatTransaksi = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna; // mutlak dari token JWT
        const query = `CALL sp_get_riwayat_transaksi('${id_pengguna}', NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

module.exports = { getDashboard, getSaldo, topupSaldo, getDaftarPengguna, getRiwayatTransaksi };

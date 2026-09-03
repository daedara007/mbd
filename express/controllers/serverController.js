const pool = require('../config/db');

const deployServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_paket, id_node, nama_instance } = req.body;

        const query = `CALL sp_buat_instance('${id_pengguna}', ${id_paket}, ${id_node}, '${nama_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const startServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance } = req.body;

        const query = `CALL sp_start_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const destroyServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance } = req.body;

        const query = `CALL sp_hapus_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getDaftarPaket = async (req, res) => {
    try {
        const query = `CALL sp_get_katalog_paket(NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getDaftarNode = async (req, res) => {
    try {
        const query = `CALL sp_get_daftar_node(NULL)`;
        const result = await pool.query(query);
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const stopServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance } = req.body;

        if (!id_instance) {
            return res.status(400).json({ status: 'error', pesan: 'id_instance wajib diisi.' });
        }

        const query = `CALL sp_stop_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const renewServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance } = req.body;

        if (!id_instance) {
            return res.status(400).json({ status: 'error', pesan: 'id_instance wajib diisi.' });
        }

        const query = `CALL sp_perpanjang_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const renameServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance, nama_baru } = req.body;

        if (!id_instance || !nama_baru) {
            return res.status(400).json({ status: 'error', pesan: 'id_instance dan nama_baru wajib diisi.' });
        }

        const query = `CALL sp_ubah_nama_server('${id_pengguna}', '${id_instance}', '${nama_baru}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

const getLogServer = async (req, res) => {
    try {
        const id_pengguna = req.user.id_pengguna;
        const { id_instance } = req.params;

        if (!id_instance) {
            return res.status(400).json({ status: 'error', pesan: 'id_instance wajib disertakan di URL.' });
        }

        const query = `CALL sp_get_log_aktivasi('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);

        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
};

module.exports = { deployServer, startServer, stopServer, destroyServer, getDaftarPaket, getDaftarNode, renewServer, renameServer, getLogServer };

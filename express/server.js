const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json()); // Agar bisa membaca body berformat JSON

// Konfigurasi koneksi menggunakan akun khusus backend (User Privilege)
const pool = new Pool({
    user: 'akun_backend',
    host: 'localhost',
    database: 'panelserver',
    password: 'password123',
    port: 5432,
});

// ==========================================
// USE CASE 1: Tampilkan Dasbor (READ)
// ==========================================
app.get('/api/dashboard/:id_pengguna', async (req, res) => {
    try {
        const { id_pengguna } = req.params;
        // Panggil Function, Postgres langsung mengembalikan JSON utuh
        const result = await pool.query('SELECT fn_get_dashboard_json($1) AS data_dasbor', [id_pengguna]);
        
        res.json(result.rows[0].data_dasbor);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
});

// ==========================================
// USE CASE 2: Deploy Server Baru (CREATE)
// ==========================================
app.post('/api/server/deploy', async (req, res) => {
    try {
        const { id_pengguna, id_paket, id_node, nama_instance } = req.body;
        
        // FIX: Menggunakan Simple Query Protocol (tanpa parameter array $1, $2)
        // Perhatikan penggunaan tanda kutip satu (') untuk tipe data UUID dan VARCHAR
        const query = `CALL sp_buat_instance('${id_pengguna}', ${id_paket}, ${id_node}, '${nama_instance}', NULL)`;
        const result = await pool.query(query);
        
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
});

// ==========================================
// USE CASE 3: Start Server (UPDATE)
// ==========================================
app.post('/api/server/start', async (req, res) => {
    try {
        const { id_pengguna, id_instance } = req.body;
        
        const query = `CALL sp_start_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);
        
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
});

// ==========================================
// USE CASE 4: Destroy Server (DELETE)
// ==========================================
app.delete('/api/server/destroy', async (req, res) => {
    try {
        const { id_pengguna, id_instance } = req.body;
        
        const query = `CALL sp_hapus_server('${id_pengguna}', '${id_instance}', NULL)`;
        const result = await pool.query(query);
        
        res.json(result.rows[0].p_response);
    } catch (error) {
        res.status(500).json({ status: 'error', pesan: error.message });
    }
});

// Jalankan Server
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server API berjalan di http://localhost:${PORT}`);
    console.log(`Terhubung ke database panel_server sebagai akun_backend`);
});

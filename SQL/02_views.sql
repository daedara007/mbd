CREATE OR REPLACE VIEW vw_dashboard_pengguna AS
SELECT 
    i.id_pengguna,
    i.id_instance,
    i.nama_instance,
    i.status_instance,
    i.port_koneksi,
    n.ip_publik,
    p.nama_paket,
    p.vcore_cpu,
    p.ram_mb,
    i.waktu_kedaluwarsa
FROM Instance_Server i
JOIN Node_Server n ON i.id_node = n.id_node
JOIN Paket_Layanan p ON i.id_paket = p.id_paket
WHERE i.is_active = TRUE;

CREATE OR REPLACE VIEW vw_riwayat_transaksi AS
SELECT 
    p.id_pengguna,
    p.nama AS nama_pengguna,
    t.id_transaksi,
    t.jenis_transaksi,
    t.nominal,
    t.tanggal_transaksi,
    t.id_instance
FROM Pengguna p
JOIN Transaksi t ON p.id_pengguna = t.id_pengguna;
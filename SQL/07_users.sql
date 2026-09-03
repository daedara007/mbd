-- akun backend
CREATE ROLE akun_backend WITH LOGIN PASSWORD 'password123';


REVOKE ALL ON SCHEMA public FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM akun_backend;


GRANT USAGE ON SCHEMA public TO akun_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Pengguna, Paket_Layanan, Node_Server, Instance_Server TO akun_backend;
GRANT SELECT, INSERT ON TABLE Transaksi, Log_Aktivasi TO akun_backend;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO akun_backend;


GRANT EXECUTE ON PROCEDURE sp_get_dashboard_json(UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_buat_instance(UUID, INT, INT, VARCHAR, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_start_server(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_stop_server(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_hapus_server(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_ubah_nama_server(UUID, UUID, VARCHAR, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_register_pengguna(VARCHAR, VARCHAR, VARCHAR, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_pengguna_login(VARCHAR, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_topup_saldo(UUID, DECIMAL, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_cek_saldo_pengguna(UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_daftar_pengguna(JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_katalog_paket(JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_perpanjang_server(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_daftar_node(JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_riwayat_transaksi(UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_get_log_aktivasi(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON FUNCTION fn_cek_kelayakan_saldo(UUID, INT), fn_cek_server_kedaluwarsa(UUID) TO akun_backend;
GRANT SELECT ON vw_dashboard_pengguna, vw_riwayat_transaksi TO akun_backend;

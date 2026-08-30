-- akun backend
CREATE ROLE akun_backend WITH LOGIN PASSWORD 'password123';


REVOKE ALL ON SCHEMA public FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM akun_backend;


GRANT USAGE ON SCHEMA public TO akun_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Pengguna, Paket_Layanan, Node_Server, Instance_Server, Transaksi, Log_Aktivasi TO akun_backend;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO akun_backend;


GRANT EXECUTE ON FUNCTION fn_get_dashboard_json(UUID) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_buat_instance(UUID, INT, INT, VARCHAR, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_start_server(UUID, UUID, JSON) TO akun_backend;
GRANT EXECUTE ON PROCEDURE sp_hapus_server(UUID, UUID, JSON) TO akun_backend;
GRANT SELECT ON vw_dashboard_pengguna TO akun_backend;
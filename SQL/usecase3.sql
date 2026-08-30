-- fungsi untuk cek status server sebelum di start
CREATE OR REPLACE FUNCTION fn_trg_validasi_start_server()
RETURNS TRIGGER AS $$
BEGIN

    IF NEW.status_instance = 'running' THEN
        IF OLD.status_instance != 'stopped' THEN
            RAISE EXCEPTION 'Operasi ditolak: Tidak bisa menyalakan server karena status saat ini adalah %', OLD.status_instance;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger before update agar function fn trg validasi start server jalan
CREATE TRIGGER trg_before_update_instance
BEFORE UPDATE ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validasi_start_server();

-- stored procedure untuk usecase 3
CREATE OR REPLACE PROCEDURE sp_start_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    
    UPDATE Instance_Server SET status_instance = 'running' 
    WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna;

    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan/bukan milik Anda.');
        RETURN;
    END IF;

    INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
    VALUES (p_id_instance, 'START', 'Server berhasil dinyalakan.');

    COMMIT;
    p_response := json_build_object('status', 'success', 'pesan', 'Server sedang proses dinyalakan.');
END;
$$;
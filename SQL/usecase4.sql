-- fungsi untuk soft delete instance
CREATE OR REPLACE FUNCTION fn_trg_soft_delete_instance()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Instance_Server 
    SET is_active = FALSE, 
        status_instance = 'stopped' 
    WHERE id_instance = OLD.id_instance;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- trigger kalo ada delete
CREATE TRIGGER trg_before_delete_instance
BEFORE DELETE ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_soft_delete_instance();

-- stored procedure untuk usecase 4
CREATE OR REPLACE PROCEDURE sp_hapus_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Instance_Server WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna AND is_active = TRUE) THEN
        ROLLBACK; 
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan atau sudah dihancurkan sebelumnya.');
        RETURN;
    END IF;

    DELETE FROM Instance_Server WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna;

    INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
    VALUES (p_id_instance, 'DESTROY', 'Server berhasil dihancurkan (Soft Delete).');

    COMMIT; 
    p_response := json_build_object('status', 'success', 'pesan', 'Server berhasil dihapus permanen.');
END;
$$;
CREATE OR REPLACE FUNCTION fn_cek_kelayakan_saldo(p_id_pengguna UUID, p_id_paket INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_saldo DECIMAL;
    v_harga DECIMAL;
BEGIN
    -- Ambil saldo pengguna saat ini
    SELECT saldo_kredit INTO v_saldo FROM Pengguna WHERE id_pengguna = p_id_pengguna;
    
    -- Ambil harga paket layanan
    SELECT harga_per_bulan INTO v_harga FROM Paket_Layanan WHERE id_paket = p_id_paket;
    
    -- Evaluasi kelayakan
    IF v_saldo >= v_harga THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fungsi pendamping untuk Trigger
CREATE OR REPLACE FUNCTION fn_trg_log_aktivasi()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
    VALUES (NEW.id_instance, 'CREATE', 'Instance berhasil dialokasikan pada node.');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Pemasangan Trigger pada tabel
CREATE TRIGGER trg_after_insert_instance
AFTER INSERT ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_log_aktivasi();

-- Procedure untuk usecase 2
CREATE OR REPLACE PROCEDURE sp_buat_instance(
    IN p_id_pengguna UUID,
    IN p_id_paket INT,
    IN p_id_node INT,
    IN p_nama_instance VARCHAR,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_port INT;
    v_harga DECIMAL;
    v_id_instance UUID;
BEGIN
    -- Validasi 1: Cek Saldo
    IF NOT fn_cek_kelayakan_saldo(p_id_pengguna, p_id_paket) THEN
        ROLLBACK; -- Eksplisit Rollback karena gagal syarat bisnis
        p_response := json_build_object('status', 'error', 'pesan', 'Saldo tidak mencukupi untuk menyewa paket ini.');
        RETURN;
    END IF;

    SELECT harga_per_bulan INTO v_harga FROM Paket_Layanan WHERE id_paket = p_id_paket;
    SELECT COALESCE(MAX(port_koneksi) + 1, 25565) INTO v_port FROM Instance_Server WHERE id_node = p_id_node;

    INSERT INTO Instance_Server (id_pengguna, id_paket, id_node, nama_instance, port_koneksi)
    VALUES (p_id_pengguna, p_id_paket, p_id_node, p_nama_instance, v_port)
    RETURNING id_instance INTO v_id_instance;

    UPDATE Pengguna SET saldo_kredit = saldo_kredit - v_harga WHERE id_pengguna = p_id_pengguna;

    INSERT INTO Transaksi (id_pengguna, id_instance, jenis_transaksi, nominal)
    VALUES (p_id_pengguna, v_id_instance, 'DEPLOY_SERVER', v_harga);

    COMMIT; -- Eksplisit Commit setelah semua operasi fisik sukses

    p_response := json_build_object(
        'status', 'success',
        'pesan', 'Server berhasil di-deploy.',
        'data', json_build_object('id_instance', v_id_instance, 'port_koneksi', v_port, 'saldo_terpotong', v_harga)
    );
END;
$$;
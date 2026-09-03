
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

    IF NOT fn_cek_kelayakan_saldo(p_id_pengguna, p_id_paket) THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Saldo tidak mencukupi untuk menyewa paket ini.');
        RETURN;
    END IF;

    SELECT harga_per_bulan INTO v_harga FROM Paket_Layanan WHERE id_paket = p_id_paket;
    SELECT COALESCE(MAX(port_koneksi) + 1, 25565) INTO v_port FROM Instance_Server WHERE id_node = p_id_node;

    INSERT INTO Instance_Server (id_pengguna, id_paket, id_node, nama_instance, port_koneksi, waktu_kedaluwarsa)
    VALUES (p_id_pengguna, p_id_paket, p_id_node, p_nama_instance, v_port, CURRENT_TIMESTAMP + INTERVAL '30 days')
    RETURNING id_instance INTO v_id_instance;

    UPDATE Pengguna SET saldo_kredit = saldo_kredit - v_harga WHERE id_pengguna = p_id_pengguna;

    INSERT INTO Transaksi (id_pengguna, id_instance, jenis_transaksi, nominal)
    VALUES (p_id_pengguna, v_id_instance, 'DEPLOY_SERVER - ' || p_nama_instance, v_harga);

    COMMIT;

    p_response := json_build_object(
        'status', 'success',
        'pesan', 'Server berhasil di-deploy.',
        'data', json_build_object(
            'id_instance', v_id_instance, 
            'port_koneksi', v_port, 
            'saldo_terpotong', v_harga,
            'waktu_kedaluwarsa', CURRENT_TIMESTAMP + INTERVAL '30 days'
        )
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_start_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Instance_Server WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna AND is_active = TRUE) THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan, bukan milik Anda, atau sudah dihapus.');
        RETURN;
    END IF;

    IF fn_cek_server_kedaluwarsa(p_id_instance) THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Gagal menyalakan server. Masa aktif server telah kedaluwarsa, silakan perpanjang terlebih dahulu.');
        RETURN;
    END IF;

    UPDATE Instance_Server SET status_instance = 'running' 
    WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna;

    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan/bukan milik Anda.');
        RETURN;
    END IF;

    COMMIT;
    p_response := json_build_object('status', 'success', 'pesan', 'Server sedang proses dinyalakan.');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_stop_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status status_instance_enum;
BEGIN
    SELECT status_instance INTO v_status
    FROM Instance_Server
    WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna AND is_active = TRUE;

    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan/bukan milik Anda.');
        RETURN;
    END IF;

    IF v_status = 'stopped' THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server sudah dalam keadaan mati.');
        RETURN;
    END IF;

    UPDATE Instance_Server 
    SET status_instance = 'stopped' 
    WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna;

    COMMIT;
    p_response := json_build_object('status', 'success', 'pesan', 'Server berhasil dimatikan.');
END;
$$;

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

    COMMIT; 
    p_response := json_build_object('status', 'success', 'pesan', 'Server berhasil dihapus permanen.');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_ubah_nama_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    IN p_nama_baru VARCHAR,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nama_bersih VARCHAR;
BEGIN
    v_nama_bersih := TRIM(p_nama_baru);

    IF v_nama_bersih IS NULL OR v_nama_bersih = '' THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Nama server baru tidak boleh kosong.');
        RETURN;
    END IF;

    IF LENGTH(v_nama_bersih) < 3 THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Nama server minimal harus 3 karakter.');
        RETURN;
    END IF;

    UPDATE Instance_Server 
    SET nama_instance = v_nama_bersih
    WHERE id_instance = p_id_instance 
      AND id_pengguna = p_id_pengguna 
      AND is_active = TRUE;

    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan atau bukan milik Anda.');
        RETURN;
    END IF;

    COMMIT;
    p_response := json_build_object(
        'status', 'success',
        'pesan', 'Nama server berhasil diperbarui.',
        'data', json_build_object(
            'id_instance', p_id_instance,
            'nama_instance_baru', v_nama_bersih
        )
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_register_pengguna(
    IN p_nama VARCHAR,
    IN p_email VARCHAR,
    IN p_password_hash VARCHAR,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_email IS NULL OR TRIM(p_email) = '' OR p_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        p_response := json_build_object('status', 'error', 'pesan', 'Format email tidak valid.');
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM Pengguna WHERE LOWER(email) = LOWER(TRIM(p_email))) THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Email sudah terdaftar. Silakan gunakan email lain atau login.');
        RETURN;
    END IF;

    INSERT INTO Pengguna (nama, email, password_hash)
    VALUES (p_nama, LOWER(TRIM(p_email)), p_password_hash);

    COMMIT;
    p_response := json_build_object('status', 'success', 'pesan', 'Pendaftaran berhasil. Silakan login.');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_dashboard_json(
    IN p_id_pengguna UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json json;
BEGIN
    SELECT json_agg(json_build_object(
        'id_instance', id_instance,
        'nama_instance', nama_instance,
        'status', status_instance,
        'alamat_koneksi', ip_publik || ':' || port_koneksi,
        'spesifikasi', nama_paket || ' (' || vcore_cpu || ' Core, ' || ram_mb || ' MB)',
        'waktu_kedaluwarsa', waktu_kedaluwarsa
    ))
    INTO hasil_json
    FROM vw_dashboard_pengguna
    WHERE id_pengguna = p_id_pengguna;

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_pengguna_login(
    IN p_email VARCHAR,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_pengguna UUID;
    v_nama VARCHAR;
    v_password_hash VARCHAR;
    v_role VARCHAR;
BEGIN
    SELECT id_pengguna, nama, password_hash, role
    INTO v_id_pengguna, v_nama, v_password_hash, v_role
    FROM Pengguna
    WHERE email = p_email;

    IF NOT FOUND THEN
        p_response := NULL;
        RETURN;
    END IF;

    p_response := json_build_object(
        'id_pengguna', v_id_pengguna,
        'nama', v_nama,
        'email', p_email,
        'role', v_role,
        'password_hash', v_password_hash
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_topup_saldo(
    IN p_id_pengguna_tujuan UUID,
    IN p_nominal DECIMAL,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_nominal IS NULL OR p_nominal <= 0 THEN
        p_response := json_build_object('status', 'error', 'pesan', 'Nominal top-up tidak valid. Nominal harus lebih besar dari 0.');
        RETURN;
    END IF;

    UPDATE Pengguna 
    SET saldo_kredit = saldo_kredit + p_nominal 
    WHERE id_pengguna = p_id_pengguna_tujuan;
    
    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Pengguna tidak ditemukan.');
        RETURN;
    END IF;

    INSERT INTO Transaksi (id_pengguna, jenis_transaksi, nominal)
    VALUES (p_id_pengguna_tujuan, 'TOPUP', p_nominal);

    COMMIT;
    p_response := json_build_object('status', 'success', 'pesan', 'Top-up berhasil ditambahkan.');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cek_saldo_pengguna(
    IN p_id_pengguna UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo DECIMAL(15, 2);
BEGIN
    SELECT saldo_kredit INTO v_saldo 
    FROM Pengguna 
    WHERE id_pengguna = p_id_pengguna;

    IF NOT FOUND THEN
        p_response := json_build_object('status', 'error', 'pesan', 'Pengguna tidak ditemukan.');
        RETURN;
    END IF;

    p_response := json_build_object('status', 'success', 'data', json_build_object('saldo_kredit', v_saldo));
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_daftar_pengguna(
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json JSON;
BEGIN
    SELECT json_agg(json_build_object(
        'id_pengguna', id_pengguna,
        'nama', nama,
        'email', email,
        'role', role,
        'saldo_kredit', saldo_kredit
    )) INTO hasil_json
    FROM Pengguna;

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object('status', 'success', 'data', hasil_json);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_perpanjang_server(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_paket INT;
    v_harga DECIMAL(15, 2);
    v_waktu_kedaluwarsa TIMESTAMP;
    v_waktu_baru TIMESTAMP;
    v_nama_instance VARCHAR(100);
BEGIN

    SELECT id_paket, waktu_kedaluwarsa, nama_instance
    INTO v_id_paket, v_waktu_kedaluwarsa, v_nama_instance
    FROM Instance_Server
    WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna AND is_active = TRUE;

    IF NOT FOUND THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan atau sudah tidak aktif.');
        RETURN;
    END IF;

    IF NOT fn_cek_kelayakan_saldo(p_id_pengguna, v_id_paket) THEN
        ROLLBACK;
        p_response := json_build_object('status', 'error', 'pesan', 'Saldo tidak mencukupi untuk memperpanjang server.');
        RETURN;
    END IF;

    SELECT harga_per_bulan INTO v_harga FROM Paket_Layanan WHERE id_paket = v_id_paket;

    UPDATE Pengguna SET saldo_kredit = saldo_kredit - v_harga WHERE id_pengguna = p_id_pengguna;

    IF fn_cek_server_kedaluwarsa(p_id_instance) THEN
        v_waktu_baru := CURRENT_TIMESTAMP + INTERVAL '30 days';
    ELSE
        v_waktu_baru := v_waktu_kedaluwarsa + INTERVAL '30 days';
    END IF;

    UPDATE Instance_Server 
    SET waktu_kedaluwarsa = v_waktu_baru
    WHERE id_instance = p_id_instance;

    INSERT INTO Transaksi (id_pengguna, id_instance, jenis_transaksi, nominal)
    VALUES (p_id_pengguna, p_id_instance, 'PERPANJANG_SERVER - ' || v_nama_instance, v_harga);

    COMMIT;

    p_response := json_build_object(
        'status', 'success',
        'pesan', 'Masa aktif server berhasil diperpanjang 30 hari.',
        'data', json_build_object(
            'id_instance', p_id_instance,
            'waktu_kedaluwarsa_baru', v_waktu_baru,
            'saldo_terpotong', v_harga
        )
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_hentikan_server_kedaluwarsa()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Instance_Server
    SET status_instance = 'stopped'
    WHERE waktu_kedaluwarsa < CURRENT_TIMESTAMP
      AND status_instance != 'stopped'
      AND is_active = TRUE;

    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_bersihkan_server_grace_period()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Instance_Server
    SET is_active = FALSE,
        status_instance = 'stopped'
    WHERE waktu_kedaluwarsa < CURRENT_TIMESTAMP - INTERVAL '7 days'
      AND is_active = TRUE;

    COMMIT;
END;
$$;

DROP PROCEDURE IF EXISTS sp_get_katalog_paket(UUID, JSON);
CREATE OR REPLACE PROCEDURE sp_get_katalog_paket(
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json json;
BEGIN
    SELECT json_agg(json_build_object(
        'id_paket', id_paket,
        'nama_paket', nama_paket,
        'vcore_cpu', vcore_cpu,
        'ram_mb', ram_mb || ' mb',
        'storage_gb', storage_gb || ' gb',
        'harga_per_bulan', harga_per_bulan
    ) ORDER BY harga_per_bulan ASC)
    INTO hasil_json
    FROM Paket_Layanan;

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$;

DROP PROCEDURE IF EXISTS sp_get_daftar_node(UUID, JSON);
CREATE OR REPLACE PROCEDURE sp_get_daftar_node(
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json json;
BEGIN
    SELECT json_agg(json_build_object(
        'id_node', id_node,
        'nama_node', nama_node,
        'lokasi_datacenter', lokasi_datacenter,
        'ip_publik', ip_publik,
        'status_node', status_node
    ) ORDER BY id_node ASC)
    INTO hasil_json
    FROM Node_Server
    WHERE status_node = 'online';

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_riwayat_transaksi(
    IN p_id_pengguna UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json json;
BEGIN
    SELECT json_agg(json_build_object(
        'id_transaksi', id_transaksi,
        'jenis_transaksi', jenis_transaksi,
        'nominal', nominal,
        'tanggal_transaksi', tanggal_transaksi
    ) ORDER BY tanggal_transaksi DESC)
    INTO hasil_json
    FROM vw_riwayat_transaksi
    WHERE id_pengguna = p_id_pengguna;

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_get_log_aktivasi(
    IN p_id_pengguna UUID,
    IN p_id_instance UUID,
    INOUT p_response JSON DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    hasil_json json;
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Instance_Server WHERE id_instance = p_id_instance AND id_pengguna = p_id_pengguna AND is_active = TRUE) THEN
        p_response := json_build_object('status', 'error', 'pesan', 'Server tidak ditemukan, bukan milik Anda, atau sudah dihapus.');
        RETURN;
    END IF;

    SELECT json_agg(json_build_object(
        'id_log', id_log,
        'aksi', aksi,
        'waktu_eksekusi', waktu_eksekusi,
        'pesan_sistem', pesan_sistem
    ) ORDER BY waktu_eksekusi DESC)
    INTO hasil_json
    FROM Log_Aktivasi
    WHERE id_instance = p_id_instance;

    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    p_response := json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$;
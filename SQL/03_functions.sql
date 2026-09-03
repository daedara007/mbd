CREATE OR REPLACE FUNCTION fn_cek_kelayakan_saldo(p_id_pengguna UUID, p_id_paket INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_saldo DECIMAL;
    v_harga DECIMAL;
BEGIN

    SELECT saldo_kredit INTO v_saldo FROM Pengguna WHERE id_pengguna = p_id_pengguna;
    
    SELECT harga_per_bulan INTO v_harga FROM Paket_Layanan WHERE id_paket = p_id_paket;
    
    IF v_saldo >= v_harga THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_cek_server_kedaluwarsa(p_id_instance UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_waktu_kedaluwarsa TIMESTAMP;
BEGIN
    SELECT waktu_kedaluwarsa INTO v_waktu_kedaluwarsa
    FROM Instance_Server
    WHERE id_instance = p_id_instance;

    IF v_waktu_kedaluwarsa IS NULL OR v_waktu_kedaluwarsa < CURRENT_TIMESTAMP THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_trg_log_aktivasi()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
    VALUES (NEW.id_instance, 'CREATE', 'Instance berhasil dialokasikan pada node.');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_trg_validasi_start_server()
RETURNS TRIGGER AS $$
BEGIN

    IF NEW.status_instance = 'running' AND OLD.status_instance IS DISTINCT FROM NEW.status_instance THEN
        IF fn_cek_server_kedaluwarsa(NEW.id_instance) THEN
            RAISE EXCEPTION 'Operasi ditolak: Server telah kedaluwarsa. Silakan perpanjang masa aktif server terlebih dahulu.';
        END IF;

        IF OLD.status_instance != 'stopped' THEN
            RAISE EXCEPTION 'Operasi ditolak: Tidak bisa menyalakan server karena status saat ini adalah %', OLD.status_instance;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION fn_trg_log_update_instance()
RETURNS TRIGGER AS $$
BEGIN
    
    IF OLD.status_instance IS DISTINCT FROM NEW.status_instance THEN
        INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
        VALUES (
            NEW.id_instance, 
            UPPER(NEW.status_instance::text), 
            'Status server berubah dari ' || OLD.status_instance || ' ke ' || NEW.status_instance
        );
    END IF;


    IF OLD.nama_instance IS DISTINCT FROM NEW.nama_instance THEN
        INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
        VALUES (
            NEW.id_instance, 
            'RENAME', 
            'Nama server diubah dari "' || OLD.nama_instance || '" menjadi "' || NEW.nama_instance || '"'
        );
    END IF;

    IF OLD.waktu_kedaluwarsa IS DISTINCT FROM NEW.waktu_kedaluwarsa AND NEW.waktu_kedaluwarsa > OLD.waktu_kedaluwarsa THEN
        INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
        VALUES (
            NEW.id_instance, 
            'RENEW', 
            'Masa aktif server diperpanjang hingga ' || TO_CHAR(NEW.waktu_kedaluwarsa, 'YYYY-MM-DD HH24:MI:SS')
        );
    END IF;

    IF OLD.is_active IS DISTINCT FROM NEW.is_active AND NEW.is_active = FALSE THEN
        INSERT INTO Log_Aktivasi (id_instance, aksi, pesan_sistem)
        VALUES (
            NEW.id_instance, 
            'DESTROY', 
            'Server berhasil dihancurkan (Soft Delete).'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

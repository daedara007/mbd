CREATE INDEX idx_instance_pengguna ON Instance_Server(id_pengguna);

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
    p.ram_mb
FROM Instance_Server i
JOIN Node_Server n ON i.id_node = n.id_node
JOIN Paket_Layanan p ON i.id_paket = p.id_paket
WHERE i.is_active = TRUE;

-- Fungsi untuk usecase 1
CREATE OR REPLACE FUNCTION fn_get_dashboard_json(p_id_pengguna UUID)
RETURNS json AS $$
DECLARE
    hasil_json json;
BEGIN
    -- Merakit baris data menjadi array JSON
    SELECT json_agg(json_build_object(
        'id_instance', id_instance,
        'nama_instance', nama_instance,
        'status', status_instance,
        'alamat_koneksi', ip_publik || ':' || port_koneksi,
        'spesifikasi', nama_paket || ' (' || vcore_cpu || ' Core, ' || ram_mb || ' MB)'
    ))
    INTO hasil_json
    FROM vw_dashboard_pengguna
    WHERE id_pengguna = p_id_pengguna;

    -- Jika pengguna belum punya server sama sekali
    IF hasil_json IS NULL THEN
        hasil_json := '[]'::json;
    END IF;

    -- Membungkus hasil akhir dengan pesan status
    RETURN json_build_object(
        'status', 'success',
        'data', hasil_json
    );
END;
$$ LANGUAGE plpgsql;
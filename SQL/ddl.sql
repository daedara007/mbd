-- 1. Buat Tipe Data ENUM untuk Status
CREATE TYPE status_node_enum AS ENUM ('online', 'offline', 'maintenance');
CREATE TYPE status_instance_enum AS ENUM ('running', 'stopped', 'starting', 'error');

-- 2. Tabel Pengguna
CREATE TABLE Pengguna (
    id_pengguna UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    saldo_kredit DECIMAL(15, 2) DEFAULT 0.00,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabel Node_Server (Mesin Induk Fisik)
CREATE TABLE Node_Server (
    id_node SERIAL PRIMARY KEY,
    nama_node VARCHAR(50) NOT NULL,
    ip_publik VARCHAR(45) NOT NULL,
    lokasi_datacenter VARCHAR(50) NOT NULL,
    status_node status_node_enum DEFAULT 'online'
);

-- 4. Tabel Paket_Layanan (Katalog Spesifikasi)
CREATE TABLE Paket_Layanan (
    id_paket SERIAL PRIMARY KEY,
    nama_paket VARCHAR(50) NOT NULL,
    vcore_cpu INT NOT NULL,
    ram_mb INT NOT NULL,
    storage_gb INT NOT NULL,
    harga_per_bulan DECIMAL(15, 2) NOT NULL
);

-- 5. Tabel Instance_Server (Server Milik Pengguna)
CREATE TABLE Instance_Server (
    id_instance UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_pengguna UUID NOT NULL,
    id_paket INT NOT NULL,
    id_node INT NOT NULL,
    nama_instance VARCHAR(100) NOT NULL,
    port_koneksi INT NOT NULL,
    status_instance status_instance_enum DEFAULT 'stopped',
    is_active BOOLEAN DEFAULT TRUE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Definisi Foreign Key
    CONSTRAINT fk_pengguna FOREIGN KEY (id_pengguna) REFERENCES Pengguna(id_pengguna),
    CONSTRAINT fk_paket FOREIGN KEY (id_paket) REFERENCES Paket_Layanan(id_paket),
    CONSTRAINT fk_node FOREIGN KEY (id_node) REFERENCES Node_Server(id_node)
);

-- 6. Tabel Transaksi (Riwayat Keuangan)
CREATE TABLE Transaksi (
    id_transaksi UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_pengguna UUID NOT NULL,
    id_instance UUID,
    jenis_transaksi VARCHAR(50) NOT NULL,
    nominal DECIMAL(15, 2) NOT NULL,
    tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_transaksi_pengguna FOREIGN KEY (id_pengguna) REFERENCES Pengguna(id_pengguna),
    CONSTRAINT fk_transaksi_instance FOREIGN KEY (id_instance) REFERENCES Instance_Server(id_instance)
);

-- 7. Tabel Log_Aktivasi 
CREATE TABLE Log_Aktivasi (
    id_log BIGSERIAL PRIMARY KEY,
    id_instance UUID NOT NULL,
    aksi VARCHAR(50) NOT NULL,
    waktu_eksekusi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pesan_sistem TEXT,
    
    CONSTRAINT fk_log_instance FOREIGN KEY (id_instance) REFERENCES Instance_Server(id_instance)
);


INSERT INTO Node_Server (nama_node, ip_publik, lokasi_datacenter, status_node) VALUES
('Node-Alpha-ID', '103.150.10.5', 'Jakarta, Indonesia', 'online'),
('Node-Beta-SG', '128.199.20.7', 'Singapore', 'online');


INSERT INTO Paket_Layanan (nama_paket, vcore_cpu, ram_mb, storage_gb, harga_per_bulan) VALUES
('Starter (Survival)', 2, 2048, 20, 50000.00),
('Pro (Minigames)', 4, 4096, 50, 120000.00),
('Extreme (Modded)', 8, 8192, 100, 250000.00);


INSERT INTO Pengguna (nama, email, saldo_kredit) VALUES
('Kevin Jonathan', 'kevin@example.com', 500000.00),
('Admin Test', 'admin@example.com', 15000.00);

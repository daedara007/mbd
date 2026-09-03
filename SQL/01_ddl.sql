CREATE TYPE status_node_enum AS ENUM ('online', 'offline', 'maintenance');
CREATE TYPE status_instance_enum AS ENUM ('running', 'stopped', 'starting', 'error');

CREATE TABLE Pengguna (
    id_pengguna UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    saldo_kredit DECIMAL(15, 2) DEFAULT 0.00,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Node_Server (
    id_node SERIAL PRIMARY KEY,
    nama_node VARCHAR(50) NOT NULL,
    ip_publik VARCHAR(45) NOT NULL,
    lokasi_datacenter VARCHAR(50) NOT NULL,
    status_node status_node_enum DEFAULT 'online'
);

CREATE TABLE Paket_Layanan (
    id_paket SERIAL PRIMARY KEY,
    nama_paket VARCHAR(50) NOT NULL,
    vcore_cpu INT NOT NULL,
    ram_mb INT NOT NULL,
    storage_gb INT NOT NULL,
    harga_per_bulan DECIMAL(15, 2) NOT NULL
);

CREATE TABLE Instance_Server (
    id_instance UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_pengguna UUID NOT NULL,
    id_paket INT NOT NULL,
    id_node INT NOT NULL,
    nama_instance VARCHAR(100) NOT NULL,
    port_koneksi INT NOT NULL,
    status_instance status_instance_enum DEFAULT 'stopped',
    is_active BOOLEAN DEFAULT TRUE,
    waktu_kedaluwarsa TIMESTAMP,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_pengguna FOREIGN KEY (id_pengguna) REFERENCES Pengguna(id_pengguna),
    CONSTRAINT fk_paket FOREIGN KEY (id_paket) REFERENCES Paket_Layanan(id_paket),
    CONSTRAINT fk_node FOREIGN KEY (id_node) REFERENCES Node_Server(id_node)
);

CREATE TABLE Transaksi (
    id_transaksi UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_pengguna UUID NOT NULL,
    id_instance UUID,
    jenis_transaksi VARCHAR(150) NOT NULL,
    nominal DECIMAL(15, 2) NOT NULL,
    tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_transaksi_pengguna FOREIGN KEY (id_pengguna) REFERENCES Pengguna(id_pengguna),
    CONSTRAINT fk_transaksi_instance FOREIGN KEY (id_instance) REFERENCES Instance_Server(id_instance)
);

CREATE TABLE Log_Aktivasi (
    id_log BIGSERIAL PRIMARY KEY,
    id_instance UUID NOT NULL,
    aksi VARCHAR(50) NOT NULL,
    waktu_eksekusi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pesan_sistem TEXT,
    
    CONSTRAINT fk_log_instance FOREIGN KEY (id_instance) REFERENCES Instance_Server(id_instance)
);

CREATE INDEX idx_instance_pengguna ON Instance_Server(id_pengguna);

ALTER DATABASE panel_management SET timezone TO 'Asia/Makassar';
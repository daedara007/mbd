INSERT INTO Node_Server (nama_node, ip_publik, lokasi_datacenter, status_node) VALUES
('Node-Alpha-ID', '103.150.10.5', 'Jakarta, Indonesia', 'online'),
('Node-Beta-SG', '128.199.20.7', 'Singapore', 'online'),
('Node-Gamma-US', '104.21.35.8', 'New York, USA', 'online'),
('Node-Delta-JP', '150.230.15.2', 'Tokyo, Japan', 'maintenance');

INSERT INTO Paket_Layanan (nama_paket, vcore_cpu, ram_mb, storage_gb, harga_per_bulan) VALUES
('Starter (Survival)', 2, 2048, 20, 50000.00),
('Pro (Minigames)', 4, 4096, 50, 120000.00),
('Extreme (Modded)', 8, 8192, 100, 250000.00),
('Ultimate (Network)', 16, 16384, 250, 450000.00);

INSERT INTO Pengguna (nama, email, password_hash, role, saldo_kredit) VALUES
('Kevin Jonathan', 'kevin@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'admin', 500000.00),
('Admin Test', 'admin@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'admin', 15000.00),
('Budi Santoso', 'budi@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'user', 25000.00),
('Siti Aminah', 'siti@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'user', 150000.00);

INSERT INTO Instance_Server (id_pengguna, id_paket, id_node, nama_instance, port_koneksi, status_instance, is_active, waktu_kedaluwarsa) VALUES
(
    (SELECT id_pengguna FROM Pengguna WHERE email = 'kevin@example.com'), 
    1, 1, 'Server Survival Kevin', 25565, 'running', TRUE, CURRENT_TIMESTAMP + INTERVAL '15 days'
),
(
    (SELECT id_pengguna FROM Pengguna WHERE email = 'kevin@example.com'), 
    2, 2, 'Minigames SG', 25566, 'stopped', TRUE, CURRENT_TIMESTAMP + INTERVAL '30 days'
),
(
    (SELECT id_pengguna FROM Pengguna WHERE email = 'budi@example.com'), 
    1, 1, 'Budi Craft', 25567, 'starting', TRUE, CURRENT_TIMESTAMP + INTERVAL '5 days'
),
(
    (SELECT id_pengguna FROM Pengguna WHERE email = 'siti@example.com'), 
    3, 3, 'Siti Modded US', 25568, 'error', TRUE, CURRENT_TIMESTAMP - INTERVAL '1 days'
);

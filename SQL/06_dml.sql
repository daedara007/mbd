INSERT INTO Node_Server (nama_node, ip_publik, lokasi_datacenter, status_node) VALUES
('Node-Alpha-ID', '103.150.10.5', 'Jakarta, Indonesia', 'online'),
('Node-Beta-SG', '128.199.20.7', 'Singapore', 'online');


INSERT INTO Paket_Layanan (nama_paket, vcore_cpu, ram_mb, storage_gb, harga_per_bulan) VALUES
('Starter (Survival)', 2, 2048, 20, 50000.00),
('Pro (Minigames)', 4, 4096, 50, 120000.00),
('Extreme (Modded)', 8, 8192, 100, 250000.00);


INSERT INTO Pengguna (nama, email, password_hash, role, saldo_kredit) VALUES
('Kevin Jonathan', 'kevin@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'user', 500000.00),
('Admin Test', 'admin@example.com', '$2b$10$LOVQPbuLfAR8EPgqb3Exe.bzDdcgZo7OeIp471jx20NW8NsJhvng2', 'admin', 15000.00);

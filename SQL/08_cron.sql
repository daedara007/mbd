CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.unschedule('cek_kedaluwarsa_harian') 
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cek_kedaluwarsa_harian');

SELECT cron.unschedule('cek_grace_period_harian') 
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cek_grace_period_harian');

SELECT cron.schedule(
    'cek_kedaluwarsa_harian',
    '* * * * *',
    'CALL sp_hentikan_server_kedaluwarsa()'
);

SELECT cron.schedule(
    'cek_grace_period_harian',
    '* * * * *',
    'CALL sp_bersihkan_server_grace_period()'
);

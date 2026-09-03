CREATE TRIGGER trg_after_insert_instance
AFTER INSERT ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_log_aktivasi();

CREATE TRIGGER trg_before_update_instance
BEFORE UPDATE ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validasi_start_server();

CREATE TRIGGER trg_before_delete_instance
BEFORE DELETE ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_soft_delete_instance();

CREATE TRIGGER trg_after_update_instance
AFTER UPDATE ON Instance_Server
FOR EACH ROW
EXECUTE FUNCTION fn_trg_log_update_instance();

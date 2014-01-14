USE master;
-- HAMMERORA GO
ALTER database $database_name set recovery full;
-- HAMMERORA GO
BACKUP DATABASE $database_name TO DISK='$backup_file_db' WITH COMPRESSION, FORMAT;
-- HAMMERORA GO
BACKUP LOG      $database_name TO DISK='$backup_file_db' WITH COMPRESSION;
-- HAMMERORA GO

CREATE USER $test_user identified by $test_pass default tablespace $test_table_space TEMPORARY TABLESPACE $test_temp_space
-- HAMMERORA GO
GRANT CONNECT, RESOURCE to $test_user
-- HAMMERORA GO
GRANT CREATE VIEW to $test_user
-- HAMMERORA GO
ALTER USER $test_user quota unlimited on $test_table_space
-- HAMMERORA GO
GRANT read, write ON DIRECTORY dmpdir to $test_user
-- HAMMERORA GO

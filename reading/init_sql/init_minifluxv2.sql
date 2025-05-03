
-- Init Minifluxv2 DB and user with password
SELECT 'init_minifluxv2.sql' AS script_name;

\set miniflux_db_name `echo ${MINIFLUX_DB_NAME}`
\set miniflux_db_user `echo ${MINIFLUX_DB_USER}`
\set miniflux_db_password `echo ${MINIFLUX_DB_PASSWORD}`

CREATE USER :miniflux_db_user WITH ENCRYPTED PASSWORD :'miniflux_db_password';
CREATE DATABASE :miniflux_db_name WITH OWNER :miniflux_db_user;

-- Use the new database and enable the hstore extension
\c :miniflux_db_name
CREATE EXTENSION IF NOT EXISTS hstore;



-- Init Wallabag DB and user with password
SELECT 'init_wallabag.sql' AS script_name;

\set wallabag_db_name `echo ${WALLABAG_DB_NAME}`
\set wallabag_db_user `echo ${WALLABAG_DB_USER}`
\set wallabag_db_password `echo ${WALLABAG_DB_PASSWORD}`

CREATE USER :wallabag_db_user WITH ENCRYPTED PASSWORD :'wallabag_db_password';
CREATE DATABASE :wallabag_db_name WITH OWNER :wallabag_db_user;


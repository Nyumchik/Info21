DROP DATABASE IF EXISTS part4;
DROP SCHEMA IF EXISTS public CASCADE;

CREATE DATABASE part4;
CREATE SCHEMA public;

DROP TABLE IF EXISTS "TableName_1";
DROP TABLE IF EXISTS "TableName_2";
DROP TABLE IF EXISTS "TableName_3";
DROP TABLE IF EXISTS "Ex_1";
DROP TABLE IF EXISTS "Ex_2";

CREATE TABLE IF NOT EXISTS "TableName_1" (
    id SERIAL PRIMARY KEY,
    name VARCHAR
);

CREATE TABLE IF NOT EXISTS "TableName_2" (
    id SERIAL PRIMARY KEY,
    name VARCHAR
);

CREATE TABLE IF NOT EXISTS "TableName_3" (
    id SERIAL PRIMARY KEY,
    name VARCHAR
);

CREATE TABLE IF NOT EXISTS "Ex_1" (
    id SERIAL PRIMARY KEY,
    name VARCHAR
);

CREATE TABLE IF NOT EXISTS "Ex_2" (
    id SERIAL PRIMARY KEY,
    name VARCHAR
);

---ex01
DROP PROCEDURE IF EXISTS prc_remove_table(IN name varchar);
CREATE OR REPLACE PROCEDURE prc_remove_table(IN name varchar) 
AS 
$$
    BEGIN
        FOR name IN
            SELECT table_name
            FROM information_schema.tables
            WHERE table_name LIKE CONCAT(name, '%') AND table_schema = 'public'
        LOOP
            EXECUTE CONCAT('DROP TABLE IF EXISTS "', name, '" CASCADE');
        END LOOP;
    END;
$$ 
LANGUAGE plpgsql;

CALL prc_remove_table('TableName');


--ex02
CREATE OR REPLACE FUNCTION fnc_1(number integer)
RETURNS INTEGER AS $$ BEGIN RETURN 1; END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_2(number integer)
RETURNS INTEGER AS $$ BEGIN RETURN 2; END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_3(number integer)
RETURNS INTEGER AS $$ BEGIN RETURN 3; END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_4()
RETURNS INTEGER AS $$ BEGIN RETURN 4; END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_5()
RETURNS INTEGER AS $$ BEGIN RETURN 5; END; $$ LANGUAGE plpgsql;

DROP PROCEDURE IF EXISTS prc_count_fnc_with_args(OUT "Number of functions" INTEGER, IN ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_count_fnc_with_args(OUT "Number of functions" INTEGER, IN ref REFCURSOR) 
AS
$$
    BEGIN
        OPEN ref FOR
            SELECT p.proname AS "Function name",
                pg_catalog.PG_GET_FUNCTION_IDENTITY_ARGUMENTS(p.oid) AS "Argument"
            FROM pg_catalog.pg_namespace n
                JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid
            WHERE p.prokind = 'f'
                AND pg_catalog.PG_GET_FUNCTION_IDENTITY_ARGUMENTS(p.oid) != ''
                AND n.nspname = 'public';

            "Number of functions" = (SELECT COUNT(p.proname)
                                        FROM pg_catalog.pg_namespace n
                                            JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid
                                        WHERE p.prokind = 'f'
                                            AND pg_catalog.PG_GET_FUNCTION_IDENTITY_ARGUMENTS(p.oid) != ''
                                            AND n.nspname = 'public');
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_count_fnc_with_args(0, 'ref');
-- FETCH ALL IN "ref";
-- END;

--ex03
DROP FUNCTION IF EXISTS fnc_trg_1();
CREATE OR REPLACE FUNCTION fnc_trg_1() RETURNS TRIGGER AS $$ BEGIN END; $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_1 AFTER INSERT ON "TableName_1" FOR EACH ROW EXECUTE PROCEDURE fnc_trg_1();
CREATE TRIGGER tr_2 BEFORE UPDATE ON "TableName_1" FOR EACH ROW EXECUTE PROCEDURE fnc_trg_1();
CREATE TRIGGER tr_3 AFTER UPDATE ON "TableName_1" FOR EACH ROW EXECUTE PROCEDURE fnc_trg_1();
CREATE TRIGGER tr_4 AFTER DELETE ON "TableName_1" FOR EACH ROW EXECUTE PROCEDURE fnc_trg_1();

DROP PROCEDURE IF EXISTS prc_remove_triggers(OUT "Removed triggers" integer);
CREATE OR REPLACE PROCEDURE prc_remove_triggers(OUT "Removed triggers" integer) 
AS
$$
    DECLARE
        row record;
    BEGIN
        "Removed triggers" = (SELECT count(*) FROM information_schema.triggers);

        FOR row IN (SELECT trigger_name, event_object_table FROM information_schema.triggers)
            LOOP
                EXECUTE format('DROP TRIGGER "%s" ON "%s" CASCADE', row.trigger_name, row.event_object_table);
            END LOOP;
    END;
$$ 
LANGUAGE plpgsql;

CALL prc_remove_triggers(NULL);

--ex04
DROP PROCEDURE IF EXISTS prc_name_and_type(IN name varchar, IN ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_name_and_type(IN name varchar, IN ref REFCURSOR) 
AS 
$$
    BEGIN
        OPEN ref FOR
            SELECT routine_name AS "Name", routine_type AS "Type"
                FROM information_schema.routines
                WHERE routines.specific_schema = 'public' 
                AND routine_definition LIKE CONCAT('%', name, '%');
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_name_and_type('DROP', 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_name_and_type('BEGIN', 'ref');
-- FETCH ALL IN "ref";
-- END;




DROP TABLE IF EXISTS spec;
CREATE TABLE spec
(
    id                integer PRIMARY KEY,
    table_name        varchar NOT NULL,
    column_name       varchar NOT NULL,
    current_max_value integer NOT NULL,
    UNIQUE (table_name, column_name)
);


INSERT INTO spec
VALUES (1, 'spec', 'id', 1);

CREATE OR REPLACE FUNCTION if_max_updated() RETURNS TRIGGER AS
$$
DECLARE
    max_val INTEGER;
BEGIN
    EXECUTE format('SELECT MAX(%I) FROM new_table', tg_argv[0]) INTO max_val;
    UPDATE spec SET current_max_value = max_val
    WHERE table_name = tg_table_name AND column_name = tg_argv[0] AND max_val > spec.current_max_value;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_last_int(table_name_ varchar, column_name_ varchar, OUT max_val integer) AS
$$
DECLARE
    triggers_count integer;
BEGIN
    UPDATE spec
    SET current_max_value = current_max_value + 1
    WHERE table_name = table_name_
      AND column_name = column_name_
    RETURNING current_max_value INTO max_val;
    IF max_val IS NULL THEN
        IF NOT EXISTS (SELECT * from information_schema.tables where table_name = table_name_) THEN
            RAISE EXCEPTION 'Не существует таблицы %', table_name_;
        END IF;

        IF NOT EXISTS (SELECT * from information_schema.columns where table_name = table_name_ and column_name = column_name_) THEN
             RAISE EXCEPTION 'Не существует столбца % в таблице %', column_name_, table_name_;
        END IF;

        IF (SELECT DATA_TYPE FROM information_schema.columns WHERE table_name = table_name_ and column_name = column_name_)
            NOT IN ('integer') THEN
            RAISE EXCEPTION 'Тип значений в столбце % не целочисленный', column_name_;
        END IF;

        EXECUTE FORMAT('SELECT max(%I) from %I', column_name_, table_name_) INTO max_val;
        INSERT INTO spec
        VALUES (get_last_int('spec', 'id'), table_name_, column_name_, COALESCE(max_val + 1, 1));

        SELECT count(*) into triggers_count from information_schema.triggers where event_object_table = table_name_;

        LOOP
        triggers_count = triggers_count + 1;
        EXIT WHEN NOT EXISTS(SELECT * from information_schema.triggers
                            where trigger_name = quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count));
        END LOOP;

        EXECUTE 'CREATE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count) || ' ' ||
            'AFTER UPDATE ON ' || quote_ident(table_name_) ||
            ' referencing NEW TABLE as new_table FOR EACH STATEMENT
            EXECUTE FUNCTION if_max_updated(' || quote_ident(column_name_) || ')';

        LOOP
        triggers_count = triggers_count + 1;
        EXIT WHEN NOT EXISTS(SELECT * from information_schema.triggers
                            where trigger_name = quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count));
        END LOOP;

        EXECUTE 'CREATE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count) || ' ' ||
            'AFTER INSERT ON ' || quote_ident(table_name_) ||
            ' referencing NEW TABLE as new_table FOR EACH STATEMENT
            EXECUTE FUNCTION if_max_updated(' || quote_ident(column_name_) || ')';
    END IF;
END;
$$ LANGUAGE plpgsql;


drop table if exists test;
create table test(numbers1 integer, numbers2 integer, words varchar);

insert into test values(1, 2, 'three');
insert into test values(4, 5, 'six');

select * from test;

select get_last_int('test', 'numbers1');

select * from spec;

/* select get_last_int('testt', 'numbers1');

select get_last_int('test', 'numbers11');

select get_last_int('test', 'words');

select get_last_int('TEST', 'NUMBERS1');
*/
select get_last_int('test', 'numbers2');

select * from spec;

select * from information_schema.triggers;

drop table if exists test2;
create table test2(id integer);

insert into test2 values(1);
insert into test2 values(2);
insert into test2 values(3);

create trigger test2_id_3
after update on test2
referencing new table as new_table for each STATEMENT
EXECUTE FUNCTION if_max_updated(id);

create trigger test2_id_4
after insert on test2
referencing new table as new_table for each STATEMENT
EXECUTE FUNCTION if_max_updated(id);

select get_last_int('test2', 'id');

drop table if exists "т п";
create table public."т п"
(
"с к !@#$%^&*()987654334';ljg""" integer
);

select get_last_int('т п', 'с к !@#$%^&*()987654334'';ljg"');

select * from spec;

select * from information_schema.triggers;

DROP FUNCTION get_last_int(table_name_ varchar, column_name_ varchar);
DROP TABLE spec;




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
BEGIN
    UPDATE spec
    SET current_max_value = current_max_value + 1
    WHERE table_name = table_name_
      AND column_name = column_name_
    RETURNING current_max_value INTO max_val;

    IF max_val IS NULL THEN
        EXECUTE FORMAT('SELECT max(%I) from %I', column_name_, table_name_) INTO max_val;
        INSERT INTO spec
        VALUES (get_last_int('spec', 'id'), table_name_, column_name_, COALESCE(max_val + 1, 1));

        EXECUTE 'CREATE OR REPLACE TRIGGER max_updated' ||  quote_ident(table_name_) || quote_ident(column_name_) || 'UPDATE ' ||
            'AFTER UPDATE ON '  || quote_ident(table_name_) ||
            ' referencing NEW TABLE as new_table FOR EACH STATEMENT
            EXECUTE FUNCTION if_max_updated(' || quote_ident(column_name_) || ')';

        EXECUTE 'CREATE OR REPLACE TRIGGER max_updated' || quote_ident(table_name_) || quote_ident(column_name_) || 'INSERT ' ||
            ' AFTER INSERT ON '  || quote_ident(table_name_) ||
            ' referencing NEW TABLE as new_table FOR EACH STATEMENT
            EXECUTE FUNCTION if_max_updated(' || quote_ident(column_name_) || ')';
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS aboba;
CREATE TABLE aboba
(
    numbers integer
);

insert into aboba values(1);
insert into aboba values(2);
insert into aboba values(3);

select get_last_int('aboba', 'numbers');

select * from spec;

insert into aboba values(4);

select * from spec;

INSERT INTO aboba values(3);

select * from spec;

drop table if exists test;
create table test (
    numbers1 INTEGER,
    numbers2 INTEGER
);

insert into test values(1,2);
insert into test values(3,4);
insert into test values(5,6);

select get_last_int('test', 'numbers1');
select get_last_int('test', 'numbers2');

select * from spec;

update test set numbers1 = 10, numbers2 = 9 where numbers1 = 1 and numbers2 = 2;

select * from test;
select * from spec;

update test set numbers1 = 1, numbers2 = 1 where numbers1 = 10 and numbers2 = 9;

select * from test;
select * from test;

select * from spec;

 DROP FUNCTION get_last_int(table_name_ varchar, column_name_ varchar);
 DROP TABLE spec;


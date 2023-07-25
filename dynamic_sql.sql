DROP TABLE IF EXISTS heroes_stats;
CREATE TABLE heroes_stats
(
    id   serial PRIMARY KEY,
    name varchar,
    hp   integer,
    mp   integer
);

DROP TABLE IF EXISTS "странное название3213'''";
CREATE TABLE "странное название3213'''"
(
    id   serial PRIMARY KEY,
    name varchar
);

CREATE OR REPLACE FUNCTION create_replicates() RETURNS void
    LANGUAGE plpgsql AS
$$
DECLARE
    tables CURSOR FOR (SELECT table_name
                       FROM information_schema.tables
                       WHERE table_schema = 'public');
    table_name_          varchar;
    table_replicate_name varchar;
    columns CURSOR FOR (SELECT column_name
                        FROM information_schema.columns
                        WHERE table_name = table_name_);
    column_name_         varchar;
    selected_columns_    varchar;
BEGIN

    OPEN tables;

    LOOP

        FETCH tables INTO table_name_;
        EXIT WHEN NOT found; -- таблицы кончились
        table_replicate_name := QUOTE_IDENT(table_name_ || '_replicate'); -- название таблицы-двойника

        EXECUTE 'CREATE TABLE ' || table_replicate_name || ' AS SELECT * FROM ' ||
                QUOTE_IDENT(table_name_); -- создаем таблицу-двойника
        EXECUTE 'ALTER TABLE ' || table_replicate_name ||
                ' ADD COLUMN _date_and_time timestamp DEFAULT current_timestamp';
        EXECUTE 'ALTER TABLE ' || table_replicate_name || ' ADD COLUMN _user_editor varchar DEFAULT current_user';
        EXECUTE 'ALTER TABLE ' || table_replicate_name ||
                ' ADD COLUMN _type_of_modification varchar DEFAULT ''default'' '; -- добавляем новые столбцы в нее

        selected_columns_ := '';

        OPEN columns;

        LOOP
            FETCH columns INTO column_name_;
            EXIT WHEN NOT found;
            selected_columns_ := selected_columns_ || QUOTE_IDENT(column_name_) || ', ';
        END LOOP;

        CLOSE columns;

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || QUOTE_IDENT(table_replicate_name || '_insert') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' ||
                'INSERT INTO ' || table_replicate_name || ' (' || selected_columns_ || '_type_of_modification)' ||
                ' SELECT ' || selected_columns_ || ' ''insert'' FROM new_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';

        EXECUTE 'CREATE OR REPLACE TRIGGER ' || QUOTE_IDENT(table_replicate_name || '_insert') || ' AFTER INSERT ON ' ||
                QUOTE_IDENT(table_name_) || ' REFERENCING NEW TABLE AS new_table FOR EACH STATEMENT EXECUTE FUNCTION '
                    || QUOTE_IDENT(table_replicate_name || '_insert') || '()';

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || QUOTE_IDENT(table_replicate_name || '_delete') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' ||
                'INSERT INTO ' || table_replicate_name || ' (' || selected_columns_ || '_type_of_modification)' ||
                ' SELECT ' || selected_columns_ || ' ''delete'' FROM old_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';

        EXECUTE 'CREATE OR REPLACE TRIGGER ' || QUOTE_IDENT(table_replicate_name || '_delete') || ' AFTER DELETE ON ' ||
                QUOTE_IDENT(table_name_) || ' REFERENCING OLD TABLE AS old_table FOR EACH STATEMENT EXECUTE FUNCTION '
                    || QUOTE_IDENT(table_replicate_name || '_delete') || '()';

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || QUOTE_IDENT(table_replicate_name || '_update') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' ||
                'INSERT INTO ' || table_replicate_name || ' (' || selected_columns_ || '_type_of_modification)' ||
                ' SELECT ' || selected_columns_ || ' ''update'' FROM new_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';

        EXECUTE 'CREATE OR REPLACE TRIGGER ' || QUOTE_IDENT(table_replicate_name || '_update') || ' AFTER UPDATE ON ' ||
                QUOTE_IDENT(table_name_) || ' REFERENCING NEW TABLE AS new_table FOR EACH STATEMENT EXECUTE FUNCTION '
                    || QUOTE_IDENT(table_replicate_name || '_update') || '()';

    END LOOP;

    CLOSE tables;

END;
$$;


INSERT INTO heroes_stats(name, hp, mp)
VALUES ('pudge', 100, 100);
INSERT INTO heroes_stats(name, hp, mp)
VALUES ('bobi', 500, 500), ('shadow fiend', 1, 1);

SELECT create_replicates();

SELECT *
FROM heroes_stats;
SELECT *
FROM heroes_stats_replicate;

INSERT INTO heroes_stats(name, hp, mp)
VALUES ('ogre magi', 58, 99);

SELECT *
FROM heroes_stats;
SELECT *
FROM heroes_stats_replicate;

DELETE
FROM heroes_stats
WHERE name = 'shadow fiend';

SELECT *
FROM heroes_stats;
SELECT *
FROM heroes_stats_replicate;

UPDATE heroes_stats
SET mp = 100
WHERE name = 'ogre magi';

SELECT *
FROM heroes_stats;

SELECT *
FROM heroes_stats_replicate;


SELECT *
FROM "странное название3213'''";

SELECT *
FROM "странное название3213'''_replicate";



DROP TABLE IF EXISTS cheese_types CASCADE ;
CREATE TABLE cheese_types (
    id SERIAL PRIMARY KEY,
    cheese_name varchar,
    UNIQUE (cheese_name)
);

DROP TABLE IF EXISTS cheese_makers CASCADE ;
CREATE TABLE cheese_makers (
    id SERIAL PRIMARY KEY,
    maker_name varchar,
    UNIQUE (maker_name)
);

DROP TABLE IF EXISTS cheese_at_shop CASCADE;
CREATE TABLE cheese_at_shop (
    cheese_id integer,
    maker_id integer,
    production_date date,
    expiration_date date,
    FOREIGN KEY (cheese_id) REFERENCES cheese_types(id),
    FOREIGN KEY (maker_id) REFERENCES cheese_makers(id),
    UNIQUE (cheese_id, maker_id, production_date, expiration_date)
);

insert into cheese_types(cheese_name) values ('parmigano');
insert into cheese_types(cheese_name) values ('tilsiter');
insert into cheese_types(cheese_name) values ('dutch');

insert into cheese_makers(maker_name) values ('roga_i_kopyta');
insert into cheese_makers(maker_name) values ('oao merkury');

insert into cheese_at_shop values(1, 1, '2000-01-01', '2000-01-02');
insert into cheese_at_shop values(1, 2, '2000-01-01', '2000-01-02');
insert into cheese_at_shop values(2, 1, '2000-01-01', '2000-01-02');
insert into cheese_at_shop values(3, 1, '2000-01-01', '2000-01-02');


CREATE OR REPLACE VIEW cheeses AS
    SELECT cheese_name, maker_name, production_date, expiration_date
    FROM cheese_at_shop inner join cheese_types on cheese_at_shop.cheese_id = cheese_types.id
    inner join cheese_makers on cheese_at_shop.maker_id = cheese_makers.id;

CREATE OR REPLACE FUNCTION if_inserted_cheeses() RETURNS TRIGGER AS
$$
DECLARE
    max_cheese_id integer;
    max_maker_id integer;
BEGIN
    select id from cheese_types where cheese_name = new.cheese_name into max_cheese_id;
    IF max_cheese_id IS NULL THEN
        INSERT INTO cheese_types(cheese_name) values (NEW.cheese_name) RETURNING id INTO max_cheese_id;
    END IF;
    select id from cheese_makers where maker_name = new.maker_name into max_maker_id;
    IF max_maker_id IS NULL THEN
        INSERT INTO cheese_makers(maker_name) values (NEW.maker_name) RETURNING id INTO max_maker_id;
    END IF;
    INSERT INTO cheese_at_shop values (max_cheese_id, max_maker_id, NEW.production_date, NEW.expiration_date);
    return new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER cheeses_insert
INSTEAD OF INSERT ON cheeses
FOR EACH ROW
EXECUTE FUNCTION if_inserted_cheeses();

CREATE OR REPLACE FUNCTION if_deleted_cheeses() RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM cheese_at_shop
    WHERE production_date = old.production_date and expiration_date = old.expiration_date
    and maker_id = (select cheese_maker.id from cheese_maker where cheese_maker.id = maker_id)
    and cheese_id = (select cheese_types.id from cheese_types where cheese_types.id = cheese_id);
    RETURN old;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER cheeses_delete
INSTEAD OF DELETE ON cheeses
FOR EACH ROW
EXECUTE FUNCTION if_deleted_cheeses();

CREATE OR REPLACE FUNCTION if_updated_cheeses() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE cheese_at_shop SET production_date = new.production_date, expiration_date = new.expiration_date
    WHERE production_date = old.production_date and expiration_date = old.expiration_date
    and maker_id = (select cheese_maker.id from cheese_maker where cheese_maker.id = maker_id)
    and cheese_id = (select cheese_types.id from cheese_types where cheese_types.id = cheese_id);
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER cheeses_update
INSTEAD OF UPDATE ON cheeses
FOR EACH ROW
EXECUTE FUNCTION if_updated_cheeses();

select * from cheese_types;

select * from cheese_makers;

select * from cheese_at_shop;

INSERT into cheeses values ('aaa', 'bbb', '2011-01-01', '2011-01-02');
INSERT into cheeses values ('aaa', 'bbb', '2011-01-01', '2011-01-02');

DELETE from cheeses
where production_date = '2011-01-01';

update cheeses set production_date = '2000-01-02' where production_date = '2000-01-01';

select * from cheese_types;

select * from cheese_makers;

select * from cheese_at_shop;

select * from cheeses;



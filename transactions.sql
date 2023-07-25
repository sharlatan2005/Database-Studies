--ТРАНЗАКЦИИ В ПЕРВОЙ КОНСОЛИ





--ГРЯЗНОЕ ЧТЕНИЕ (не допускается при любом уровне изоляции)

BEGIN ISOLATION LEVEL READ UNCOMMITTED;

UPDATE transactions_test SET numbers1 = 1, numbers2 = 1
where id = 1;

abort;


--НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ

 BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT * from transactions_test;

SELECT * from transactions_test;

COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT * from transactions_test;

SELECT * from transactions_test;

COMMIT;



-- ФАНТОМНОЕ ЧТЕНИЕ

 BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT * FROM transactions_test WHERE numbers1 = 1;

SELECT * FROM transactions_test WHERE numbers1 = 1;

COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT * FROM transactions_test WHERE numbers1 = 1;

SELECT * FROM transactions_test WHERE numbers1 = 1;

COMMIT;



-- АНОМАЛИЯ СЕРИАЛИЗАЦИИ

BEGIN ISOLATION LEVEL REPEATABLE READ;

select sum(total) from serializable_anomaly where status = 'NEW';

insert into serializable_anomaly values ('total new', 550, 'FAILED');

COMMIT;

BEGIN ISOLATION LEVEL SERIALIZABLE ;

select sum(total) from serializable_anomaly where status = 'NEW';

insert into serializable_anomaly values ('total new', 550, 'FAILED');

COMMIT;





-- ТРАНЗАКЦИИ ВО ВТОРОЙ КОНСОЛИ




-- ГРЯЗНОЕ ЧТЕНИЕ (не допускается)


BEGIN ISOLATION LEVEL read UNCOMMITTED;

SELECT * from transactions_test;

SELECT * from transactions_test;

COMMIT;



--НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ

BEGIN ISOLATION LEVEL READ COMMITTED;

UPDATE transactions_test set numbers1 = 2, numbers2 = 2
WHERE id = 1;

COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;

UPDATE transactions_test set numbers1 = 2, numbers2 = 2
WHERE id = 1;

COMMIT;

-- ФАНТОМНОЕ ЧТЕНИЕ


BEGIN ISOLATION LEVEL READ COMMITTED;

INSERT INTO transactions_test(numbers1, numbers2) VALUES (1, 10);

COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;

INSERT INTO transactions_test(numbers1, numbers2) VALUES (1, 10);

COMMIT;



-- АНОМАЛИЯ СЕРИАЛИЗАЦИИ ПО ЛЮБОМУ

BEGIN ISOLATION LEVEL REPEATABLE READ;

select sum(total) from serializable_anomaly where status = 'FAILED';

insert into serializable_anomaly values ('total failed', 125, 'NEW');

COMMIT;


BEGIN ISOLATION LEVEL SERIALIZABLE;

select sum(total) from serializable_anomaly where status = 'FAILED';

insert into serializable_anomaly values ('total failed', 125, 'NEW');

COMMIT;





-- ТОЧКА СОХРАНЕНИЯ

BEGIN TRANSACTION;
    INSERT INTO transactions_test(numbers1, numbers2) VALUES (200,200);
    SAVEPOINT my_savepoint;
    INSERT INTO transactions_test(numbers1, numbers2) VALUES (300,300);
    ROLLBACK TO SAVEPOINT my_savepoint;
    INSERT INTO transactions_test(numbers1, numbers2) VALUES (100,100);
COMMIT;



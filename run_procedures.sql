\i ./procedures.sql
\i ./small_fill_db.sql



-- ТЕСТ ПРОЦЕДУРЫ 1
BEGIN;
\echo 'OK, pre=true'
CALL pay_salary(true);
SELECT * FROM employee;
SELECT * FROM salary_payment;
ROLLBACK;


BEGIN;
\echo 'OK, pre=false'
CALL pay_salary(false);
SELECT * FROM employee;
SELECT * FROM salary_payment;
ROLLBACK;

BEGIN;
\echo 'OK, dissmissal date'
INSERT INTO employee (id, name, inn, birth_date, sex, employment_date, salary, employee_role_fk, dismissal_date) VALUES
	(13, 'Duke', '900000000000', '2000-01-09', 'M', '2018-01-09', '900000', 1, '2019-01-09');
CALL pay_salary(true);
SELECT * FROM employee;
SELECT * FROM salary_payment;
ROLLBACK;


BEGIN;
\echo 'ERROR, salary payment exists'
INSERT INTO salary_payment(sum, date, employee_fk) SELECT '1', date_trunc('month', current_date) + interval '24 days', 1;
CALL pay_salary(true);
SELECT * FROM employee;
SELECT * FROM salary_payment;
ROLLBACK;


BEGIN;
\echo 'OK, but January'
CALL pay_salary(false, date '2023-02-07');
SELECT * FROM employee;
SELECT * FROM salary_payment;
ROLLBACK;



-- ТЕСТ ПРОЦЕДУРы 2

BEGIN;
\echo 'ERROR, price_list not found'
CALL new_price_list_from_existing(101, 0);
ROLLBACK;


BEGIN;
\echo 'ERROR, percent <= -100'
CALL new_price_list_from_existing(1, -100);
CALL new_price_list_from_existing(1, -101);
ROLLBACK;


BEGIN;
\echo 'OK, percent= 73'
CALL new_price_list_from_existing(1, 73);
SELECT * FROM price_list JOIN price_list_service ON price_list.id = price_list_service.price_list_fk;
ROLLBACK;


BEGIN;
\echo 'OK, percent = 173'
CALL new_price_list_from_existing(1, 173);
SELECT * FROM price_list JOIN price_list_service ON price_list.id = price_list_service.price_list_fk;
ROLLBACK;


BEGIN;
\echo 'OK, percent = -73'
CALL new_price_list_from_existing(1, -73);
SELECT * FROM price_list JOIN price_list_service ON price_list.id = price_list_service.price_list_fk;
ROLLBACK;

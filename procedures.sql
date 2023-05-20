

BEGIN;

-- ПРОЦЕДУРА 1:
-- Оформление з/п сотрудникам.
-- Процедура предназначена для оформления з/п или аванса для всех сотрудников,
-- которые еще работают в фирме. Процедура принимает тип выплат (з/п или аванс) и
-- формирует исходящие платежки на всех сотрудников. Для аванса формируются платежки
-- за текущий месяц, для з/п – за прошлый. Если такие платежки уже есть, то выдается ошибка.
-- Если платежки созданы успешно, то выводится сумма всех платежек.

CREATE PROCEDURE pay_salary(pre BOOL DEFAULT true, now_date DATE DEFAULT NULL)
LANGUAGE plpgsql AS 
$pay_salary$
	DECLARE
		salary_date DATE;
		january_1 DATE;
		january_14 DATE;
	BEGIN
		IF now_date IS NULL
		THEN
			now_date := (
				SELECT current_date
			);
		END IF;

		IF pre = True THEN
			salary_date := (
				SELECT date_trunc('month', now_date) + interval '24 days'
			);
		ELSE
	 		salary_date := (
	 			SELECT date_trunc('month', now_date) - interval '1 month' + interval '9 days'
	 		);
		END IF;

		january_1 := (
			SELECT date_trunc('year', now_date)
		);
		january_14 := january_1 + interval '13 days';
		WHILE (
			EXTRACT(DOW FROM salary_date) IN (0, 6) OR (salary_date >= january_1 AND salary_date <= january_14)
		) LOOP
			salary_date := salary_date - interval '1 day';
		END LOOP;
		RAISE NOTICE 'Choosen date: %', salary_date;


		IF EXISTS ( 
			SELECT * FROM salary_payment WHERE salary_payment.date = salary_date LIMIT 1 
		) THEN
			RAISE WARNING 'Found existing salary payments';
			RETURN;
		END IF;


		INSERT INTO salary_payment(sum, date, employee_fk)
		SELECT employee.salary * 0.5, salary_date, employee.id
		FROM employee
		WHERE dismissal_date IS NULL OR dismissal_date > now_date;


		RAISE NOTICE 'Total: %', (
			SELECT sum(salary_payment.sum) FROM salary_payment WHERE salary_payment.date = salary_date
		);
	END;
$pay_salary$;

COMMIT;




BEGIN;

-- ПРОЦЕДУРА 2:
-- Оформление нового прайс-листа
-- Процедура предназначена для изменения цен в некотором прайс-листе.
-- Процедура принимает id прайс-листа и процент надбавки или скидки.
-- В результате формируется новый прайс-лист, который содержит услуги
-- старого прайс-листа и измененную на % цену.

CREATE PROCEDURE new_price_list_from_existing(price_list_id INT, percent INT)
LANGUAGE plpgsql AS 
$new_price_list_from_existing$
	DECLARE
		old_price_list RECORD;
		old_price_list_service RECORD;
		new_base_price INT;
		new_service_price INT;
		new_price_list_id INT;
	BEGIN
		SELECT * INTO old_price_list FROM price_list WHERE id = price_list_id;

		IF NOT FOUND THEN
			RAISE WARNING 'Pricelist not found';
			RETURN;
		END IF;
		IF percent <= -100 THEN
			RAISE WARNING 'percent value must be greater then -100';
			RETURN;
		END IF;

		new_base_price := old_price_list.base_price + CAST((old_price_list.base_price * (percent::float / 100)) AS INT);
		RAISE NOTICE 'new_base_price: %', new_base_price;
		INSERT INTO price_list (client_type_fk, admin_fk, base_price) VALUES
			(old_price_list.client_type_fk, old_price_list.admin_fk, new_base_price)
			RETURNING id INTO new_price_list_id;

		FOR old_price_list_service IN (
			SELECT * FROM price_list_service WHERE price_list_fk = old_price_list.id
		)
		LOOP
			new_service_price := old_price_list_service.price + CAST((old_price_list_service.price * (percent::float / 100)) AS INT);
			RAISE NOTICE 'new_service_price: %', new_service_price;
			INSERT INTO price_list_service (price_list_fk, service_fk, price) VALUES
				(new_price_list_id, old_price_list_service.service_fk, new_service_price);
		END LOOP;
	END;
$new_price_list_from_existing$;

COMMIT;


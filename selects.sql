-- ммм ЗАПРОСЫ ммм ЗАПРОСЫ мм ЗАПРОСЫ м  м м м ЗАПРОСЫ ммммм ЗАПРОСЫ ЗАПРОСЫ ЗАПРОСЫ мм ЗАПРОСЫ м ЗАПРОСЫ м м м ЗАПРОСЫ ми м 

-- CREATE FUNCTION select1()
-- RETURNS TABLE(name text)
-- LANGUAGE plpgsql AS 
-- $$
-- BEGIN
-- 	RETURN QUERY 
-- END;
-- $$;



-- ЗАПРОС 1:
--
-- Получить статистику по пользователям. Отчет представить в виде:
--
-- ФИО пользователя, id, дата регистрации, число договоров, общее число услуг,
-- среднее число услуг по договору, дата последнего договора,
-- название самой популярной услуги, список счетов пользователя через запятую.
CREATE VIEW select1 AS
SELECT
	client.id as "id",
	client.name as "name",
	client.created_at as "created_at",
	COUNT(DISTINCT main_contract.id) as "main_contract_count",
	COUNT(DISTINCT service_contract.id) as "service_contract_count",
	(
		CASE WHEN COUNT(DISTINCT main_contract.id) = 0 THEN 0
			 ELSE COUNT(DISTINCT service_contract.id) / COUNT(DISTINCT main_contract.id)::float
		END
	) as "avg_service_contract_count",
	GREATEST(MAX(main_contract.from_date), MAX(service_contract.created_date)) as "last_contract_date",
	mode() WITHIN GROUP (ORDER BY service.name) as "most_popular_service",
	(
		SELECT string_agg(bank_account.number, ', ')
		FROM bank_account
		WHERE bank_account.client_fk = client.id
	) as "bank_account_list"
FROM client
LEFT JOIN main_contract ON main_contract.client_fk = client.id
LEFT JOIN service_contract ON service_contract.main_contract_fk = main_contract.id
LEFT JOIN service ON service.id = service_contract.service_fk
GROUP BY client.id;







-- ЗАПРОС 2:
-- Получить статистику по работе сотрудников в разрезе по месяцам прошлого года. Отчет представить в следующем виде:
-- Для каждого сотрудника по одной строке отчета, с 24 столбцами – по 2 столбца на месяц.
-- В первом столбце указывается число договоров в этом месяце, которые оформил сотрудник,
-- во втором – процент изменений относительно прошлого месяца.

CREATE VIEW select2 AS
select * from crosstab(
  $$
  	WITH month_info AS (
	 	SELECT
			employee.id as "e_id",
			month_number.month as "month",
			COUNT(DISTINCT main_contract.id) + COUNT(DISTINCT service_contract.id) as "count"
		FROM employee
		CROSS JOIN (
			SELECT month FROM generate_series(0, 12) as gs(month)
		) as month_number
		LEFT JOIN main_contract ON (
			(
				main_contract.manager_fk = employee.id OR main_contract.lawyer_fk = employee.id
			)
			AND main_contract.from_date > date_trunc('year', current_date) - interval '1 year' - interval '1 month'
			AND main_contract.from_date < date_trunc('year', current_date)
			AND (
				date_part('year', main_contract.from_date) = date_part('year', current_date) - 1
				AND date_part('month', main_contract.from_date)::int = month_number.month
				OR
				date_part('year', main_contract.from_date) = date_part('year', current_date) - 2
				AND date_part('month', main_contract.from_date)::int = 12
				AND month_number.month = 0
			)
		)
		LEFT JOIN service_contract ON (
			service_contract.main_contract_fk = main_contract.id
			AND service_contract.created_date < date_trunc('year', current_date)
		)
		WHERE employee.employee_role_fk IN (2, 3)
		GROUP BY employee.id, month_number.month
  	)
  	SELECT
		month_info.e_id as "e_id",
		(month_info.month - 1)*2 + pair.i as "column_number",
		(
			CASE WHEN pair.i = 1
					THEN month_info.count
				 WHEN month_info_prev.count = 0
 					THEN NULL
 				 ELSE
					floor(((month_info.count::float - month_info_prev.count::float) / month_info_prev.count::float)*100)
			END
		) as "value"
  	FROM month_info
  	JOIN month_info as month_info_prev ON (
  		month_info_prev.month = month_info.month - 1
  		AND month_info_prev.e_id = month_info.e_id
  	)
	CROSS JOIN (
		SELECT i FROM generate_series(1, 2) as gs(i)
	) as pair
	WHERE month_info.month > 0
	GROUP BY month_info.e_id, month_info.month, pair.i, month_info.count, month_info_prev.count
	ORDER BY month_info.e_id, month_info.month, pair.i
  $$,
  $$
  	SELECT i from generate_series(1,24) gs(i)
  $$
) as (
  "employee_id" int,
  "Jan" int,
  "Jan %" float,
  "Feb" int,
  "Feb %" float,
  "Mar" int,
  "Mar %" float,
  "Apr" int,
  "Apr %" float,
  "May" int,
  "May %" float,
  "Jun" int,
  "Jun %" float,
  "Jul" int,
  "Jul %" float,
  "Aug" int,
  "Aug %" float,
  "Sep" int,
  "Sep %" float,
  "Oct" int,
  "Oct %" float,
  "Nov" int,
  "Nov %" float,
  "Dec" int,
  "Dec %" float
);

-- as (
--   "employee_id" int,
--   "Jan" int,
--   "Feb" int,
--   "Mar" int,
--   "Apr" int,
--   "May" int,
--   "Jun" int,
--   "Jul" int,
--   "Aug" int,
--   "Sep" int,
--   "Oct" int,
--   "Nov" int,
--   "Dec" int
--  );

	











-- ЗАПРОС 3:
-- Получить информацию о клиентах-должниках. Отчет представить в виде:
-- ФИО пользователя +,
-- число договоров +,
-- сумма всех договоров с учетом услуг +,
-- сумма всех платежей клиента +,
-- дата последнего договора +,
-- дата последнего платежа +,
-- р/с с которого осуществлялся последний платеж +,
-- сумма задолженности +
CREATE VIEW select3 AS
SELECT
	client.name as "name",
	COUNT(DISTINCT main_contract.id) as "main_contract_count",
	COUNT(DISTINCT service_contract.id) as "service_contract_count",
	prices_info.base_sum + COALESCE(SUM(price_list_service.price), 0) as "total_contract_price",
	COALESCE(payments_info.paid_sum, 0) as "paid_sum",
	GREATEST(MAX(main_contract.from_date), MAX(service_contract.created_date)) as "last_contract_date",
	payments_info.last_payment_date as "last_contract_payment_date",
	(
		SELECT bank_account.number
		FROM main_contract
		LEFT JOIN contract_payment ON contract_payment.main_contract_fk = main_contract.id
		LEFT JOIN bank_account ON bank_account.id = contract_payment.bank_account_fk	
		WHERE
			main_contract.client_fk = client.id
			AND contract_payment.created_at = payments_info.last_payment_date
		LIMIT 1
	) as "last_payment_bank_account_number",
	prices_info.base_sum + COALESCE(SUM(price_list_service.price), 0) - payments_info.paid_sum as "debt_sum"
FROM client
LEFT JOIN main_contract ON main_contract.client_fk = client.id
LEFT JOIN service_contract ON service_contract.main_contract_fk = main_contract.id
LEFT JOIN price_list_service ON
	price_list_service.price_list_fk = main_contract.price_list_fk
	AND price_list_service.service_fk = service_contract.service_fk
LEFT JOIN (
	SELECT
		client_1.id as "client_id",
		COALESCE(SUM(contract_payment.sum), 0) - COALESCE(SUM(contract_payment.change), 0) as "paid_sum",
		MAX(contract_payment.created_at) as "last_payment_date"
	FROM client as client_1
	LEFT JOIN main_contract ON main_contract.client_fk = client_1.id
	LEFT JOIN contract_payment ON contract_payment.main_contract_fk = main_contract.id
	GROUP BY client_1.id
) as payments_info ON payments_info.client_id = client.id
LEFT JOIN (
	SELECT
		client_2.id as "client_id",
		COALESCE(SUM(price_list.base_price), 0) as "base_sum"
	FROM client as client_2
	LEFT JOIN main_contract ON main_contract.client_fk = client_2.id
	LEFT JOIN price_list ON price_list.id = main_contract.price_list_fk
	GROUP BY client_2.id
) as prices_info ON prices_info.client_id = client.id
GROUP BY client.id, payments_info.paid_sum, payments_info.last_payment_date, prices_info.base_sum;




-- ЗАПРОС 4:
-- Получить рейтинг услуг по популярности. Отчет предоставить в виде:
-- + Название услуги;
-- + кол-во договоров, где эта услуга применяется (сортировать по этому полю);
-- среднее число раз включения услуги в договор без учета договоров, где услуга не применялась (значение будет больше или равно 1);
-- + текущая стоимость услуги по самому дорогому прайс-листу;
-- + текущая стоимость услуги по самому дешевому прайс-листу.

CREATE VIEW select4 AS
SELECT
	service.id as "id",
	service.name as "name",
	COUNT(DISTINCT service_contract.id) as "contract_count",
	(
		CASE WHEN COUNT(DISTINCT service_contract.main_contract_fk) = 0 THEN 0
			 ELSE COUNT(DISTINCT service_contract.id) / COUNT(DISTINCT service_contract.main_contract_fk)::float
		END
	) as "avg_per_main_contract",
	prices_info.max_price as "max_price",
	prices_info.min_price as "min_price"
FROM service
LEFT JOIN service_contract ON service_contract.service_fk = service.id
LEFT JOIN (
	SELECT
		price_list_service.service_fk as "service_id",
		MAX(price_list_service.price) as "max_price",
		MIN(price_list_service.price) as "min_price"
	FROM price_list_service
	GROUP BY price_list_service.service_fk
) as prices_info ON prices_info.service_id = service.id
GROUP BY service.id, service.name, prices_info.max_price, prices_info.min_price
ORDER BY contract_count DESC;



-- ЗАПРОС 5:
-- Получить информацию о сумме выплат сотрудникам за текущий год. Отчет предоставить в виде:
-- + ФИО сотрудника;
-- + количество авансов и з/п, которые должны были быть выплачены за текущий год (сотрудник мог быть принять на работу в середине года);
-- + сумма всех платежей, которые были выплачены;
-- + текущая задолженность перед сотрудником;
-- дата самой старой запланированнйо выплаты, по которой выплат не было или было выплачено не полностью.
CREATE VIEW select5 AS
SELECT
	employee.name as "name",
	employee.employment_date as "empl_date",
	year_info.first_10::date as "first_10",
	year_info.first_25::date as "first_25",
	employee.dismissal_date as "dism_date",
	year_info.last_10::date as "last_10",
	year_info.last_25::date as "last_25",
	(
		CASE WHEN date_part('month', age(year_info.last_25, year_info.first_25)) < 0
				THEN 0
			 ELSE date_part('month', age(year_info.last_25, year_info.first_25)) + 1
		END
	) as "exp_year_salary_count",
	(
		CASE WHEN date_part('month', age(year_info.last_10, year_info.first_10)) < 0
		THEN 0
			 ELSE date_part('month', age(year_info.last_10, year_info.first_10)) + 1
		END
	) as "exp_year_pre_salary_count",
	COALESCE(
		SUM(CASE WHEN salary_payment.date > date_trunc('year', current_date) THEN salary_payment.sum ELSE 0 END), 0
	) as "year_paid_sum",
	(
		(
			CASE WHEN date_part('month', age(year_info.last_25, year_info.first_25)) < 0
					THEN 0
				 ELSE date_part('month', age(year_info.last_25, year_info.first_25)) + 1
			END 
		) * (employee.salary / 2)
		+
		(
			CASE WHEN date_part('month', age(year_info.last_10, year_info.first_10)) < 0
					THEN 0
				 ELSE date_part('month', age(year_info.last_10, year_info.first_10)) + 1
			END
		) * (employee.salary / 2)
		-
		COALESCE(
			SUM(CASE WHEN salary_payment.date > date_trunc('year', current_date) THEN salary_payment.sum ELSE 0 END), 0
		)
	) as "our_debt",
	(
		SELECT 
			(
				CASE WHEN date_part('day', salary_payment.date)::int = 10 AND (employee.dismissal_date IS NULL OR salary_payment.date + interval '15 days' < employee.dismissal_date)
						THEN salary_payment.date + interval '15 days'
					 WHEN date_part('day', salary_payment.date)::int = 10
					 	THEN NULL
					 WHEN employee.dismissal_date IS NULL OR salary_payment.date + interval '1 month' - interval '15 days'< employee.dismissal_date
						THEN salary_payment.date + interval '1 month' - interval '15 days'
					 ELSE
					 	NULL
				END
			)::date
		FROM salary_payment
		WHERE
			salary_payment.employee_fk = employee.id
			AND salary_payment.date >= date_trunc('year', current_date)
		ORDER BY salary_payment.date DESC
		LIMIT 1
	) as "oldest_unpaid_date"
FROM employee
LEFT JOIN salary_payment on salary_payment.employee_fk = employee.id
LEFT JOIN (
	SELECT
		employee.id as employee_id,
			(
			CASE WHEN employee.employment_date < date_trunc('year', current_date)
				 	THEN date_trunc('year', current_date) + interval '9 days'
				 WHEN date_part('day', employee.employment_date) >= 10
				 	THEN GREATEST(
				 		date_trunc('month', employee.employment_date) + interval '1 month' + interval '9 days',
				 		date_trunc('year', current_date) + interval '9 days'
				 	)
				 ELSE
				 	GREATEST(
				 		date_trunc('month', employee.employment_date) + interval '9 days',
				 		date_trunc('year', current_date) + interval '9 days'
				 	)
			END
		) as "first_10",
		(
			CASE WHEN employee.dismissal_date IS NULL OR employee.dismissal_date > current_date
					THEN
						CASE WHEN date_part('day', current_date) >= 10
								THEN date_trunc('month', current_date) + interval '9 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '9 days'
						END
				 WHEN employee.dismissal_date < date_trunc('year', current_date) + interval '9 days'
				 	THEN date_trunc('year', current_date) - interval '1 month' + interval '9 days'
				 WHEN date_part('day', employee.dismissal_date) >= 10
				 	THEN LEAST(
				 		date_trunc('month', employee.dismissal_date) + interval '9 days',
				 		CASE WHEN date_part('day', current_date) >= 10
								THEN date_trunc('month', current_date) + interval '9 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '9 days'
						END
				 	)
				 ELSE
				 	LEAST(
				 		date_trunc('month', employee.dismissal_date) - interval '1 month' + interval '9 days',
				 		CASE WHEN date_part('day', current_date) >= 10
								THEN date_trunc('month', current_date) + interval '9 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '9 days'
						END
				 	)
			END
		) as "last_10",
		(
			CASE WHEN employee.employment_date < date_trunc('year', current_date)
				 	THEN date_trunc('year', current_date) + interval '24 days'
				 WHEN date_part('day', employee.employment_date) >= 25
				 	THEN GREATEST(
				 		date_trunc('month', employee.employment_date) + interval '1 month' + interval '24 days',
				 		date_trunc('year', current_date) + interval '24 days'
				 	)
				 ELSE
				 	GREATEST(
				 		date_trunc('month', employee.employment_date) + interval '24 days',
				 		date_trunc('year', current_date) + interval '24 days'
				 	)
			END
		) as "first_25",
		(
			CASE WHEN employee.dismissal_date IS NULL OR employee.dismissal_date > current_date
					THEN
						CASE WHEN date_part('day', current_date) >= 25
								THEN date_trunc('month', current_date) + interval '24 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '24 days'
						END
				 WHEN employee.dismissal_date < date_trunc('year', current_date) + interval '24 days'
				 	THEN date_trunc('year', current_date) - interval '1 month' + interval '24 days'
				 WHEN date_part('day', employee.dismissal_date) >= 25
				 	THEN LEAST(
				 		date_trunc('month', employee.dismissal_date) + interval '24 days',
				 		CASE WHEN date_part('day', current_date) >= 25
								THEN date_trunc('month', current_date) + interval '24 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '24 days'
						END
				 	)
				 ELSE
				 	LEAST(
				 		date_trunc('month', employee.dismissal_date) - interval '1 month' + interval '24 days',
				 		CASE WHEN date_part('day', current_date) >= 25
								THEN date_trunc('month', current_date) + interval '24 days'
							 ELSE date_trunc('month', current_date) - interval '1 month' + interval '24 days'
						END
				 	)
			END
		) as "last_25"
	FROM employee
) as year_info ON year_info.employee_id = employee.id
GROUP BY employee.id, year_info.first_25, year_info.last_25, year_info.first_10, year_info.last_10
ORDER BY employee.id;



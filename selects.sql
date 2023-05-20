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

-- ЗАПРОС 6:
-- Получить статистику по работе сотрудников в разрезе по месяцам прошлого года. Отчет представить в следующем виде:
-- Для каждого сотрудника по одной строке отчета, с 24 столбцами – по 2 столбца на месяц.
-- В первом столбце указывается число договоров в этом месяце, которые оформил сотрудник,
-- во втором – процент изменений относительно прошлого месяца.








-- ЗАПРОС 7:
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
	COALESCE(prices_info.base_sum + SUM(price_list_service.price), 0) as "total_contract_price",
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
	prices_info.base_sum + SUM(price_list_service.price) - payments_info.paid_sum as "debt_sum"
FROM client
LEFT JOIN main_contract ON main_contract.client_fk = client.id
LEFT JOIN service_contract ON service_contract.main_contract_fk = main_contract.id
LEFT JOIN price_list_service ON
	price_list_service.price_list_fk = main_contract.price_list_fk
	AND price_list_service.service_fk = service_contract.service_fk
LEFT JOIN (
	SELECT
		client_1.id as "client_id",
		SUM(contract_payment.sum) - SUM(contract_payment.change) as "paid_sum",
		MAX(contract_payment.created_at) as "last_payment_date"
	FROM client as client_1
	LEFT JOIN main_contract ON main_contract.client_fk = client_1.id
	LEFT JOIN contract_payment ON contract_payment.main_contract_fk = main_contract.id
	GROUP BY client_1.id
) as payments_info ON payments_info.client_id = client.id
LEFT JOIN (
	SELECT
		client_2.id as "client_id",
		SUM(price_list.base_price) as "base_sum"
	FROM client as client_2
	LEFT JOIN main_contract ON main_contract.client_fk = client_2.id
	LEFT JOIN price_list ON price_list.id = main_contract.price_list_fk
	GROUP BY client_2.id
) as prices_info ON prices_info.client_id = client.id
GROUP BY client.id, payments_info.paid_sum, payments_info.last_payment_date, prices_info.base_sum;




-- ЗАПРОС 8:

-- ЗАПРОС 9:

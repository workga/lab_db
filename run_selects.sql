\i ./procedures.sql
\i ./triggers.sql
-- \i ./fill_db.sql
\i ./select_small_fill_db.sql
\i ./selects.sql


\echo 'CLIENT'
select * from client limit 60;
\echo 'EMPLOYEE'
select * from employee order by id limit 60;
\echo 'BANK_ACCOUNT'
select * from bank_account limit 60;

\echo 'SERVICE'
select * from service limit 60;
\echo 'PRICE_LIST'
select * from price_list limit 60;
\echo 'PRICE_LIST_SERVICE'
select * from price_list_service limit 60;


\echo 'CONTRACTS'

select
	client.id as c_id,
	main_contract.id as m_id,
	main_contract.from_date as m_date,
	price_list.id as pl_id,
	price_list.base_price as b_price,
	service_contract.id as s_id,
	service_contract.created_date as s_date,
	price_list_service.price as s_price,
	service.name as s_name
from client
left join main_contract on main_contract.client_fk = client.id 
left join service_contract on service_contract.main_contract_fk = main_contract.id
left join price_list on price_list.id = main_contract.price_list_fk
left join price_list_service 
	on price_list_service.service_fk = service_contract.service_fk
	and price_list_service.price_list_fk = service_contract.price_list_fk
left join service on service.id = service_contract.service_fk
order by client.id, main_contract.id, service_contract.id
limit 60;

\echo 'PAYMENTS'
select
	client.id as c_id,
	main_contract.id as m_id,
	contract_payment.sum as p_sum,
	contract_payment.change as p_change,
	bank_account.number as p_ba,
	contract_payment.created_at as p_date,
	contract_payment_sum.sum as ps_sum,
	contract_payment_sum.main_contract_fk as ps_mid,
	contract_payment_sum.service_contract_fk as ps_sid
from client
left join main_contract on main_contract.client_fk = client.id
left join contract_payment on contract_payment.main_contract_fk = main_contract.id 
left join bank_account on bank_account.id = contract_payment.bank_account_fk
left join contract_payment_sum on contract_payment_sum.contract_payment_fk = contract_payment.id
order by main_contract.id, contract_payment.created_at
limit 60;

\echo 'SALARY'
select 
	employee.name as name,
	employee.employment_date as e_date,
	employee.dismissal_date as d_date,
	employee.salary as salary,
	salary_payment.sum as salary_sum,
	salary_payment.date as salary_date
from employee
left join salary_payment on salary_payment.employee_fk = employee.id
where dismissal_date IS NOT NULL
order by employee.id, salary_payment.date
limit 60;




\echo 'SELECT 1'
SELECT *
FROM select1
LIMIT 20;

\echo 'SELECT 2'
SELECT *
FROM select2
limit 20;


\echo 'SELECT 3'
SELECT *
FROM select3
LIMIT 20;


\echo 'SELECT 4'
SELECT *
FROM select4
LIMIT 20;


\echo 'SELECT 5'
SELECT *
FROM select5
LIMIT 20;




select employee.id as eid, main_contract.id as mid, main_contract.from_date as m_date, service_contract.id as sid, service_contract.created_date as s_date
from employee
left join main_contract on (main_contract.manager_fk = employee.id or main_contract.lawyer_fk = employee.id)
left join service_contract on service_contract.main_contract_fk = main_contract.id
where employee.id = 5
order by m_date, s_date;



SELECT
	employee.id as "e_id",
	month_number.month as "month",
	COUNT(DISTINCT main_contract.id) as "m_count",
	COUNT(DISTINCT service_contract.id) as "s_count",
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
LEFT JOIN main_contract as outdated_main_contract ON (
	outdated_main_contract.manager_fk = employee.id OR outdated_main_contract.lawyer_fk = employee.id
)
LEFT JOIN service_contract ON (
	service_contract.main_contract_fk = outdated_main_contract.id
	AND service_contract.created_date > date_trunc('year', current_date) - interval '1 year' - interval '1 month'
	AND service_contract.created_date < date_trunc('year', current_date)
	AND (
		date_part('year', service_contract.created_date) = date_part('year', current_date) - 1
		AND date_part('month', service_contract.created_date)::int = month_number.month
		OR
		date_part('year', service_contract.created_date) = date_part('year', current_date) - 2
		AND date_part('month', service_contract.created_date)::int = 12
		AND month_number.month = 0
	)
)
WHERE employee.employee_role_fk IN (2, 3) and employee.id = 5
GROUP BY employee.id, month_number.month;




\echo 'SELECT 2'
SELECT *
FROM select2
WHERE employee_id = 5
limit 20;


\echo 'SELECT 2_1 (without crosstab)'
SELECT *
FROM select2_1
limit 20;


\echo 'SELECT 2_2 (using functions)'
SELECT *
FROM select2_2
limit 20;


\echo 'SELECT 2_3 (using 2 with)'
SELECT *
FROM select2_3
limit 20;
























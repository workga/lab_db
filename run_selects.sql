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
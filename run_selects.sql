\i ./procedures.sql
\i ./triggers.sql
-- \i ./fill_db.sql
\i ./select_small_fill_db.sql
\i ./selects.sql


\echo 'CLIENT'
select * from client;
\echo 'EMPLOYEE'
select * from employee;
\echo 'BANK_ACCOUNT'
select * from bank_account;

\echo 'SERVICE'
select * from service;
\echo 'PRICE_LIST'
select * from price_list;
\echo 'PRICE_LIST_SERVICE'
select * from price_list_service;


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
	contract_payment.created_at as p_date
from client
left join main_contract on main_contract.client_fk = client.id
left join contract_payment on contract_payment.main_contract_fk = main_contract.id 
left join bank_account on bank_account.id = contract_payment.bank_account_fk
order by main_contract.id, contract_payment.created_at
limit 60;




\echo 'SELECT 1'
SELECT *
FROM select1
LIMIT 10;


\echo 'SELECT 3'
SELECT *
FROM select3
LIMIT 10;
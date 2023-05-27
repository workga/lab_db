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
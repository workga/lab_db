SELECT setseed(0.23);

\set CLIENT_NUMBER 100
\set EMPLOYEE_NUMBER 100
\set BANK_NUMBER 50
\set SERVICE_NUMBER 50





BEGIN;
-- ЗАПОЛНЕНИЕ БД

INSERT INTO client (name, client_type_fk, created_at)
SELECT
	'Client Name '||i::text,
	floor(random()*3)+1,
	date '2009-01-01' + (floor(random()*365) + 1)*(interval '1 day')
FROM generate_series(1, :CLIENT_NUMBER) AS gs(i);



INSERT INTO employee (name, inn, birth_date, sex, employment_date, salary, employee_role_fk)
SELECT 
	'Employee Name '||i::text,
	lpad(i::text, 12, '0'),
	(timestamp '1950-01-01 00:00:00' + random() * (timestamp '2000-01-01 00:00:00' - timestamp '1950-01-01 00:00:00'))::date,
	substring('MF', (floor(random()*2)+1)::int,1),
	(now() - random() * (now()  - timestamp '2010-01-01 00:00:00'))::date,
	floor(random()*100000)+10000,
	floor(random()*4)+1
FROM generate_series(1, :EMPLOYEE_NUMBER) AS gs(i);



INSERT INTO bank (name, address, bik, correspondent_account)
SELECT
	'Bank Name '||i::text,
	'Bank Address '||i::text,
	lpad(i::text, 9, '0'),
	lpad(i::text, 20, '0')
FROM generate_series(1, :BANK_NUMBER) AS gs(i);


DO
LANGUAGE plpgsql
$$
DECLARE
	i INT;
	j INT;
	bank_count INT;
	client_id INT;
	employee_id INT;
	max_bank_account_per_row INT := 5;
BEGIN
	i := 1;
	SELECT COUNT(*) INTO bank_count FROM bank;

	FOR client_id IN (
		SELECT id FROM client
	) LOOP
		FOR j IN (
			SELECT gs.j FROM generate_series(1, floor(random()*max_bank_account_per_row + 1)::int) as gs(j)
		)
		LOOP
			INSERT INTO bank_account (number, bank_fk, client_fk)
			VALUES (
				lpad(i::text, 10, '0') || lpad(j::text, 10, '0'),
				floor(random()*bank_count + 1),
				client_id
			);
			i := i + 1;
		END LOOP;
	END LOOP;


	FOR employee_id IN (
		SELECT id FROM employee
	) LOOP
		FOR j IN (
			SELECT gs.j FROM generate_series(1, floor(random()*max_bank_account_per_row + 1)::int) as gs(j)
		)
		LOOP
			INSERT INTO bank_account (number, bank_fk, employee_fk)
			VALUES (
				lpad(i::text, 10, '0') || lpad(j::text, 10, '0'),
				floor(random()*bank_count + 1),
				employee_id
			);
			i := i + 1;
		END LOOP;
	END LOOP;
END
$$;


INSERT INTO service (name)
SELECT
	'Service Name '||i::text
FROM generate_series(1, :SERVICE_NUMBER) as gs(i);



INSERT INTO price_list (client_type_fk, created_date, admin_fk, base_price) 
SELECT
	j,
	date '2010-01-01' + i * interval '1 month',
	(
		SELECT id
		FROM employee
		WHERE
			employee_role_fk = 1
			and j::bool
		ORDER BY random()
		LIMIT 1
	),
	100*i*j
FROM (
	SELECT i FROM generate_series(1, 13*12 + 5) as gs(i)
) as gs_1
JOIN (
	SELECT j FROM generate_series(1, 3) as gs(j)
) as gs_2 ON True;



DO
LANGUAGE plpgsql
$$
DECLARE
	price_list RECORD;
	service_id INT;
	max_services_per_price_list INT := 20;
BEGIN
	FOR price_list IN (
		SELECT * FROM price_list
	) LOOP
		FOR service_id IN (
			SELECT id FROM service ORDER BY random() LIMIT floor(random()*(max_services_per_price_list)) + 1
		)
		LOOP
			INSERT INTO price_list_service (price_list_fk, service_fk, price)
			VALUES (price_list.id, service_id, price_list.base_price*10000 + service_id*100);
		END LOOP;
	END LOOP;
END
$$;




DO
LANGUAGE plpgsql
$$
DECLARE
	client RECORD;
	m INT;
	max_main_contracts_per_client INT := 5;
	begin_date DATE;
	inserted_main_contract RECORD;
	s INT;
	service_id INT;
	max_services_per_main_contract INT := 5;
BEGIN
	FOR client IN (
		SELECT * FROM client
	)
	LOOP
		FOR m IN (
			SELECT i FROM generate_series(1, floor(random()*(max_main_contracts_per_client + 1))::int) as gs(i)
		)
		LOOP
			begin_date := (
				now() - (
					(max_main_contracts_per_client - m) / max_main_contracts_per_client::float
				) * (
					now()  - timestamp '2010-01-01 00:00:00'
				)
			)::date;
			INSERT INTO main_contract (client_fk, price_list_fk, manager_fk, lawyer_fk, from_date, to_date, text)
			VALUES (
				client.id,
				(
					SELECT id
					FROM price_list
					WHERE 
						client_type_fk = client.client_type_fk
						AND created_date < begin_date
					ORDER BY created_date DESC
					LIMIT 1
				),
				(
					SELECT id
					FROM employee
					WHERE employee_role_fk = 2
					ORDER BY random()
					LIMIT 1
				),
				(
					SELECT id
					FROM employee
					WHERE employee_role_fk = 3
					ORDER BY random()
					LIMIT 1
				),
				begin_date,
				begin_date + interval '1 year',
				'Main Contract Text '||(floor(random()*1000) + 1)::int||' For Client '||client.id::text
			)
			RETURNING * INTO inserted_main_contract;

			IF random() > 0.2
			THEN
				INSERT INTO contract_payment (main_contract_fk, bank_account_fk, sum, created_at)
				VALUES (
					inserted_main_contract.id,
					(
						SELECT id
						FROM bank_account
						WHERE client_fk = inserted_main_contract.client_fk
						ORDER BY random()
						LIMIT 1
					),
					(
						SELECT base_price*(random() + 0.5)
						FROM price_list
						WHERE price_list.id = inserted_main_contract.price_list_fk
					),
					inserted_main_contract.from_date + interval '1 month' + floor(random()*30)*(interval '1 day')
				);
			END IF;



			FOR s IN (
				SELECT i FROM generate_series(1, floor(random()*(max_services_per_main_contract))::int) as gs(i)
			)
			LOOP
				SELECT service_fk INTO service_id
				FROM price_list_service
				WHERE
					price_list_fk = inserted_main_contract.price_list_fk
				ORDER BY random()
				LIMIT 1;

				INSERT INTO service_contract (main_contract_fk, service_fk, price_list_fk, created_date)
				VALUES (
					inserted_main_contract.id,
					service_id,
					inserted_main_contract.price_list_fk,
					inserted_main_contract.from_date + interval '1 month'
				);


				IF random() > 0.2
				THEN
					INSERT INTO contract_payment (main_contract_fk, bank_account_fk, sum, created_at)
					VALUES (
						inserted_main_contract.id,
						(
							SELECT id
							FROM bank_account
							WHERE client_fk = inserted_main_contract.client_fk
							ORDER BY random()
							LIMIT 1
						),
						(
							SELECT price*(random() + 0.5)
							FROM price_list_service
							WHERE
								price_list_fk = inserted_main_contract.price_list_fk
								AND service_fk = service_id
						),
						inserted_main_contract.from_date + interval '1 month' + floor(random()*30)*(interval '1 day')
					);
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END
$$;


COMMIT;

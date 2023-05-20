BEGIN;

-- ТРИГГЕР 1:
-- для договора на услугу проверять, что указанный прайслист соответствует типу клиента,
-- иначе менять на последний прайслист для этого типа

-- ФУНКЦИЯ 1
CREATE FUNCTION proc_price_list_matches_client_type() RETURNS TRIGGER LANGUAGE plpgsql AS 
$price_list_matches_client_type$
	DECLARE
		actual_client_type_id INT;
		price_list_client_type_id INT;
    BEGIN
    	-- находим настоящий тип клиента
		actual_client_type_id := (
    		SELECT client_type_fk FROM client WHERE id = (
    			SELECT client_fk FROM main_contract WHERE id = NEW.main_contract_fk
    		)
	    );
    	-- находим тип клиента, указанный в прайслисте
		price_list_client_type_id := (
			SELECT client_type_fk FROM price_list WHERE id = NEW.price_list_fk
		);

		-- RAISE NOTICE 'TRIGGER 1: actual_client_type_id=% price_list_client_type_id=%', actual_client_type_id, price_list_client_type_id;

		-- если не совпали типы - заменяем на последний прайслист нужного типа
        IF ( price_list_client_type_id != actual_client_type_id ) THEN
            NEW.price_list_fk := (
            	SELECT id FROM price_list
            	WHERE price_list.client_type_fk = actual_client_type_id
            	ORDER BY price_list.created_date DESC LIMIT 1
            );
        	RAISE NOTICE 'TRIGGER 1: changing price_list_fk to %', NEW.price_list_fk;
        ELSE
        	-- RAISE NOTICE 'TRIGGER 1: price_list_fk=% is OK', NEW.price_list_fk;
        END IF;
      
        RETURN NEW;
    END;
$price_list_matches_client_type$;

-- ТРИГГЕР 1
CREATE TRIGGER tg_price_list_matches_client_type BEFORE INSERT
ON service_contract
FOR EACH ROW
EXECUTE PROCEDURE proc_price_list_matches_client_type();

COMMIT;


-- BEGIN;

-- INSERT INTO main_contract (id, lawyer_fk, manager_fk, client_fk, price_list_fk, from_date, to_date, text) VALUES
-- 	(1, 3, 2, 1, 1, '2023-01-10', '2024-01-10', 'КУПИЛ МУЖИК ШЛЯПУ'),
-- 	(2, 3, 2, 2, 2, '2023-01-10', '2024-01-10', 'ИДЕТ МЕДВЕДЬ ПО ЛЕСУ');

-- -- ПРОВЕРКА РАБОТЫ ТРИГГЕРА 1
-- INSERT INTO service_contract (id, main_contract_fk, service_fk, price_list_fk, created_date) VALUES
-- 	(1, 1, 1, 1, '2023-01-11'),
-- 	(2, 2, 1, 1, '2023-02-11');  -- здесь price_list_fk заменится на 5
-- SELECT price_list_fk FROM service_contract;

-- ROLLBACK;



BEGIN;
-- ТРИГГЕР 2: сумма платежки раскидывается по документам САМА (если сумма маленькая - то несколько платежек на один документ, если большая - то одна платежка на несколько документов)

-- ФУНКЦИЯ 2
CREATE FUNCTION proc_create_payment_proportions() RETURNS TRIGGER LANGUAGE plpgsql AS 
$create_payment_proportions$
	DECLARE
		current_sum INT;
		main_contract_row RECORD;
		main_contract_paid_sum INT;
		main_contract_base_price INT;
		sum_to_pay INT;
		unpaid_contract RECORD;
		unpaid_contract_paid_sum INT;
		unpaid_contract_price INT;
    BEGIN
    	-- RAISE NOTICE 'TRIGGER 2: begin';
    	current_sum := NEW.sum;
    	-- RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    	SELECT * INTO main_contract_row FROM main_contract WHERE id = NEW.main_contract_fk;

    	-- ПРОВЕРЯЕМ СНАЧАЛА ОСНОВНОЙ ДОГОВОР
    	IF main_contract_row.paid = false THEN
    		-- RAISE NOTICE 'TRIGGER 2: looking at main_contract %', NEW.main_contract_fk;
    		-- СКОЛЬКО УЖЕ ОПЛАЧЕНО
	    	main_contract_paid_sum := (
	    		SELECT COALESCE(SUM(contract_payment_sum.sum), 0) FROM contract_payment_sum WHERE main_contract_fk = NEW.main_contract_fk
	    	);

	    	-- СТОИМОСТЬ ИЗ ПРАЙСЛИСТА
	    	main_contract_base_price := (
	    		SELECT base_price FROM price_list WHERE id = main_contract_row.price_list_fk
	    	);
	    	-- RAISE NOTICE 'TRIGGER 2: main_contract_paid_sum %', main_contract_paid_sum;
	    	-- RAISE NOTICE 'TRIGGER 2: main_contract_base_price %', main_contract_base_price;


	    	-- СОЗДАЕМ ПЛАТЕЖКУ
    		sum_to_pay := LEAST(current_sum, main_contract_base_price - main_contract_paid_sum);
    		-- RAISE NOTICE 'TRIGGER 2: pay % for main_contract %', sum_to_pay, NEW.main_contract_fk;
    		INSERT INTO contract_payment_sum (contract_payment_fk, main_contract_fk, sum) VALUES
    			(NEW.id, NEW.main_contract_fk, sum_to_pay);

    		-- ЕСЛИ ОПЛАТИЛИ ПОЛНОСТЬЮ - УСТАНАВЛИВАЕМ ФЛАГ
    		current_sum := current_sum - sum_to_pay;
    		-- RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    		IF main_contract_base_price = main_contract_paid_sum + sum_to_pay THEN
    			-- RAISE NOTICE 'TRIGGER 2: now main_contract % is paid', NEW.main_contract_fk;
    			UPDATE main_contract SET paid=true WHERE id = NEW.main_contract_fk;
    		END IF;
	    END IF;


	    -- ЕСЛИ ОСТАЛАСЬ СУММА - ОПЛАЧИВАЕМ ПОСЛЕДОВАТЕЛЬНО ДОГОВОРЫ НА УСЛУГИ
	    IF current_sum = 0 THEN
	    	-- RAISE NOTICE 'TRIGGER 2: end';
	    	RETURN NULL;
	    END IF;

        FOR unpaid_contract IN (
			SELECT *
			FROM service_contract
			WHERE main_contract_fk = NEW.main_contract_fk AND paid = false
			ORDER BY created_date ASC
		)
		LOOP
			-- RAISE NOTICE 'TRIGGER 2: looking at unpaid_contract %', unpaid_contract.id;
			-- СКОЛЬКО УЖЕ ОПЛАЧЕНО
	    	unpaid_contract_paid_sum := (
	    		SELECT COALESCE(SUM(contract_payment_sum.sum), 0) FROM contract_payment_sum WHERE service_contract_fk = unpaid_contract.id
	    	);
	    	-- СТОИМОСТЬ ИЗ ПРАЙСЛИСТА
	    	unpaid_contract_price := (
	    		SELECT price FROM price_list_service
	    		WHERE price_list_fk = unpaid_contract.price_list_fk AND service_fk = unpaid_contract.service_fk
	    	);
	    	-- RAISE NOTICE 'TRIGGER 2: unpaid_contract_paid_sum %', unpaid_contract_paid_sum;
	    	-- RAISE NOTICE 'TRIGGER 2: unpaid_contract_price %', unpaid_contract_price;


	    	-- СОЗДАЕМ ПЛАТЕЖКУ
    		sum_to_pay := LEAST(current_sum, unpaid_contract_price - unpaid_contract_paid_sum);
    		-- RAISE NOTICE 'TRIGGER 2: pay % for unpaid_contract %', sum_to_pay, unpaid_contract.id;
    		INSERT INTO contract_payment_sum (contract_payment_fk, service_contract_fk, sum) VALUES
    			(NEW.id, unpaid_contract.id, sum_to_pay);

    		-- ЕСЛИ ОПЛАТИЛИ ПОЛНОСТЬЮ - УСТАНАВЛИВАЕМ ФЛАГ
    		current_sum := current_sum - sum_to_pay;
    		-- RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    		IF unpaid_contract_price = unpaid_contract_paid_sum + sum_to_pay THEN
    			-- RAISE NOTICE 'TRIGGER 2: now unpaid_contract % is paid', unpaid_contract.id;
    			UPDATE service_contract SET paid=true WHERE id = unpaid_contract.id;
    		END IF;
    		IF current_sum = 0 THEN
    			-- RAISE NOTICE 'TRIGGER 2: end';
    			RETURN NULL;
    		END IF;
		END LOOP;

		-- ЕСЛИ ОСТАЛАСЬ СУММА, ТО УКАЗЫВАЕМ ЭТО В ПЛАТЕЖКЕ
		-- RAISE NOTICE 'TRIGGER 2: set change % for contract_payment %', current_sum, NEW.id;
		UPDATE contract_payment
		SET sum = sum - current_sum,
			change = current_sum
		WHERE id = NEW.id;

		-- RAISE NOTICE 'TRIGGER 2: end';
		RETURN NULL;
    END;
$create_payment_proportions$;


-- ТРИГГЕР 2
CREATE TRIGGER tg_create_payment_proportions AFTER INSERT
ON contract_payment
FOR EACH ROW
EXECUTE PROCEDURE proc_create_payment_proportions();

COMMIT;



-- BEGIN;

-- -- ПРОВЕРКА РАБОТЫ ТРИГГЕРА 2

-- -- КЕЙС 1:
-- --
-- -- ОСНОВНОЙ ДОГОВОР - 5000
-- -- ДОГОВОР НА УСЛУГУ - 100
-- -- ДОГОВОР НА УСЛУГУ - 200
-- -- ДОГОВОР НА УСЛУГУ - 300
-- -- ДОГОВОР НА УСЛУГУ - 200
-- -- ДОГОВОР НА УСЛУГУ - 400
-- -- ДОГОВОР НА УСЛУГУ - 600
-- --
-- -- ВСЕГО            - 6800
-- --
-- --
-- -- ПЛАТЕЖКА         - 4000
-- -- ПЛАТЕЖКА         -  200
-- -- ПЛАТЕЖКА         - 1000
-- -- ПЛАТЕЖКА         -  500
-- -- ПЛАТЕЖКА         -  800
-- -- ПЛАТЕЖКА         -  400
-- -- 
-- -- ВСЕГО            - 6900
-- --
-- --
-- -- ОПЛАТА           - 4000
-- -- ОПЛАТА           -  200
-- -- ОПЛАТА           -  800
-- -- ОПЛАТА           -  100
-- -- ОПЛАТА           -  100
-- -- ОПЛАТА           -  100
-- -- ОПЛАТА           -  300
-- -- ОПЛАТА           -  100
-- -- ОПЛАТА           -  100
-- -- ОПЛАТА           -  400
-- -- ОПЛАТА           -  300
-- -- ОПЛАТА           -  300
-- -- СДАЧА            -  100




-- INSERT INTO main_contract (id, lawyer_fk, manager_fk, client_fk, price_list_fk, from_date, to_date, text) VALUES
-- 	(1, 3, 2, 1, 1, '2023-01-10', '2024-01-10', 'КУПИЛ МУЖИК ШЛЯПУ');
-- INSERT INTO service_contract (id, main_contract_fk, service_fk, price_list_fk, created_date) VALUES
-- 	(1, 1, 1, 1, '2023-01-11'),
-- 	(2, 1, 2, 1, '2023-01-12'),
-- 	(3, 1, 3, 1, '2023-01-13'),
-- 	(4, 1, 1, 4, '2023-02-11'),
-- 	(5, 1, 2, 4, '2023-02-12'),
-- 	(6, 1, 3, 4, '2023-02-13');

-- -- чтобы сохранить порядок
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(1, 1, 11, 4000);
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(2, 1, 11, 200);
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(3, 1, 11, 1000);
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(4, 1, 11, 500);
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(5, 1, 11, 800);
-- INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
-- 	(6, 1, 11, 400);

-- SELECT id, sum, main_contract_fk, service_contract_fk FROM contract_payment_sum WHERE contract_payment_fk IN (1, 2, 3, 4, 5, 6) ORDER BY created_at ASC;
-- SELECT id, sum, change FROM contract_payment WHERE id IN (1, 2, 3, 4, 5, 6) ORDER BY created_at ASC;
-- ROLLBACK;

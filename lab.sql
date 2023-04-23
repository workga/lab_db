DROP DATABASE IF EXISTS lab_db;
CREATE DATABASE lab_db;

\c lab_db

BEGIN;

-- БАНК
CREATE TABLE bank (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	address VARCHAR(100) NOT NULL,
	bik CHAR(9) CHECK (bik ~ '^[0-9]{9}$'),
	correspondent_account CHAR(20) CHECK (correspondent_account ~ '^[0-9]{20}$')
);

INSERT INTO bank (id, name, address, bik, correspondent_account) VALUES
	(1, 'ЖЕЛТЫЙ БАНК', 'МОСКВА', '100000000', '10000000000000000000'),
	(2, 'ЗЕЛЕНЫЙ БАНК', 'ПИТЕР', '200000000', '20000000000000000000'),
	(3, 'СИНИЙ БАНК', 'ЕКБ', '300000000', '30000000000000000000'),
	(4, 'КРАСНЫЙ БАНК', 'КАЗАНЬ', '400000000', '40000000000000000000');



-- БАНКОВСКИЙ СЧЕТ
CREATE TABLE bank_account (
	id SERIAL PRIMARY KEY,
	number CHAR(20) CHECK (number ~ '^[0-9]{20}$'),
	bank_fk INT REFERENCES bank NOT NULL
);

INSERT INTO bank_account (id, number, bank_fk) VALUES
	(1, '10000000000000000001', 1),
	(2, '10000000000000000002', 1),
	(3, '10000000000000000003', 1),
	(4, '10000000000000000004', 1),
	(5, '20000000000000000001', 2),
	(6, '20000000000000000002', 2),
	(7, '20000000000000000003', 2),
	(8, '20000000000000000004', 2),
	(9, '30000000000000000001', 3),
	(10, '30000000000000000002', 3),
	(11, '30000000000000000003', 3),
	(12, '30000000000000000004', 3),
	(13, '40000000000000000001', 4),
	(14, '40000000000000000002', 4),
	(15, '40000000000000000003', 4),
	(16, '40000000000000000004', 4);



-- ТИП РАБОТНИКА
CREATE TABLE employee_role (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	code VARCHAR(20) CHECK (code ~ '^[0-9]+$')
);

INSERT INTO employee_role (id, name, code) VALUES
	(1, 'admin', 1000), 
	(2, 'manager', 1001),
	(3, 'lawyer', 1002),
	(4, 'bookkeeper', 1003);


-- РАБОТНИК
CREATE TABLE employee (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	inn CHAR(12) CHECK (inn ~ '^[0-9]{12}$'),
	birth_date DATE NOT NULL,
	sex CHAR CHECK (sex IN ('M', 'F')),
	employment_date DATE NOT NULL,
	dismissal_date DATE,
	salary INT NOT NULL,
	employee_role_fk  INT REFERENCES employee_role NOT NULL,
	bank_account_fk INT REFERENCES bank_account NOT NULL
);

INSERT INTO employee (id, name, inn, birth_date, sex, employment_date, salary, employee_role_fk, bank_account_fk) VALUES
	(1, 'Vasya', '100000000000', '2000-01-01', 'M', '2018-01-01', '100000', 1, 1),
	(2, 'Misha', '200000000000', '2000-01-02', 'M', '2018-01-02', '200000', 2, 2),
	(3, 'Stas', '300000000000', '2000-01-03', 'M', '2018-01-03', '300000', 3, 3),
	(4, 'Anna', '400000000000', '2000-01-04', 'F', '2018-01-04', '400000', 4, 4),
	(5, 'Lyosha', '500000000000', '2000-01-05', 'M', '2018-01-05', '500000', 1, 5),
	(6, 'Lika', '600000000000', '2000-01-06', 'F', '2018-01-06', '600000', 2, 6),
	(7, 'Dima', '700000000000', '2000-01-07', 'M', '2018-01-07', '700000', 3, 7),
	(8, 'Rita', '800000000000', '2000-01-08', 'F', '2018-01-08', '800000', 4, 8);


-- ИНФОРМАЦИЯ О КЛИЕНТЕ
CREATE TABLE client_info_ind (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	inn CHAR(12) CHECK (inn ~ '^[0-9]{12}$'),
	passport CHAR(10) CHECK (passport ~ '^[0-9]{10}$')
);

CREATE TABLE client_info_ent (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	inn CHAR(12) CHECK (inn ~ '^[0-9]{12}$'),
	ogrnip CHAR(15) CHECK (ogrnip ~ '^[0-9]{15}$')
);

CREATE TABLE client_info_leg (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	inn CHAR(10) CHECK (inn ~ '^[0-9]{10}$'),
	ogrn CHAR(13) CHECK (ogrn ~ '^[0-9]{13}$'),
	responsible_person VARCHAR(100) NOT NULL
);


-- ТИП КЛИЕНТА
CREATE TABLE client_type (
	id SERIAL PRIMARY KEY,
	type CHAR(3) UNIQUE NOT NULL
);

INSERT INTO client_type (type) VALUES
	('IND'),
	('ENT'),
	('LEG');



-- КЛИЕНТ
CREATE TABLE client (
	id SERIAL PRIMARY KEY,
	client_type_fk INT REFERENCES client_type NOT NULL,
	client_info_ind_fk INT REFERENCES client_info_ind,
	client_info_ent_fk INT REFERENCES client_info_ent,
	client_info_leg_fk INT REFERENCES client_info_leg,
	bank_account_fk INT REFERENCES bank_account NOT NULL
);

INSERT INTO client (id, client_type_fk, bank_account_fk) VALUES -- тут добавить потом фк на информацию о клиенте
	(1, 1, 9),
	(2, 2, 10),
	(3, 3, 11);



-- ПЛАТЕЖКА ЗАРПЛАТЫ -- добавить инсерты
CREATE TABLE salary_payment (
	id SERIAL PRIMARY KEY,
	sum INT NOT NULL,
	date DATE NOT NULL,
	employee_fk INT REFERENCES employee NOT NULL
);




-- УСЛУГА
CREATE TABLE service (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL
);

INSERT INTO service (id, name) VALUES 
	(1, 'ОФОРМЛЕНИЕ КВАДРАТНОГО ДОКУМЕНТА'),
	(2, 'ОФОРМЛЕНИЕ ПРЯМОУГОЛЬНОГО ДОКУМЕНТА'),
	(3, 'ОФОРМЛЕНИЕ КРУГЛОГО ДОКУМЕНТА'),
	(4, 'ОФОРМЛЕНИЕ ТРЕУГОЛЬНОГО ДОКУМЕНТА'),
	(5, 'ОФОРМЛЕНИЕ ОВАЛЬНОГО ДОКУМЕНТА'),
	(6, 'ОФОРМЛЕНИЕ ЭЛЛИПТИЧЕСКОГО ДОКУМЕНТА'),
	(7, 'ОФОРМЛЕНИЕ ГИПЕРБОЛИЧЕСКОГО ДОКУМЕНТА'),
	(8, 'ОФОРМЛЕНИЕ ПАРАБОЛИЧЕСКОГО ДОКУМЕНТА');



-- ПРАЙСЛИСТ
CREATE TABLE price_list (
	id SERIAL PRIMARY KEY,
	client_type_fk INT REFERENCES client_type NOT NULL,
	created_date DATE NOT NULL,
	admin_fk INT REFERENCES employee NOT NULL,
	base_price INT NOT NULL -- правка 2: теперь базовая цена в прайслисте, а не в типе клиента: DONE
);

INSERT INTO price_list (id, client_type_fk, created_date, admin_fk, base_price) VALUES
	(1, 1, '2023-01-01', 1, 5000),
	(2, 2, '2023-01-01', 1, 20000),
	(3, 3, '2023-01-01', 1, 100000),
	(4, 1, '2023-02-01', 1, 5000),
	(5, 2, '2023-02-01', 1, 20000),
	(6, 3, '2023-02-01', 1, 100000);


-- СВЯЗЬ: УСЛУГА - ПРАЙС ЛИСТ
CREATE TABLE price_list_service (
	price_list_fk INT REFERENCES price_list NOT NULL,
	service_fk INT REFERENCES service NOT NULL,
	price INT NOT NULL,
	PRIMARY KEY (service_fk, price_list_fk)
);

INSERT INTO price_list_service (price_list_fk, service_fk, price) VALUES
	(1, 1, 100),
	(1, 2, 200),
	(1, 3, 300),
	(2, 1, 1000),
	(2, 2, 2000),
	(2, 3, 3000),
	(3, 1, 10000),
	(3, 2, 20000),
	(3, 3, 30000),
	(4, 1, 200),
	(4, 2, 400),
	(4, 3, 600),
	(5, 1, 2000),
	(5, 2, 4000),
	(5, 3, 6000),
	(6, 1, 20000),
	(6, 2, 40000),
	(6, 3, 60000);



-- инсерты для оставшихся таблиц делаются во время проверки триггеров

-- ОСНОВНОЙ ДОГОВОР
CREATE TABLE main_contract (
	id SERIAL PRIMARY KEY,
	lawyer_fk INT REFERENCES employee NOT NULL,
	manager_fk INT REFERENCES employee NOT NULL,
	client_fk INT REFERENCES client NOT NULL,
	price_list_fk INT REFERENCES price_list NOT NULL, -- added
	from_date DATE NOT NULL,
	to_date DATE NOT NULL,
	text TEXT NOT NULL,
	paid BOOL NOT NULL DEFAULT false
);


-- ДОГОВОР НА УСЛУГУ
CREATE TABLE service_contract (
	id SERIAL PRIMARY KEY,
	main_contract_fk INT REFERENCES main_contract NOT NULL,
	service_fk INT REFERENCES service NOT NULL,
	price_list_fk INT REFERENCES price_list NOT NULL,
	created_date DATE NOT NULL,
	done_date DATE,
	prepaid BOOL DEFAULT false,
	success BOOL DEFAULT false,
	paid BOOL NOT NULL DEFAULT false
);


-- ПЛАТЕЖКА ДОГОВОРА
CREATE TABLE contract_payment (
	id SERIAL PRIMARY KEY,
	main_contract_fk INT REFERENCES main_contract NOT NULL,
	bank_account_fk INT REFERENCES bank_account NOT NULL, -- правка 1: счет оплаты не привязан к клиенту: DONE
	sum INT NOT NULL CHECK (sum > 0),
	change INT NOT NULL DEFAULT 0,
	created_at TIMESTAMP DEFAULT NOW()
);


-- РАЗДЕЛЕНИЕ ПЛАТЕЖКИ ДОГОВОРА ПО КОНКРЕТНЫМ ДОГОВОРАМ
CREATE TABLE contract_payment_sum (
	id SERIAL PRIMARY KEY,
	contract_payment_fk INT REFERENCES contract_payment NOT NULL,
	service_contract_fk INT REFERENCES service_contract,
	main_contract_fk INT REFERENCES main_contract,
	sum INT NOT NULL,
	CONSTRAINT contract_check CHECK (
		(service_contract_fk IS NOT NULL AND main_contract_fk IS NULL) OR
		(service_contract_fk IS NULL AND main_contract_fk IS NOT NULL)
	),
	created_at TIMESTAMP DEFAULT NOW()
);

COMMIT;





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

		RAISE NOTICE 'TRIGGER 1: actual_client_type_id=% price_list_client_type_id=%', actual_client_type_id, price_list_client_type_id;

		-- если не совпали типы - заменяем на последний прайслист нужного типа
        IF ( price_list_client_type_id != actual_client_type_id ) THEN
            NEW.price_list_fk := (
            	SELECT id FROM price_list
            	WHERE price_list.client_type_fk = actual_client_type_id
            	ORDER BY price_list.created_date DESC LIMIT 1
            );
        	RAISE NOTICE 'TRIGGER 1: changing price_list_fk to %', NEW.price_list_fk;
        ELSE
        	RAISE NOTICE 'TRIGGER 1: price_list_fk=% is OK', NEW.price_list_fk;
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


BEGIN;

INSERT INTO main_contract (id, lawyer_fk, manager_fk, client_fk, price_list_fk, from_date, to_date, text) VALUES
	(1, 3, 2, 1, 1, '2023-01-10', '2024-01-10', 'КУПИЛ МУЖИК ШЛЯПУ'),
	(2, 3, 2, 2, 2, '2023-01-10', '2024-01-10', 'ИДЕТ МЕДВЕДЬ ПО ЛЕСУ');

-- ПРОВЕРКА РАБОТЫ ТРИГГЕРА 1
INSERT INTO service_contract (id, main_contract_fk, service_fk, price_list_fk, created_date) VALUES
	(1, 1, 1, 1, '2023-01-11'),
	(2, 2, 1, 1, '2023-02-11');  -- здесь price_list_fk заменится на 5
SELECT price_list_fk FROM service_contract;

ROLLBACK;



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
    	RAISE NOTICE 'TRIGGER 2: begin';
    	current_sum := NEW.sum;
    	RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    	SELECT * INTO main_contract_row FROM main_contract WHERE id = NEW.main_contract_fk;

    	-- ПРОВЕРЯЕМ СНАЧАЛА ОСНОВНОЙ ДОГОВОР
    	IF main_contract_row.paid = false THEN
    		RAISE NOTICE 'TRIGGER 2: looking at main_contract %', NEW.main_contract_fk;
    		-- СКОЛЬКО УЖЕ ОПЛАЧЕНО
	    	main_contract_paid_sum := (
	    		SELECT COALESCE(SUM(contract_payment_sum.sum), 0) FROM contract_payment_sum WHERE main_contract_fk = NEW.main_contract_fk
	    	);

	    	-- СТОИМОСТЬ ИЗ ПРАЙСЛИСТА
	    	main_contract_base_price := (
	    		SELECT base_price FROM price_list WHERE id = main_contract_row.price_list_fk
	    	);
	    	RAISE NOTICE 'TRIGGER 2: main_contract_paid_sum %', main_contract_paid_sum;
	    	RAISE NOTICE 'TRIGGER 2: main_contract_base_price %', main_contract_base_price;


	    	-- СОЗДАЕМ ПЛАТЕЖКУ
    		sum_to_pay := LEAST(current_sum, main_contract_base_price - main_contract_paid_sum);
    		RAISE NOTICE 'TRIGGER 2: pay % for main_contract %', sum_to_pay, NEW.main_contract_fk;
    		INSERT INTO contract_payment_sum (contract_payment_fk, main_contract_fk, sum) VALUES
    			(NEW.id, NEW.main_contract_fk, sum_to_pay);

    		-- ЕСЛИ ОПЛАТИЛИ ПОЛНОСТЬЮ - УСТАНАВЛИВАЕМ ФЛАГ
    		current_sum := current_sum - sum_to_pay;
    		RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    		IF main_contract_base_price = main_contract_paid_sum + sum_to_pay THEN
    			RAISE NOTICE 'TRIGGER 2: now main_contract % is paid', NEW.main_contract_fk;
    			UPDATE main_contract SET paid=true WHERE id = NEW.main_contract_fk;
    		END IF;
	    END IF;


	    -- ЕСЛИ ОСТАЛАСЬ СУММА - ОПЛАЧИВАЕМ ПОСЛЕДОВАТЕЛЬНО ДОГОВОРЫ НА УСЛУГИ
	    IF current_sum = 0 THEN
	    	RAISE NOTICE 'TRIGGER 2: end';
	    	RETURN NULL;
	    END IF;

        FOR unpaid_contract IN (
			SELECT *
			FROM service_contract
			WHERE main_contract_fk = NEW.main_contract_fk AND paid = false
			ORDER BY created_date ASC
		)
		LOOP
			RAISE NOTICE 'TRIGGER 2: looking at unpaid_contract %', unpaid_contract.id;
			-- СКОЛЬКО УЖЕ ОПЛАЧЕНО
	    	unpaid_contract_paid_sum := (
	    		SELECT COALESCE(SUM(contract_payment_sum.sum), 0) FROM contract_payment_sum WHERE service_contract_fk = unpaid_contract.id
	    	);
	    	-- СТОИМОСТЬ ИЗ ПРАЙСЛИСТА
	    	unpaid_contract_price := (
	    		SELECT price FROM price_list_service
	    		WHERE price_list_fk = unpaid_contract.price_list_fk AND service_fk = unpaid_contract.service_fk
	    	);
	    	RAISE NOTICE 'TRIGGER 2: unpaid_contract_paid_sum %', unpaid_contract_paid_sum;
	    	RAISE NOTICE 'TRIGGER 2: unpaid_contract_price %', unpaid_contract_price;


	    	-- СОЗДАЕМ ПЛАТЕЖКУ
    		sum_to_pay := LEAST(current_sum, unpaid_contract_price - unpaid_contract_paid_sum);
    		RAISE NOTICE 'TRIGGER 2: pay % for unpaid_contract %', sum_to_pay, unpaid_contract.id;
    		INSERT INTO contract_payment_sum (contract_payment_fk, service_contract_fk, sum) VALUES
    			(NEW.id, unpaid_contract.id, sum_to_pay);

    		-- ЕСЛИ ОПЛАТИЛИ ПОЛНОСТЬЮ - УСТАНАВЛИВАЕМ ФЛАГ
    		current_sum := current_sum - sum_to_pay;
    		RAISE NOTICE 'TRIGGER 2: now sum is %', current_sum;
    		IF unpaid_contract_price = unpaid_contract_paid_sum + sum_to_pay THEN
    			RAISE NOTICE 'TRIGGER 2: now unpaid_contract % is paid', unpaid_contract.id;
    			UPDATE service_contract SET paid=true WHERE id = unpaid_contract.id;
    		END IF;
    		IF current_sum = 0 THEN
    			RAISE NOTICE 'TRIGGER 2: end';
    			RETURN NULL;
    		END IF;
		END LOOP;

		-- ЕСЛИ ОСТАЛАСЬ СУММА, ТО УКАЗЫВАЕМ ЭТО В ПЛАТЕЖКЕ
		RAISE NOTICE 'TRIGGER 2: set change % for contract_payment %', current_sum, NEW.id;
		UPDATE contract_payment
		SET sum = sum - current_sum,
			change = current_sum
		WHERE id = NEW.id;

		RAISE NOTICE 'TRIGGER 2: end';
		RETURN NULL;
    END;
$create_payment_proportions$;

-- ТРИГГЕР 2
CREATE TRIGGER tg_create_payment_proportions AFTER INSERT
ON contract_payment
FOR EACH ROW
EXECUTE PROCEDURE proc_create_payment_proportions();

COMMIT;



BEGIN;

-- ПРОВЕРКА РАБОТЫ ТРИГГЕРА 2

-- КЕЙС 1:
--
-- ОСНОВНОЙ ДОГОВОР - 5000
-- ДОГОВОР НА УСЛУГУ - 100
-- ДОГОВОР НА УСЛУГУ - 200
-- ДОГОВОР НА УСЛУГУ - 300
-- ДОГОВОР НА УСЛУГУ - 200
-- ДОГОВОР НА УСЛУГУ - 400
-- ДОГОВОР НА УСЛУГУ - 600
--
-- ВСЕГО            - 6800
--
--
-- ПЛАТЕЖКА         - 4000
-- ПЛАТЕЖКА         -  200
-- ПЛАТЕЖКА         - 1000
-- ПЛАТЕЖКА         -  500
-- ПЛАТЕЖКА         -  800
-- ПЛАТЕЖКА         -  400
-- 
-- ВСЕГО            - 6900
--
--
-- ОПЛАТА           - 4000
-- ОПЛАТА           -  200
-- ОПЛАТА           -  800
-- ОПЛАТА           -  100
-- ОПЛАТА           -  100
-- ОПЛАТА           -  100
-- ОПЛАТА           -  300
-- ОПЛАТА           -  100
-- ОПЛАТА           -  100
-- ОПЛАТА           -  400
-- ОПЛАТА           -  300
-- ОПЛАТА           -  300
-- СДАЧА            -  100




INSERT INTO main_contract (id, lawyer_fk, manager_fk, client_fk, price_list_fk, from_date, to_date, text) VALUES
	(1, 3, 2, 1, 1, '2023-01-10', '2024-01-10', 'КУПИЛ МУЖИК ШЛЯПУ');
INSERT INTO service_contract (id, main_contract_fk, service_fk, price_list_fk, created_date) VALUES
	(1, 1, 1, 1, '2023-01-11'),
	(2, 1, 2, 1, '2023-01-12'),
	(3, 1, 3, 1, '2023-01-13'),
	(4, 1, 1, 4, '2023-02-11'),
	(5, 1, 2, 4, '2023-02-12'),
	(6, 1, 3, 4, '2023-02-13');

-- чтобы сохранить порядок
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(1, 1, 11, 4000);
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(2, 1, 11, 200);
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(3, 1, 11, 1000);
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(4, 1, 11, 500);
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(5, 1, 11, 800);
INSERT INTO contract_payment (id, main_contract_fk, bank_account_fk, sum) VALUES
	(6, 1, 11, 400);

SELECT id, sum, main_contract_fk, service_contract_fk FROM contract_payment_sum WHERE contract_payment_fk IN (1, 2, 3, 4, 5, 6) ORDER BY created_at ASC;
SELECT id, sum, change FROM contract_payment WHERE id IN (1, 2, 3, 4, 5, 6) ORDER BY created_at ASC;
ROLLBACK;











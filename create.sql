BEGIN;

-- ИНФОРМАЦИЯ О КЛИЕНТЕ
CREATE TABLE client_info_ind (
	id SERIAL PRIMARY KEY,
	inn CHAR(12) CHECK (inn ~ '^[0-9]{12}$'),
	passport CHAR(10) CHECK (passport ~ '^[0-9]{10}$')
);

CREATE TABLE client_info_ent (
	id SERIAL PRIMARY KEY,
	inn CHAR(12) CHECK (inn ~ '^[0-9]{12}$'),
	ogrnip CHAR(15) CHECK (ogrnip ~ '^[0-9]{15}$')
);

CREATE TABLE client_info_leg (
	id SERIAL PRIMARY KEY,
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
	name VARCHAR(100) NOT NULL,
	created_at DATE NOT NULL DEFAULT current_date,
	client_type_fk INT REFERENCES client_type NOT NULL,
	client_info_ind_fk INT REFERENCES client_info_ind,
	client_info_ent_fk INT REFERENCES client_info_ent,
	client_info_leg_fk INT REFERENCES client_info_leg
);


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
	employee_role_fk  INT REFERENCES employee_role NOT NULL
);


-- БАНК
CREATE TABLE bank (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	address VARCHAR(100) NOT NULL,
	bik CHAR(9) CHECK (bik ~ '^[0-9]{9}$'),
	correspondent_account CHAR(20) CHECK (correspondent_account ~ '^[0-9]{20}$')
);


-- БАНКОВСКИЙ СЧЕТ
CREATE TABLE bank_account (
	id SERIAL PRIMARY KEY,
	number CHAR(20) UNIQUE CHECK (number ~ '^[0-9]{20}$'),
	bank_fk INT REFERENCES bank NOT NULL,
	client_fk INT REFERENCES client,
	employee_fk INT REFERENCES employee
);


-- УСЛУГА
CREATE TABLE service (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL
);


-- ПРАЙСЛИСТ
CREATE TABLE price_list (
	id SERIAL PRIMARY KEY,
	client_type_fk INT REFERENCES client_type NOT NULL,
	created_date DATE NOT NULL DEFAULT current_date,
	admin_fk INT REFERENCES employee NOT NULL,
	base_price INT NOT NULL -- правка 2: теперь базовая цена в прайслисте, а не в типе клиента: DONE
);



-- СВЯЗЬ: УСЛУГА - ПРАЙС ЛИСТ
CREATE TABLE price_list_service (
	price_list_fk INT REFERENCES price_list NOT NULL,
	service_fk INT REFERENCES service NOT NULL,
	price INT NOT NULL,
	PRIMARY KEY (service_fk, price_list_fk)
);


-- ОСНОВНОЙ ДОГОВОР
CREATE TABLE main_contract (
	id SERIAL PRIMARY KEY,
	manager_fk INT REFERENCES employee NOT NULL,
	lawyer_fk INT REFERENCES employee NOT NULL,
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


-- ПЛАТЕЖКА ЗАРПЛАТЫ
CREATE TABLE salary_payment (
	id SERIAL PRIMARY KEY,
	sum INT NOT NULL,
	date DATE NOT NULL,
	employee_fk INT REFERENCES employee NOT NULL
);

COMMIT;

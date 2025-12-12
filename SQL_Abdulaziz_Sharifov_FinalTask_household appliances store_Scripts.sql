--Final Task

	--TASK 3

CREATE DATABASE appliances_store;

CREATE SCHEMA IF NOT EXISTS store_data;


-- 3.1 Country
CREATE TABLE store_data.country (
    country_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

-- 3.2 Region
CREATE TABLE store_data.region (
    region_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id  INT NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_region_country FOREIGN KEY (country_id)
        REFERENCES store_data.country(country_id)
);

-- 3.3 City
CREATE TABLE store_data.city (
    city_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id INT NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_city_region FOREIGN KEY (region_id)
        REFERENCES store_data.region(region_id)
);

-- 3.4 Location
CREATE TABLE store_data.location (
    location_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_id      INT NOT NULL,
    address_line VARCHAR(255) NOT NULL,
    CONSTRAINT fk_location_city FOREIGN KEY (city_id)
        REFERENCES store_data.city(city_id)
);

-- 3.5 Supplier
CREATE TABLE store_data.supplier (
    supplier_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id    INT NOT NULL,
    supplier_name  VARCHAR(150) NOT NULL UNIQUE,
    contact_person VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    phone          VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT fk_supplier_location FOREIGN KEY (location_id)
        REFERENCES store_data.location(location_id)
);

-- 3.6 Category
CREATE TABLE store_data.category (
    category_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT
);

-- 3.7 Employee
CREATE TABLE store_data.employee (
    employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    position    VARCHAR(50) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    phone       VARCHAR(20),
    hire_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    salary      DECIMAL(10,2)
);

-- 3.8 Customer
CREATE TABLE store_data.customer (
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id INT,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    phone       VARCHAR(20),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT fk_customer_location FOREIGN KEY (location_id)
        REFERENCES store_data.location(location_id)
);

-- 3.9 Product
CREATE TABLE store_data.product (
    product_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id     INT NOT NULL,
    supplier_id     INT NOT NULL,
    sku             VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    brand           VARCHAR(100),
    model           VARCHAR(100),
    price           DECIMAL(10,2) NOT NULL,
    warranty_months INT NOT NULL DEFAULT 0,
    stock_qty       INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    comment         TEXT,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES store_data.category(category_id),
    CONSTRAINT fk_product_supplier FOREIGN KEY (supplier_id)
        REFERENCES store_data.supplier(supplier_id)
);

-- 3.10 Purchase
CREATE TABLE store_data.purchase (
    purchase_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id   INT NOT NULL,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    status        VARCHAR(20) NOT NULL DEFAULT 'ordered',
    CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id)
        REFERENCES store_data.supplier(supplier_id)
);

-- 3.11 Purchase_item 
CREATE TABLE store_data.purchase_item (
    purchase_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id       INT NOT NULL,
    purchase_id      INT NOT NULL,
    quantity         INT NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_pi_product FOREIGN KEY (product_id)
        REFERENCES store_data.product(product_id),
    CONSTRAINT fk_pi_purchase FOREIGN KEY (purchase_id)
        REFERENCES store_data.purchase(purchase_id)
);

-- 3.12 "Order" 
CREATE TABLE store_data."order" (
    order_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  INT NOT NULL,
    employee_id  INT,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    order_date   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES store_data.customer(customer_id),
    CONSTRAINT fk_order_employee FOREIGN KEY (employee_id)
        REFERENCES store_data.employee(employee_id)
);

-- 3.13 Order_item 
CREATE TABLE store_data.order_item (
    order_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
        REFERENCES store_data."order"(order_id),
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id)
        REFERENCES store_data.product(product_id)
);

-- 3.14 Payment
CREATE TABLE store_data.payment (
    payment_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       INT NOT NULL,
    payment_date   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    amount         DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES store_data."order"(order_id)
);

-- 3.15 Inventory_movement
CREATE TABLE store_data.inventory_movement (
    movement_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id      INT NOT NULL,
    employee_id     INT,
    movement_type   VARCHAR(20) NOT NULL,
    quantity_change INT NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    comment         TEXT,
    CONSTRAINT fk_im_product FOREIGN KEY (product_id)
        REFERENCES store_data.product(product_id),
    CONSTRAINT fk_im_employee FOREIGN KEY (employee_id)
        REFERENCES store_data.employee(employee_id)
);


--Constraints
ALTER TABLE store_data.product
    ADD CONSTRAINT chk_product_price CHECK (price > 0);

ALTER TABLE store_data.product
    ADD CONSTRAINT chk_product_warranty CHECK (warranty_months >= 0);

ALTER TABLE store_data.product
    ADD CONSTRAINT chk_product_stock CHECK (stock_qty >= 0);

ALTER TABLE store_data.payment
    ADD CONSTRAINT chk_payment_amount CHECK (amount > 0);

ALTER TABLE store_data.payment
    ADD CONSTRAINT chk_payment_method CHECK (payment_method IN ('cash','card','transfer'));

ALTER TABLE store_data.inventory_movement
    ADD CONSTRAINT chk_movement_type CHECK (movement_type IN ('in','out','adjustment'));

ALTER TABLE store_data.inventory_movement
    ADD CONSTRAINT chk_quantity_change_nonzero CHECK (quantity_change <> 0);

ALTER TABLE store_data."order"
    ADD CONSTRAINT chk_order_total CHECK (total_amount >= 0);

ALTER TABLE store_data."order"
    ADD CONSTRAINT chk_order_status CHECK (status IN ('pending','paid','shipped','cancelled'));

ALTER TABLE store_data.purchase
    ADD CONSTRAINT chk_purchase_total CHECK (total_amount >= 0);

ALTER TABLE store_data.purchase
    ADD CONSTRAINT chk_purchase_status CHECK (status IN ('ordered','received','cancelled'));

ALTER TABLE store_data.order_item
    ADD CONSTRAINT chk_oi_quantity CHECK (quantity > 0);

ALTER TABLE store_data.order_item
    ADD CONSTRAINT chk_oi_price CHECK (unit_price > 0);

ALTER TABLE store_data.purchase_item
    ADD CONSTRAINT chk_pi_quantity CHECK (quantity > 0);

ALTER TABLE store_data.purchase_item
    ADD CONSTRAINT chk_pi_price CHECK (unit_price > 0);




	--TASK 4

--country
INSERT INTO store_data.country (country_name)
	VALUES ('USA'), ('Germany'), ('France'), ('Japan'), ('Uzbekistan'), ('South Korea');

--region
INSERT INTO store_data.region (country_id, region_name)
	VALUES
	((SELECT country_id FROM store_data.country WHERE country_name='USA'), 'California'),
	((SELECT country_id FROM store_data.country WHERE country_name='Germany'), 'Bavaria'),
	((SELECT country_id FROM store_data.country WHERE country_name='France'), 'Île-de-France'),
	((SELECT country_id FROM store_data.country WHERE country_name='Japan'), 'Kanto'),
	((SELECT country_id FROM store_data.country WHERE country_name='Uzbekistan'), 'Tashkent Region'),
	((SELECT country_id FROM store_data.country WHERE country_name='South Korea'), 'Seoul Metro');

--city
INSERT INTO store_data.city (region_id, city_name)
	VALUES
	((SELECT region_id FROM store_data.region WHERE region_name='California'), 'Los Angeles'),
	((SELECT region_id FROM store_data.region WHERE region_name='Bavaria'), 'Munich'),
	((SELECT region_id FROM store_data.region WHERE region_name='Île-de-France'), 'Paris'),
	((SELECT region_id FROM store_data.region WHERE region_name='Kanto'), 'Tokyo'),
	((SELECT region_id FROM store_data.region WHERE region_name='Tashkent Region'), 'Tashkent'),
	((SELECT region_id FROM store_data.region WHERE region_name='Seoul Metro'), 'Seoul');

--location
INSERT INTO store_data.location (city_id, address_line)
	VALUES
	((SELECT city_id FROM store_data.city WHERE city_name='Los Angeles'), 'Sunset Blvd 120'),
	((SELECT city_id FROM store_data.city WHERE city_name='Munich'), 'Marienplatz 7'),
	((SELECT city_id FROM store_data.city WHERE city_name='Paris'), 'Rue de Rivoli 18'),
	((SELECT city_id FROM store_data.city WHERE city_name='Tokyo'), 'Shinjuku 3-24-1'),
	((SELECT city_id FROM store_data.city WHERE city_name='Tashkent'), 'Amir Temur Ave 45'),
	((SELECT city_id FROM store_data.city WHERE city_name='Seoul'), 'Gangnam-daero 55');

--supplier
INSERT INTO store_data.supplier (location_id, supplier_name, contact_person, email, phone)
	VALUES
	((SELECT location_id FROM store_data.location WHERE address_line='Sunset Blvd 120'), 'TechDistributors LA', 'John Adams', 'tdla@example.com', '+12345670001'),
	((SELECT location_id FROM store_data.location WHERE address_line='Marienplatz 7'), 'Bavaria Wholesale', 'Hans Müller', 'bwh@example.com', '+498912340001'),
	((SELECT location_id FROM store_data.location WHERE address_line='Rue de Rivoli 18'), 'Paris Electronics', 'Claire Dubois', 'pe@example.com', '+33123450001'),
	((SELECT location_id FROM store_data.location WHERE address_line='Shinjuku 3-24-1'), 'Tokyo Parts Supply', 'Kenji Sato', 'tps@example.com', '+81345670001'),
	((SELECT location_id FROM store_data.location WHERE address_line='Amir Temur Ave 45'), 'Tashkent Import', 'Aliyev Otabek', 'ti@example.com', '+998901112233'),
	((SELECT location_id FROM store_data.location WHERE address_line='Gangnam-daero 55'), 'Seoul Components', 'Min-Ji Park', 'sc@example.com', '+821012340001');

--category
INSERT INTO store_data.category (category_name, description)
	VALUES
	('Refrigerators', 'Cooling appliances'),
	('Washing Machines', 'Laundry appliances'),
	('TVs', 'Home entertainment'),
	('Air Conditioners', 'Cooling systems'),
	('Vacuum Cleaners', 'Cleaning appliances'),
	('Microwaves', 'Heating appliances');

--employee
INSERT INTO store_data.employee (first_name, last_name, position, email, phone, hire_date, salary)
	VALUES
	('Emily', 'Clark', 'Manager', 'emily.clark@example.com', '+1234000001', '2025-10-10', 2500),
	('David', 'Lee', 'Cashier', 'david.lee@example.com', '+1234000002', '2025-10-22', 1200),
	('Sarah', 'Kim', 'Sales', 'sarah.kim@example.com', '+1234000003', '2025-11-05', 1500),
	('Mark', 'Osmanov', 'Sales', 'mark.osmanov@example.com', '+1234000004', '2025-11-15', 1500),
	('Anna', 'Weiss', 'Warehouse', 'anna.weiss@example.com', '+1234000005', '2025-12-02', 1400),
	('James', 'Cruz', 'Warehouse', 'james.cruz@example.com', '+1234000006', '2025-12-10', 1400);

--customer
INSERT INTO store_data.customer (location_id, first_name, last_name, email, phone, created_at)
	VALUES
	((SELECT location_id FROM store_data.location WHERE address_line='Sunset Blvd 120'), 'Michael', 'Brown', 'mbrown@example.com', '+12341117801', '2025-10-10'),
	((SELECT location_id FROM store_data.location WHERE address_line='Marienplatz 7'), 'Sven', 'Fischer', 'sfischer@example.com', '+49891235901', '2025-10-22'),
	((SELECT location_id FROM store_data.location WHERE address_line='Rue de Rivoli 18'), 'Aline', 'Moreau', 'amoreau@example.com', '+33123459811', '2025-11-05'),
	((SELECT location_id FROM store_data.location WHERE address_line='Shinjuku 3-24-1'), 'Haruto', 'Tanaka', 'htanaka@example.com', '+81345673321', '2025-11-15'),
	((SELECT location_id FROM store_data.location WHERE address_line='Amir Temur Ave 45'), 'Dilshod', 'Karimov', 'dkarimov@example.com', '+998909988776', '2025-12-02'),
	((SELECT location_id FROM store_data.location WHERE address_line='Gangnam-daero 55'), 'Yuna', 'Choi', 'ychoi@example.com', '+821022221234', '2025-12-10');

--product
INSERT INTO store_data.product
(category_id, supplier_id, sku, name, brand, model, price, warranty_months, stock_qty, created_at, comment)
	VALUES
	((SELECT category_id FROM store_data.category WHERE category_name='Refrigerators'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='TechDistributors LA'),
	 'RF001', 'Refrigerator A+', 'Samsung', 'RS5500', 800, 24, 15, '2025-11-12', 'Energy efficient'),
	
	((SELECT category_id FROM store_data.category WHERE category_name='Washing Machines'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Bavaria Wholesale'),
	 'WM010', 'Washer Pro', 'Bosch', 'B1000', 450, 12, 20, '2025-11-25', 'Top load'),
	
	((SELECT category_id FROM store_data.category WHERE category_name='TVs'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Paris Electronics'),
	 'TV900', 'Smart TV 55"', 'LG', 'OLED55C1', 1200, 24, 10, '2025-10-18', '4K OLED'),
	
	((SELECT category_id FROM store_data.category WHERE category_name='Air Conditioners'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Tokyo Parts Supply'),
	 'AC070', 'Air Conditioner', 'Daikin', 'DX350', 900, 18, 12, '2025-10-29', 'Silent mode'),
	
	((SELECT category_id FROM store_data.category WHERE category_name='Vacuum Cleaners'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Tashkent Import'),
	 'VC050', 'Vacuum Cleaner', 'Philips', 'PXC200', 200, 12, 25, '2025-12-03', 'Bagless'),
	
	((SELECT category_id FROM store_data.category WHERE category_name='Microwaves'),
	 (SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Seoul Components'),
	 'MW006', 'Microwave Oven', 'Panasonic', 'MW800', 160, 12, 30, '2025-12-08', '800W');

--purchase
INSERT INTO store_data.purchase (supplier_id, purchase_date, total_amount, status)
	VALUES
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='TechDistributors LA'),
	 '2025-10-05', 3200, 'received'),
	
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Bavaria Wholesale'),
	 '2025-10-12', 2700, 'received'),
	
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Paris Electronics'),
	 '2025-11-01', 5000, 'received'),
	
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Tokyo Parts Supply'),
	 '2025-11-15', 3300, 'received'),
	
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Tashkent Import'),
	 '2025-12-02', 1500, 'received'),
	
	((SELECT supplier_id FROM store_data.supplier WHERE supplier_name='Seoul Components'),
	 '2025-12-12', 2200, 'received');
	

--purchase_item
INSERT INTO store_data.purchase_item (product_id, purchase_id, quantity, unit_price)
	VALUES
	((SELECT product_id FROM store_data.product WHERE sku='RF001'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-10-05'),
	 5, 600),

	((SELECT product_id FROM store_data.product WHERE sku='WM010'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-10-12'),
	 6, 350),
	
	((SELECT product_id FROM store_data.product WHERE sku='TV900'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-11-01'),
	 4, 900),
	
	((SELECT product_id FROM store_data.product WHERE sku='AC070'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-11-15'),
	 5, 700),
	
	((SELECT product_id FROM store_data.product WHERE sku='VC050'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-12-02'),
	 8, 120),
	
	((SELECT product_id FROM store_data.product WHERE sku='MW006'),
	 (SELECT purchase_id FROM store_data.purchase WHERE purchase_date='2025-12-12'),
	 10, 110);

--order
INSERT INTO store_data.order
(customer_id, employee_id, order_number, order_date, status, total_amount)
	VALUES
	((SELECT customer_id FROM store_data.customer WHERE email='mbrown@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='emily.clark@example.com'),
	 'ORD1001', '2025-10-15', 'paid', 800),
	
	((SELECT customer_id FROM store_data.customer WHERE email='sfischer@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='david.lee@example.com'),
	 'ORD1002', '2025-10-28', 'paid', 450),
	
	((SELECT customer_id FROM store_data.customer WHERE email='amoreau@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='sarah.kim@example.com'),
	 'ORD1003', '2025-11-10', 'shipped', 1200),
	
	((SELECT customer_id FROM store_data.customer WHERE email='htanaka@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='mark.osmanov@example.com'),
	 'ORD1004', '2025-11-22', 'paid', 900),
	
	((SELECT customer_id FROM store_data.customer WHERE email='dkarimov@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='anna.weiss@example.com'),
	 'ORD1005', '2025-12-04', 'pending', 200),
	
	((SELECT customer_id FROM store_data.customer WHERE email='ychoi@example.com'),
	 (SELECT employee_id FROM store_data.employee WHERE email='emily.clark@example.com'),
	 'ORD1006', '2025-12-11', 'paid', 160);


--order_item
INSERT INTO store_data.order_item
(order_id, product_id, quantity, unit_price)
	VALUES
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1001'),
	 (SELECT product_id FROM store_data.product WHERE sku='RF001'),
	 1, 800),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1002'),
	 (SELECT product_id FROM store_data.product WHERE sku='WM010'),
	 1, 450),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1003'),
	 (SELECT product_id FROM store_data.product WHERE sku='TV900'),
	 1, 1200),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1004'),
	 (SELECT product_id FROM store_data.product WHERE sku='AC070'),
	 1, 900),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1005'),
	 (SELECT product_id FROM store_data.product WHERE sku='VC050'),
	 1, 200),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1006'),
	 (SELECT product_id FROM store_data.product WHERE sku='MW006'),
	 1, 160);


--payment
INSERT INTO store_data.payment
(order_id, payment_date, amount, payment_method)
	VALUES
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1001'),
	 '2025-10-15', 800, 'card'),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1002'),
	 '2025-10-28', 450, 'cash'),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1003'),
	 '2025-11-10', 1200, 'card'),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1004'),
	 '2025-11-22', 900, 'transfer'),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1005'),
	 '2025-12-05', 200, 'cash'),
	
	((SELECT order_id FROM store_data."order" WHERE order_number='ORD1006'),
	 '2025-12-11', 160, 'card');

--inventory_movement
INSERT INTO store_data.inventory_movement
(product_id, employee_id, movement_type, quantity_change, created_at, comment)
	VALUES
	((SELECT product_id FROM store_data.product WHERE sku='RF001'),
	 (SELECT employee_id FROM store_data.employee WHERE email='anna.weiss@example.com'),
	 'in', 5, '2025-10-06', 'Stock replenishment'),
	
	((SELECT product_id FROM store_data.product WHERE sku='WM010'),
	 (SELECT employee_id FROM store_data.employee WHERE email='james.cruz@example.com'),
	 'in', 6, '2025-10-13', 'Stock replenishment'),
	
	((SELECT product_id FROM store_data.product WHERE sku='TV900'),
	 (SELECT employee_id FROM store_data.employee WHERE email='mark.osmanov@example.com'),
	 'in', 4, '2025-11-02', 'New shipment'),
	
	((SELECT product_id FROM store_data.product WHERE sku='AC070'),
	 (SELECT employee_id FROM store_data.employee WHERE email='sarah.kim@example.com'),
	 'out', -1, '2025-11-23', 'Customer purchase'),
	
	((SELECT product_id FROM store_data.product WHERE sku='VC050'),
	 (SELECT employee_id FROM store_data.employee WHERE email='david.lee@example.com'),
	 'out', -1, '2025-12-05', 'Customer purchase'),
	
	((SELECT product_id FROM store_data.product WHERE sku='MW006'),
	 (SELECT employee_id FROM store_data.employee WHERE email='emily.clark@example.com'),
	 'out', -1, '2025-12-11', 'Customer purchase');
	
	
	
	--TASK 5
	
--5.1 UPDATE
	
CREATE OR REPLACE FUNCTION store_data.update_product_column(
    p_product_id INT,
    p_column_name TEXT,
    p_new_value TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    sql TEXT;
BEGIN
    
    sql := format(
        'UPDATE store_data.product SET %I = %L WHERE product_id = %L',
        p_column_name, p_new_value, p_product_id
    );

    EXECUTE sql;

    RETURN 'Column updated successfully.';
END;
$$;
	
--5.2 TRANSACTION

CREATE OR REPLACE FUNCTION store_data.add_payment_transaction(
    p_order_number TEXT,
    p_amount DECIMAL,
    p_payment_method TEXT,
    p_payment_date TIMESTAMP WITH TIME ZONE DEFAULT now()
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    
    SELECT order_id INTO v_order_id
    FROM store_data."order"
    WHERE order_number = p_order_number;

    IF v_order_id IS NULL THEN
        RETURN 'Order not found.';
    END IF;

   
    INSERT INTO store_data.payment(order_id, payment_date, amount, payment_method)
    VALUES (v_order_id, p_payment_date, p_amount, p_payment_method);

    RETURN 'Payment transaction inserted successfully.';
END;
$$;



	--TASK 6

CREATE OR REPLACE VIEW store_data.v_quarterly_analytics AS
WITH last_date AS (
    SELECT MAX(order_date) AS max_date
    FROM store_data."order"
),
qrange AS (
    SELECT 
        date_trunc('quarter', max_date) AS start_q,
        date_trunc('quarter', max_date) + INTERVAL '3 months' AS end_q
    FROM last_date
)
SELECT DISTINCT
    c.first_name || ' ' || c.last_name AS customer_name,
    e.first_name || ' ' || e.last_name AS employee_name,
    o.order_number,
    o.order_date,
    p.name AS product_name,
    cat.category_name,
    oi.quantity,
    o.total_amount,
    pay.amount AS payment_amount,
    pay.payment_method
FROM store_data."order" o
JOIN store_data.customer c       ON o.customer_id = c.customer_id
LEFT JOIN store_data.employee e  ON o.employee_id = e.employee_id
JOIN store_data.order_item oi    ON o.order_id = oi.order_id
JOIN store_data.product p        ON oi.product_id = p.product_id
JOIN store_data.category cat     ON p.category_id = cat.category_id
LEFT JOIN store_data.payment pay ON o.order_id = pay.order_id
JOIN qrange qr                   ON o.order_date >= qr.start_q 
                                 AND o.order_date < qr.end_q;



	--TASK 7

CREATE ROLE manager
    LOGIN
    PASSWORD 'StrongPassword123';

REVOKE ALL PRIVILEGES ON DATABASE appliances_store FROM manager;
REVOKE ALL PRIVILEGES ON SCHEMA store_data FROM manager;

GRANT CONNECT ON DATABASE appliances_store TO manager;

GRANT USAGE ON SCHEMA store_data TO manager;

GRANT SELECT ON ALL TABLES IN SCHEMA store_data TO manager;

ALTER DEFAULT PRIVILEGES IN SCHEMA store_data
GRANT SELECT ON TABLES TO manager;




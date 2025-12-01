
--DCL Statements

--TASK 2


--Part 1

CREATE ROLE rentaluser
    LOGIN
    PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Part 2

GRANT SELECT ON TABLE public.customer TO rentaluser;

SELECT * FROM public.customer LIMIT 10;

--Part 3

CREATE ROLE rental NOLOGIN;

GRANT rental TO rentaluser;

--for checking
SELECT 
    r.rolname AS role,
    m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname = 'rental';

--Part 4

GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);
--( action is denied)

--Part 5

REVOKE INSERT ON TABLE public.rental FROM rental;

SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'rental'
ORDER BY grantee, privilege_type;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);
--( action is denied)

--Part 6

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM customer c
WHERE 
    EXISTS (SELECT 1 FROM rental r WHERE r.customer_id = c.customer_id)
    AND EXISTS (SELECT 1 FROM payment p WHERE p.customer_id = c.customer_id)
LIMIT 1;

CREATE ROLE client_LINDA_WILLIAMS
    LOGIN
    PASSWORD 'clientpassword';


CREATE SCHEMA IF NOT EXISTS access;

CREATE TABLE IF NOT EXISTS access.customer_role_map (
    role_name text PRIMARY KEY,
    customer_id integer NOT NULL
);

INSERT INTO access.customer_role_map (role_name, customer_id)
VALUES ('client_LINDA_WILLIAMS', 3);

GRANT CONNECT ON DATABASE dvdrental TO client_LINDA_WILLIAMS;

GRANT USAGE ON SCHEMA public TO client_LINDA_WILLIAMS;

GRANT SELECT ON customer TO client_LINDA_WILLIAMS;

--check
SELECT rolname, rolcanlogin 
FROM pg_roles
WHERE rolname = 'client_linda_williams';



--TASK 3

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;


CREATE OR REPLACE FUNCTION access.current_customer_id()
RETURNS int LANGUAGE sql STABLE AS $$
    SELECT customer_id 
    FROM access.customer_role_map
    WHERE role_name = current_user;
$$;

CREATE POLICY rental_customer_policy
ON rental
FOR SELECT
USING (customer_id = access.current_customer_id());


CREATE POLICY payment_customer_policy
ON payment
FOR SELECT
USING (customer_id = access.current_customer_id());


GRANT SELECT ON rental TO client_linda_williams;
GRANT SELECT ON payment TO client_linda_williams;


SET ROLE client_linda_williams;
SELECT * FROM rental;


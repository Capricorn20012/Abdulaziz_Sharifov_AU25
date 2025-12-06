
--DCL Statements

--TASK 2


--Part 1

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
        CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';
    END IF;
END $$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;



--Part 2

GRANT SELECT ON TABLE public.customer TO rentaluser;

SET ROLE rentaluser;
SELECT * FROM public.customer LIMIT 5;
RESET ROLE;


SET ROLE rentaluser;
SELECT * FROM public.customer LIMIT 5;
RESET ROLE;

--Part 3

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rental') THEN
        CREATE ROLE rental NOLOGIN;
    END IF;
END $$;

GRANT rental TO rentaluser;


SELECT 
    r.rolname AS role,
    m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname = 'rental';


--Part 4


GRANT INSERT, UPDATE ON TABLE public.rental TO rental;


GRANT SELECT ON TABLE inventory TO rental;
GRANT SELECT ON TABLE customer TO rental;
GRANT SELECT ON TABLE staff TO rental;
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental;


SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (
    NOW(),
    (SELECT inventory_id FROM inventory LIMIT 1),
    (SELECT customer_id FROM customer LIMIT 1),
    NULL,
    (SELECT staff_id FROM staff LIMIT 1)
);

RESET ROLE;

--Part 5

REVOKE INSERT ON TABLE public.rental FROM rental;


DO $$
DECLARE col text;
BEGIN
    FOR col IN
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'rental'
    LOOP
        EXECUTE format(
            'REVOKE INSERT (%I) ON public.rental FROM rental;', col
        );
    END LOOP;
END $$;


SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'rental'
ORDER BY grantee, privilege_type;


SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (
    NOW(),
    (SELECT inventory_id FROM inventory LIMIT 1),
    (SELECT customer_id FROM customer LIMIT 1),
    NULL,
    (SELECT staff_id FROM staff LIMIT 1)
);

RESET ROLE;



--Part 6

DO $$
DECLARE
    v_customer_id integer;
    v_first_name  text;
    v_last_name   text;
    v_role_name   text;
BEGIN

    SELECT c.customer_id, c.first_name, c.last_name
    INTO v_customer_id, v_first_name, v_last_name
    FROM public.customer c
    WHERE EXISTS (
        SELECT 1 
        FROM public.rental r 
        WHERE r.customer_id = c.customer_id
    )
      AND EXISTS (
        SELECT 1 
        FROM public.payment p 
        WHERE p.customer_id = c.customer_id
    )
    ORDER BY c.customer_id
    LIMIT 1;

    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'No customer with both rental and payment history found';
    END IF;


    v_role_name := format(
        'client_%s_%s',
        lower(regexp_replace(v_first_name, '\s+', '_', 'g')),
        lower(regexp_replace(v_last_name,  '\s+', '_', 'g'))
    );


    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role_name) THEN
        EXECUTE format(
            'CREATE ROLE %I LOGIN PASSWORD %L',
            v_role_name,
            'clientpassword'
        );
    END IF;


    EXECUTE format(
        'GRANT CONNECT ON DATABASE dvdrental TO %I',
        v_role_name
    );
END $$;


SELECT rolname 
FROM pg_roles
WHERE rolname LIKE 'client_%';



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


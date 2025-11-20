
-- TASK 1:



-- PART 1 and PART 2: Add favorite movies

WITH lang AS (
    SELECT language_id 
    FROM public.language 
    WHERE UPPER(name) = 'ENGLISH'
)
INSERT INTO public.film (
    title, description, release_year, language_id,
    rental_rate, rental_duration, last_update
)
SELECT 
    nf.title,
    nf.description,
    nf.release_year,
    (SELECT language_id FROM lang),     
    nf.rental_rate,
    nf.rental_duration,
    CURRENT_DATE
FROM (
    VALUES
        ('Constantine',
         'John Constantine helps a detective investigate her sister''s death, battling demons and his own fate.',
         2005, 4.99, 1),

        ('Hellboy',
         'A demon raised by humans becomes a paranormal investigator fighting dark forces.',
         2004, 9.99, 2),

        ('Dracula',
         'The classic tale of Count Dracula and his tragic obsession (1992 adaptation).',
         1992, 19.99, 3)
) AS nf(title, description, release_year, rental_rate, rental_duration)
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.film f
    WHERE f.title = nf.title
)
RETURNING film_id, title;



-- PART 3: Add actors and film_actor relationships

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT * FROM (
  VALUES
    ('Keanu', 'Reeves', current_date),
    ('Rachel', 'Weisz', current_date),
    ('Ron', 'Perlman', current_date),
    ('Selma', 'Blair', current_date),
    ('Gary', 'Oldman', current_date),
    ('Winona', 'Ryder', current_date)
) AS new_actors(first_name, last_name, last_update)
WHERE NOT EXISTS (
  SELECT 1 FROM public.actor a
  WHERE a.first_name = new_actors.first_name AND a.last_name = new_actors.last_name
)
COMMIT;


-- 3: Link actors to films
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f
    ON f.title IN ('Constantine','Hellboy','Dracula')
JOIN (
    VALUES
        ('Keanu','Reeves'),
        ('Rachel','Weisz'),
        ('Ron','Perlman'),
        ('Selma','Blair'),
        ('Gary','Oldman'),
        ('Winona','Ryder')
) AS v(fn, ln)
    ON a.first_name = v.fn AND a.last_name = v.ln
WHERE NOT EXISTS (
    SELECT 1 FROM public.film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING film_actor_id, actor_id, film_id
COMMIT;


-- PART 4: Add films to store inventory

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, current_date
FROM public.film f
CROSS JOIN (SELECT store_id FROM public.store LIMIT 1) s
WHERE f.title = ANY (ARRAY['Constantine','Hellboy','Dracula'])
AND NOT EXISTS (
  SELECT 1 FROM public.inventory i
  WHERE i.film_id = f.film_id AND i.store_id = s.store_id
);



-- PART 5: Update existing customer 

WITH candidate AS (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON r.customer_id = c.customer_id
    JOIN payment p ON p.customer_id = c.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 43
       AND COUNT(p.payment_id) >= 43
    ORDER BY c.customer_id
    LIMIT 1
),
chosen_address AS (
    SELECT address_id 
    FROM address 
    LIMIT 1
)

UPDATE customer c
SET
    first_name = 'Abdulaziz',
    last_name  = 'Sharifov',
    email      = 'abdulaziz@example.com',
    address_id = (SELECT address_id FROM chosen_address)
WHERE c.customer_id = (SELECT customer_id FROM candidate)
RETURNING customer_id, first_name, last_name, email;



-- PART 6: Delete related records for this customer

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id
    FROM customer
    WHERE first_name = 'Abdulaziz'
      AND last_name  = 'Sharifov'
    LIMIT 1
);


DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id
    FROM customer
    WHERE first_name = 'Abdulaziz'
      AND last_name  = 'Sharifov'
    LIMIT 1
);



-- PART 7: Rent favorite movies and add payments

WITH 
tc AS (
    SELECT customer_id 
    FROM public.customer
    WHERE first_name='Abdulaziz' AND last_name='Sharifov'
),
ti AS (
    SELECT i.inventory_id, f.rental_rate
    FROM public.inventory i
    JOIN public.film f USING(film_id)
    WHERE f.title='Constantine'
    LIMIT 1
),
staff_one AS (
    SELECT staff_id FROM public.staff LIMIT 1
),
rent AS (
    INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id, last_update)
    SELECT 
        DATE '2017-01-15',
        ti.inventory_id,
        tc.customer_id,
        s.staff_id,
        NOW()
    FROM tc, ti, staff_one s
    RETURNING rental_id, customer_id, staff_id, rental_date
)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    r.customer_id,
    r.staff_id,
    r.rental_id,
    ti.rental_rate,
    r.rental_date
FROM rent r
JOIN ti ON true;

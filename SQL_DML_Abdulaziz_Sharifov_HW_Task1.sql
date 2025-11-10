
-- TASK 1:



-- PART 1: Add favorite movies

INSERT INTO public.film
    (title, description, release_year, language_id, last_update)
SELECT * FROM (
  VALUES
    ('Constantine', 'John Constantine helps a detective investigate her sister''s death, battling demons and his own fate.', 2005, 1, current_date),
    ('Hellboy', 'A demon raised by humans becomes a paranormal investigator fighting dark forces.', 2004, 1, current_date),
    ('Dracula', 'The classic tale of Count Dracula and his tragic obsession (1992 adaptation).', 1992, 1, current_date)
) AS new_films(title, description, release_year, language_id, last_update)
WHERE NOT EXISTS (
  SELECT 1 
  FROM public.film f 
  WHERE f.title = new_films.title
);



-- PART 2: Update rental_rate and rental_duration

UPDATE public.film
SET rental_rate = v.rate,
    rental_duration = v.duration,
    last_update = current_date
FROM (
  SELECT title, rental_rate AS rate, rental_duration AS duration FROM (
    VALUES
      ('Constantine', 4.99, 1),
      ('Hellboy', 9.99, 2),
      ('Dracula', 19.99, 3)
  ) AS t(title, rental_rate, rental_duration)
) AS v
WHERE film.title = v.title;



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
);

-- 3: Link actors to films
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title = ANY (ARRAY['Constantine','Hellboy','Dracula'])
WHERE a.first_name || ' ' || a.last_name = ANY (ARRAY[
  'Keanu Reeves','Rachel Weisz','Ron Perlman','Selma Blair','Gary Oldman','Winona Ryder'
])
AND NOT EXISTS (
  SELECT 1 FROM public.film_actor fa
  WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
);



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



-- PART 5: Update existing customer (customer_id = 1)

UPDATE public.customer
SET first_name = 'Abdulaziz',
    last_name = 'Sharifov',
    email = 'abdulaziz@example.com',
    store_id = 1,
    last_update = current_date,
    address_id = (SELECT address_id FROM public.address LIMIT 1)
WHERE customer_id = 1;



-- PART 6: Delete related records for this customer

DELETE FROM public.payment
WHERE customer_id = 1;

DELETE FROM public.rental
WHERE customer_id = 1;



-- PART 7: Rent favorite movies and add payments

-- 7a: Create rentals
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id, last_update)
SELECT current_date, i.inventory_id, 1, 1, current_date
FROM public.inventory i
JOIN public.film f ON f.film_id = i.film_id
WHERE f.title = ANY (ARRAY['Constantine','Hellboy','Dracula'])
AND NOT EXISTS (
  SELECT 1 FROM public.rental r
  WHERE r.inventory_id = i.inventory_id AND r.customer_id = 1
);

-- 7b: Create payments
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date, last_update)
SELECT 1, 1, r.rental_id, f.rental_rate, current_date, current_date
FROM public.rental r
JOIN public.inventory i ON i.inventory_id = r.inventory_id
JOIN public.film f ON f.film_id = i.film_id
WHERE r.customer_id = 1
AND NOT EXISTS (
  SELECT 1 FROM public.payment p
  WHERE p.rental_id = r.rental_id
);

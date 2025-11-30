--Tasks: applying view and functions


--TASK 1

DROP VIEW IF EXISTS public.sales_revenue_by_category_qtr;

CREATE VIEW public.sales_revenue_by_category_qtr AS
SELECT
    c.name AS category_name,
    SUM(p.amount) AS total_revenue,
    date_trunc('quarter', current_date)::date AS quarter_start,
    (date_trunc('quarter', current_date) + interval '3 month' - interval '1 day')::date AS quarter_end,
    EXTRACT(YEAR FROM current_date)::int AS year
FROM public.payment p
JOIN public.rental r        ON r.rental_id     = p.rental_id
JOIN public.inventory i     ON i.inventory_id  = r.inventory_id
JOIN public.film_category fc ON fc.film_id     = i.film_id
JOIN public.category c      ON c.category_id   = fc.category_id
WHERE EXTRACT(YEAR FROM p.payment_date)    = EXTRACT(YEAR FROM current_date)
  AND EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM current_date)
GROUP BY c.name
HAVING SUM(p.amount) > 0;


--TASK 2

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    p_quarter int DEFAULT EXTRACT(QUARTER FROM CURRENT_DATE),
    p_year    int DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
)
RETURNS TABLE (
    category_name text,
    total_revenue numeric,
    quarter_start date,
    quarter_end date,
    year int
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_quarter NOT BETWEEN 1 AND 4 THEN
        RAISE EXCEPTION 'Quarter must be between 1 and 4. Got: %', p_quarter;
    END IF;

    IF p_year < 2000 THEN
        RAISE EXCEPTION 'Year must be >= 2000. Got: %', p_year;
    END IF;

    RETURN QUERY
    WITH q AS (
        SELECT
            date_trunc('quarter', make_date(p_year, (p_quarter - 1) * 3 + 1, 1))::date AS q_start,
            (date_trunc('quarter', make_date(p_year, (p_quarter - 1) * 3 + 1, 1)) 
             + INTERVAL '3 month' - INTERVAL '1 day')::date AS q_end
    )
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue,
        q.q_start AS quarter_start,
        q.q_end AS quarter_end,
        p_year AS year
    FROM q
    JOIN public.payment p 
        ON EXTRACT(YEAR FROM p.payment_date) = p_year
       AND EXTRACT(QUARTER FROM p.payment_date) = p_quarter
    JOIN public.rental r        ON r.rental_id = p.rental_id
    JOIN public.inventory i     ON i.inventory_id = r.inventory_id
    JOIN public.film_category fc ON fc.film_id = i.film_id
    JOIN public.category c      ON c.category_id = fc.category_id
    GROUP BY c.name, q.q_start, q.q_end
    HAVING SUM(p.amount) > 0;

END;
$$;


--TASK 3


CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    p_countries text[]
)
RETURNS TABLE (
    country_name text,
    film_title text,
    rating text,
    language_name text,
    length int,
    release_year int
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec_country text;
    v_country_id int;
    v_max_rentals int;
BEGIN
    
    IF p_countries IS NULL OR array_length(p_countries, 1) IS NULL THEN
        RAISE EXCEPTION 'Input array is empty';
    END IF;

    
    FOREACH rec_country IN ARRAY p_countries LOOP
        
        
        SELECT country_id INTO v_country_id
        FROM public.country
        WHERE LOWER(country) = LOWER(rec_country);

        IF v_country_id IS NULL THEN
            RAISE EXCEPTION 'Country "%" not found in database', rec_country;
        END IF;

        
        SELECT MAX(cnt) INTO v_max_rentals
        FROM (
            SELECT COUNT(r.rental_id) AS cnt
            FROM public.city ci
            JOIN public.address a    ON a.city_id = ci.city_id
            JOIN public.store s      ON s.address_id = a.address_id
            JOIN public.inventory i  ON i.store_id = s.store_id
            JOIN public.film f       ON f.film_id = i.film_id
            LEFT JOIN public.rental r ON r.inventory_id = i.inventory_id
            WHERE ci.country_id = v_country_id
            GROUP BY f.film_id
        ) AS sub;

        
        RETURN QUERY
        SELECT 
            c.country AS country_name,
            f.title AS film_title,
            f.rating,
            l.name AS language_name,
            f.length,
            f.release_year
        FROM public.country c
        JOIN public.city ci      ON ci.country_id = c.country_id
        JOIN public.address a    ON a.city_id = ci.city_id
        JOIN public.store s      ON s.address_id = a.address_id
        JOIN public.inventory i  ON i.store_id = s.store_id
        JOIN public.film f       ON f.film_id = i.film_id
        JOIN public.language l   ON l.language_id = f.language_id
        LEFT JOIN public.rental r ON r.inventory_id = i.inventory_id
        WHERE c.country_id = v_country_id
        GROUP BY 
            c.country, f.title, f.rating, l.name, f.length, f.release_year
        HAVING COUNT(r.rental_id) = v_max_rentals;

    END LOOP;

END;
$$;

SELECT * FROM most_popular_films_by_countries(
    ARRAY['Afghanistan','Brazil','United States']
);


--TASK 4

CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(
    p_title_pattern text
)
RETURNS TABLE (
    "Row_num" int,
    "Film title" text,
    "Language" text,
    "Customer name" text,
    "Rental date" timestamp
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_title_pattern IS NULL OR TRIM(p_title_pattern) = '' THEN
        RAISE EXCEPTION 'Pattern cannot be empty';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.film WHERE title ILIKE p_title_pattern
    ) THEN
        RAISE EXCEPTION 'No films found matching pattern %', p_title_pattern;
    END IF;

    RETURN QUERY
    WITH available_inventory AS (
        SELECT 
            i.inventory_id,
            f.title AS film_title,
            l.name AS language
        FROM public.film f
        JOIN public.language l ON l.language_id = f.language_id
        JOIN public.inventory i ON i.film_id = f.film_id
        WHERE f.title ILIKE p_title_pattern
          AND i.inventory_id NOT IN (
                SELECT inventory_id 
                FROM public.rental 
                WHERE return_date IS NULL
          )
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY ai.film_title)::int AS "Row_num",
        ai.film_title AS "Film title",
        trim(ai.language)::text AS "Language",
        CASE 
            WHEN lr.first_name IS NULL THEN NULL
            ELSE lr.first_name || ' ' || lr.last_name 
        END AS "Customer name",
        lr.rental_date::timestamp AS "Rental date" 
    FROM available_inventory ai
    LEFT JOIN LATERAL (
        SELECT r.rental_date, c.first_name, c.last_name
        FROM public.rental r
        JOIN public.customer c ON c.customer_id = r.customer_id
        WHERE r.inventory_id = ai.inventory_id
        ORDER BY r.rental_date DESC
        LIMIT 1
    ) lr ON TRUE;

END;
$$;



--TASK 5

CREATE OR REPLACE FUNCTION public.new_movie(
    p_title text,
    p_release_year int DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_language text DEFAULT 'Klingon'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_lang_id int;
    v_film_id int;
BEGIN

    IF p_title IS NULL OR TRIM(p_title) = '' THEN
        RAISE EXCEPTION 'Title cannot be empty';
    END IF;

    IF EXISTS (SELECT 1 FROM public.film WHERE LOWER(title) = LOWER(p_title)) THEN
        RAISE EXCEPTION 'Film "%" already exists', p_title;
    END IF;

    SELECT language_id INTO v_lang_id
    FROM public.language
    WHERE LOWER(name) = LOWER(p_language);

    IF v_lang_id IS NULL THEN
        INSERT INTO public.language(name, last_update)
        VALUES (p_language, NOW())
        RETURNING language_id INTO v_lang_id;
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1 INTO v_film_id
    FROM public.film;

    INSERT INTO public.film (
        film_id, title, description,
        release_year, language_id,
        rental_duration, rental_rate,
        replacement_cost, last_update
    )
    VALUES (
        v_film_id, p_title, NULL,
        p_release_year, v_lang_id,
        3, 4.99,
        19.99, NOW()
    );

    RETURN format(
        'Film %s inserted with id %s and language %s',
        p_title, v_film_id, p_language
    );
END;
$$;






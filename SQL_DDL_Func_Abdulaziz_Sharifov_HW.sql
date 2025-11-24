--Tasks: applying view and functions


--TASK 1

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
WITH current_q AS (
    SELECT 
        date_trunc('quarter', CURRENT_DATE)::date AS q_start,
        (date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 month')::date AS q_end
)
SELECT
    c.name AS category_name,
    SUM(p.amount) AS total_revenue,
    cq.q_start AS quarter_start,
    (cq.q_end - 1) AS quarter_end,
    EXTRACT(YEAR FROM cq.q_start)::int AS year
FROM current_q cq
JOIN payment p 
    ON p.payment_date::date >= cq.q_start
   AND p.payment_date::date < cq.q_end
JOIN rental r ON r.rental_id = p.rental_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film_category fc ON fc.film_id = i.film_id
JOIN category c ON c.category_id = fc.category_id
GROUP BY c.name, cq.q_start, cq.q_end
HAVING SUM(p.amount) > 0;


--TASK 2

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    p_date date DEFAULT NULL
)
RETURNS TABLE (
    category_name text,
    total_revenue numeric,
    quarter_start date,
    quarter_end date,
    year int
)
LANGUAGE sql
AS $$
    WITH q AS (
        SELECT 
            date_trunc('quarter', COALESCE(p_date, CURRENT_DATE))::date AS q_start,
            (date_trunc('quarter', COALESCE(p_date, CURRENT_DATE)) 
                 + INTERVAL '3 month')::date AS q_end
    )
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue,
        q.q_start AS quarter_start,
        (q.q_end - 1)::date AS quarter_end,
        EXTRACT(YEAR FROM q.q_start)::int AS year
    FROM q
    JOIN payment p 
        ON p.payment_date::date >= q.q_start
       AND p.payment_date::date <  q.q_end
    JOIN rental r ON r.rental_id = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category c ON c.category_id = fc.category_id
    GROUP BY c.name, q.q_start, q.q_end
    HAVING SUM(p.amount) > 0;
$$;


--TASK 3

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    p_countries text[]
)
RETURNS TABLE (
    country text,
    film_title text,
    rating text,
    language text,
    length int,
    release_year int
)
LANGUAGE sql
AS $$
WITH input_countries AS (
    SELECT unnest(p_countries) AS country_name
),

validated AS (
    SELECT 
        ic.country_name,
        c.country_id,
        c.country
    FROM input_countries ic
    JOIN country c ON c.country = ic.country_name
),

film_stats AS (
    SELECT 
        v.country,
        f.film_id,
        f.title AS film_title,
        f.rating,
        l.name AS language,
        f.length,
        f.release_year,
        COUNT(r.rental_id) AS rentals_count
    FROM validated v
    JOIN city ci      ON ci.country_id = v.country_id
    JOIN address a    ON a.city_id = ci.city_id
    JOIN store s      ON s.address_id = a.address_id
    JOIN inventory i  ON i.store_id = s.store_id
    JOIN film f       ON f.film_id = i.film_id
    JOIN language l   ON l.language_id = f.language_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
    GROUP BY 
        v.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
),

ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY country ORDER BY rentals_count DESC, film_id
        ) AS rn
    FROM film_stats
)

SELECT 
    country,
    film_title,
    rating,
    language,
    length,
    release_year
FROM ranked
WHERE rn = 1;
$$;


--TASK 4

DROP FUNCTION IF EXISTS public.films_in_stock_by_title(text);

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
DECLARE
    r RECORD;
    counter int := 0;
BEGIN
    IF p_title_pattern IS NULL OR p_title_pattern = '' THEN
        RAISE EXCEPTION 'Pattern cannot be empty';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM film f WHERE f.title ILIKE p_title_pattern
    ) THEN
        RAISE EXCEPTION 'No films found matching pattern %', p_title_pattern;
    END IF;

    FOR r IN
        SELECT 
            f.title AS film_title,
            l.name AS language,
            c.first_name || ' ' || c.last_name AS customer_name,
            rt.rental_date AS rental_date
        FROM film f
        JOIN language l ON l.language_id = f.language_id
        JOIN inventory i ON i.film_id = f.film_id

        LEFT JOIN rental rt ON rt.inventory_id = i.inventory_id 
                            AND rt.return_date IS NULL
        LEFT JOIN customer c ON c.customer_id = rt.customer_id

        WHERE f.title ILIKE p_title_pattern
          AND rt.rental_id IS NULL        
    LOOP
        counter := counter + 1;

        "Row_num"     := counter;
        "Film title"  := r.film_title;
        "Language"    := r.language;
        "Customer name" := r.customer_name;
        "Rental date"   := r.rental_date;

        RETURN NEXT;
    END LOOP;

    IF counter = 0 THEN
        RAISE NOTICE 'Films found, but none of them are currently in stock.';
    END IF;

    RETURN;
END;
$$;


--TASK 5

CREATE OR REPLACE FUNCTION new_movie(
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

    IF EXISTS (SELECT 1 FROM film WHERE title = p_title) THEN
        RAISE EXCEPTION 'Film "%" already exists', p_title;
    END IF;

    SELECT language_id INTO v_lang_id
    FROM language
    WHERE name = p_language;

    IF v_lang_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist. Pass correct language.', p_language;
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1
    INTO v_film_id
    FROM film;

    INSERT INTO film (
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

    RETURN format('Film "%" inserted with id % and language "%"', p_title, v_film_id, p_language);
END;
$$;





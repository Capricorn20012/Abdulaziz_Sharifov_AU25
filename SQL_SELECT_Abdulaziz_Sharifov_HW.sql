
--PART 1: Write SQL queries to retrieve the following data--


--TASK 1:
--The goal of this query is to help the marketing team identify all Animation films released between 2017 and 2019 with a rental rate greater than 1. 
--This helps them focus on promoting family-friendly movies that are relatively recent and bring higher rental value.

		-- CTE Solution
		WITH animation_films AS (
		    SELECT 
		        f.title,
		        f.release_year,
		        f.rental_rate,
		        c.name AS category_name
		    FROM public.film f
		    INNER JOIN public.film_category fc 
		        ON f.film_id = fc.film_id
		    INNER JOIN public.category c 
		        ON fc.category_id = c.category_id
		    WHERE c.name = 'Animation'
		      AND f.release_year BETWEEN 2017 AND 2019
		      AND f.rental_rate > 1
		)
		SELECT 
		    title,
		    release_year,
		    rental_rate
		FROM animation_films
		ORDER BY title ASC;
				
				
		-- Subquery Solution
		SELECT 
		    f.title,
		    f.release_year,
		    f.rental_rate
		FROM public.film f
		WHERE f.rental_rate > 1
		  AND f.release_year BETWEEN 2017 AND 2019
		  AND f.film_id IN (
		        SELECT fc.film_id
		        FROM public.film_category fc
		        INNER JOIN public.category c 
		            ON fc.category_id = c.category_id
		        WHERE c.name = 'Animation'
		  )
		ORDER BY f.title ASC;
				
				
		-- JOIN Solution
		SELECT 
		    f.title,
		    f.release_year,
		    f.rental_rate
		FROM public.film f
		INNER JOIN public.film_category fc 
		    ON f.film_id = fc.film_id
		INNER JOIN public.category c 
		    ON fc.category_id = c.category_id
		WHERE c.name = 'Animation'
		  AND f.release_year BETWEEN 2017 AND 2019
		  AND f.rental_rate > 1
		ORDER BY f.title ASC;
		
		

--TASK 2:
--The task requires calculating total revenue for each store starting from April 2017 (i.e., payment_date > '2017-03-31').
--Revenue comes from the public.payment table, which records all payments for rentals.

		-- CTE Solution
		WITH store_revenue AS (
		    SELECT 
		        s.store_id,
		        (a.address || ' ' || COALESCE(a.address2, '')) AS full_address,
		        SUM(p.amount) AS total_revenue
		    FROM public.store s
		    INNER JOIN public.address a 
		        ON s.address_id = a.address_id
		    INNER JOIN public.staff st 
		        ON s.store_id = st.store_id
		    INNER JOIN public.payment p 
		        ON st.staff_id = p.staff_id
		    WHERE p.payment_date > '2017-03-31'
		    GROUP BY s.store_id, a.address, a.address2
		)
		SELECT 
		    full_address AS address,
		    total_revenue AS revenue
		FROM store_revenue
		ORDER BY total_revenue DESC;
		
		
		-- Subquery Solution
		SELECT 
		    (a.address || ' ' || COALESCE(a.address2, '')) AS address,
		    (
		        SELECT SUM(p.amount)
		        FROM public.payment p
		        INNER JOIN public.staff st ON p.staff_id = st.staff_id
		        WHERE st.store_id = s.store_id
		          AND p.payment_date > '2017-03-31'
		    ) AS revenue
		FROM public.store s
		INNER JOIN public.address a 
		    ON s.address_id = a.address_id
		ORDER BY revenue DESC;
		
		
		-- JOIN Solution
		SELECT 
		    (a.address || ' ' || COALESCE(a.address2, '')) AS address,
		    SUM(p.amount) AS revenue
		FROM public.store s
		INNER JOIN public.address a 
		    ON s.address_id = a.address_id
		INNER JOIN public.staff st 
		    ON s.store_id = st.store_id
		INNER JOIN public.payment p 
		    ON st.staff_id = p.staff_id
		WHERE p.payment_date > '2017-03-31'
		GROUP BY a.address, a.address2
		ORDER BY revenue DESC;
		
		
		
--TASK 3: 
--The goal is to find which actors appeared in the most films released after 2015, and list the top 5

		-- CTE Solution
		WITH actor_movie_count AS (
		    SELECT 
		        a.actor_id,
		        a.first_name,
		        a.last_name,
		        COUNT(DISTINCT f.film_id) AS number_of_movies
		    FROM public.actor a
		    INNER JOIN public.film_actor fa 
		        ON a.actor_id = fa.actor_id
		    INNER JOIN public.film f 
		        ON fa.film_id = f.film_id
		    WHERE f.release_year > 2015
		    GROUP BY a.actor_id, a.first_name, a.last_name
		)
		SELECT 
		    first_name,
		    last_name,
		    number_of_movies
		FROM actor_movie_count
		ORDER BY number_of_movies DESC
		LIMIT 5;
		
		
		-- Subquery Solution
		SELECT 
		    a.first_name,
		    a.last_name,
		    (
		        SELECT COUNT(DISTINCT f.film_id)
		        FROM public.film_actor fa
		        INNER JOIN public.film f 
		            ON fa.film_id = f.film_id
		        WHERE fa.actor_id = a.actor_id
		          AND f.release_year > 2015
		    ) AS number_of_movies
		FROM public.actor a
		ORDER BY number_of_movies DESC
		LIMIT 5;
		
		
		-- JOIN Solution
		SELECT 
		    a.first_name,
		    a.last_name,
		    COUNT(DISTINCT f.film_id) AS number_of_movies
		FROM public.actor a
		INNER JOIN public.film_actor fa 
		    ON a.actor_id = fa.actor_id
		INNER JOIN public.film f 
		    ON fa.film_id = f.film_id
		WHERE f.release_year > 2015
		GROUP BY a.actor_id, a.first_name, a.last_name
		ORDER BY number_of_movies DESC
		LIMIT 5;

		

--TASK 4:
--We need to analyze how many Drama, Travel, and Documentary films were released each year.
--This helps the marketing team see which genres are trending or declining over time.


		-- CTE Solution
		WITH category_counts AS (
		    SELECT 
		        f.release_year,
		        c.name AS category_name
		    FROM public.film f
		    INNER JOIN public.film_category fc 
		        ON f.film_id = fc.film_id
		    INNER JOIN public.category c 
		        ON fc.category_id = c.category_id
		    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
		)
		SELECT 
		    release_year,
		    COALESCE(SUM(CASE WHEN category_name = 'Drama' THEN 1 END), 0) AS number_of_drama_movies,
		    COALESCE(SUM(CASE WHEN category_name = 'Travel' THEN 1 END), 0) AS number_of_travel_movies,
		    COALESCE(SUM(CASE WHEN category_name = 'Documentary' THEN 1 END), 0) AS number_of_documentary_movies
		FROM category_counts
		GROUP BY release_year
		ORDER BY release_year DESC;
		
		
		-- Subquery Solution
		SELECT 
		    f.release_year,
		    COALESCE((
		        SELECT COUNT(*)
		        FROM public.film_category fc
		        INNER JOIN public.category c 
		            ON fc.category_id = c.category_id
		        WHERE fc.film_id = f.film_id
		          AND c.name = 'Drama'
		    ), 0) AS number_of_drama_movies,
		    COALESCE((
		        SELECT COUNT(*)
		        FROM public.film_category fc
		        INNER JOIN public.category c 
		            ON fc.category_id = c.category_id
		        WHERE fc.film_id = f.film_id
		          AND c.name = 'Travel'
		    ), 0) AS number_of_travel_movies,
		    COALESCE((
		        SELECT COUNT(*)
		        FROM public.film_category fc
		        INNER JOIN public.category c 
		            ON fc.category_id = c.category_id
		        WHERE fc.film_id = f.film_id
		          AND c.name = 'Documentary'
		    ), 0) AS number_of_documentary_movies
		FROM public.film f
		GROUP BY f.release_year
		ORDER BY f.release_year DESC;
		
		
		-- JOIN Solution
		SELECT 
		    f.release_year,
		    COALESCE(SUM(CASE WHEN c.name = 'Drama' THEN 1 END), 0) AS number_of_drama_movies,
		    COALESCE(SUM(CASE WHEN c.name = 'Travel' THEN 1 END), 0) AS number_of_travel_movies,
		    COALESCE(SUM(CASE WHEN c.name = 'Documentary' THEN 1 END), 0) AS number_of_documentary_movies
		FROM public.film f
		INNER JOIN public.film_category fc 
		    ON f.film_id = fc.film_id
		INNER JOIN public.category c 
		    ON fc.category_id = c.category_id
		WHERE c.name IN ('Drama', 'Travel', 'Documentary')
		GROUP BY f.release_year
		ORDER BY f.release_year DESC;
		
		
		


--PART 2: Solve the following problems using SQL--


--TASK 1:
--We need to find the top 3 employees who generated the highest total revenue in 2017 from the public.payment table.
--Each payment is linked to a staff_id, and each staff member belongs to a store.
--We sum all payments per staff in 2017, determine their latest store, and select the top 3 by total revenue.


		-- CTE Solution
		WITH staff_revenue AS (
		    SELECT 
		        st.staff_id,
		        st.first_name,
		        st.last_name,
		        SUM(p.amount) AS total_revenue
		    FROM public.staff st
		    INNER JOIN public.payment p 
		        ON st.staff_id = p.staff_id
		    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
		    GROUP BY st.staff_id, st.first_name, st.last_name
		),
		latest_store AS (
		    SELECT DISTINCT ON (p.staff_id)
		        p.staff_id,
		        s.store_id
		    FROM public.payment p
		    INNER JOIN public.staff st ON p.staff_id = st.staff_id
		    INNER JOIN public.store s ON st.store_id = s.store_id
		    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
		    ORDER BY p.staff_id, p.payment_date DESC
		)
		SELECT 
		    sr.first_name,
		    sr.last_name,
		    ls.store_id,
		    sr.total_revenue
		FROM staff_revenue sr
		INNER JOIN latest_store ls 
		    ON sr.staff_id = ls.staff_id
		ORDER BY sr.total_revenue DESC
		LIMIT 3;
		
		
		-- Subquery Solution
		SELECT 
		    st.first_name,
		    st.last_name,
		    (
		        SELECT s.store_id
		        FROM public.payment p2
		        INNER JOIN public.staff st2 ON p2.staff_id = st2.staff_id
		        INNER JOIN public.store s ON st2.store_id = s.store_id
		        WHERE p2.staff_id = st.staff_id
		          AND EXTRACT(YEAR FROM p2.payment_date) = 2017
		        ORDER BY p2.payment_date DESC
		        LIMIT 1
		    ) AS store_id,
		    SUM(p.amount) AS total_revenue
		FROM public.staff st
		INNER JOIN public.payment p 
		    ON st.staff_id = p.staff_id
		WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
		GROUP BY st.staff_id, st.first_name, st.last_name
		ORDER BY total_revenue DESC
		LIMIT 3;
		
		
		-- JOIN Solution
		SELECT 
		    st.first_name,
		    st.last_name,
		    st.store_id,
		    SUM(p.amount) AS total_revenue
		FROM public.staff st
		INNER JOIN public.payment p 
		    ON st.staff_id = p.staff_id
		WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
		GROUP BY st.staff_id, st.first_name, st.last_name, st.store_id
		ORDER BY total_revenue DESC
		LIMIT 3;


		
--TASK 2:
--We need to identify the top 5 most rented movies and determine the expected audience age for each based on the MPA rating.
--We count rentals per film from public.rental, link to public.inventory and public.film to get titles and ratings, then display the 5 films with the highest rental counts.	


		-- CTE Solution
		WITH film_rentals AS (
		    SELECT 
		        i.film_id,
		        COUNT(r.rental_id) AS rental_count
		    FROM public.rental r
		    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
		    GROUP BY i.film_id
		)
		SELECT 
		    f.title,
		    f.rating,
		    fr.rental_count,
		    CASE f.rating
		        WHEN 'G' THEN 'All ages'
		        WHEN 'PG' THEN 'Children with parental guidance'
		        WHEN 'PG-13' THEN 'Teens 13+'
		        WHEN 'R' THEN 'Adults 17+'
		        WHEN 'NC-17' THEN 'Adults 18+ only'
		        ELSE 'Unrated'
		    END AS expected_audience
		FROM public.film f
		INNER JOIN film_rentals fr ON f.film_id = fr.film_id
		ORDER BY fr.rental_count DESC
		LIMIT 5;
				
		
		-- Using subquery
		SELECT 
		    f.title,
		    f.rating,
		    (
		        SELECT COUNT(*)
		        FROM public.rental r
		        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
		        WHERE i.film_id = f.film_id
		    ) AS rental_count,
		    CASE f.rating
		        WHEN 'G' THEN 'All ages'
		        WHEN 'PG' THEN 'Children with parental guidance'
		        WHEN 'PG-13' THEN 'Teens 13+'
		        WHEN 'R' THEN 'Adults 17+'
		        WHEN 'NC-17' THEN 'Adults 18+ only'
		        ELSE 'Unrated'
		    END AS expected_audience
		FROM public.film f
		ORDER BY rental_count DESC
		LIMIT 5;
		
		
		-- Using JOIN directly
		SELECT 
		    f.title,
		    f.rating,
		    COUNT(r.rental_id) AS rental_count,
		    CASE f.rating
		        WHEN 'G' THEN 'All ages'
		        WHEN 'PG' THEN 'Children with parental guidance'
		        WHEN 'PG-13' THEN 'Teens 13+'
		        WHEN 'R' THEN 'Adults 17+'
		        WHEN 'NC-17' THEN 'Adults 18+ only'
		        ELSE 'Unrated'
		    END AS expected_audience
		FROM public.film f
		INNER JOIN public.inventory i ON f.film_id = i.film_id
		INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
		GROUP BY f.film_id, f.title, f.rating
		ORDER BY rental_count DESC
		LIMIT 5;
		
		


--PART 3: Which actors/actresses didn't act for a longer period of time than the others? L--


--V1:
--The marketing team wants to find actors with the longest inactivity periods.


		-- V1: Using CTE
		WITH actor_latest AS (
		    SELECT 
		        a.actor_id,
		        a.first_name,
		        a.last_name,
		        MAX(f.release_year) AS last_movie_year
		    FROM public.actor a
		    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
		    INNER JOIN public.film f ON f.film_id = fa.film_id
		    GROUP BY a.actor_id, a.first_name, a.last_name
		)
		SELECT 
		    first_name,
		    last_name,
		    EXTRACT(YEAR FROM CURRENT_DATE) - last_movie_year AS inactivity_years
		FROM actor_latest
		ORDER BY inactivity_years DESC;
		
		
		-- V1: Using subquery
		SELECT 
		    a.first_name,
		    a.last_name,
		    EXTRACT(YEAR FROM CURRENT_DATE) - (
		        SELECT MAX(f.release_year)
		        FROM public.film f
		        INNER JOIN public.film_actor fa ON f.film_id = fa.film_id
		        WHERE fa.actor_id = a.actor_id
		    ) AS inactivity_years
		FROM public.actor a
		ORDER BY inactivity_years DESC;
		
		
		-- V1: Using JOIN directly
		SELECT 
		    a.first_name,
		    a.last_name,
		    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS inactivity_years
		FROM public.actor a
		INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
		INNER JOIN public.film f ON f.film_id = fa.film_id
		GROUP BY a.actor_id, a.first_name, a.last_name
		ORDER BY inactivity_years DESC;


		
--V2:

		-- V2: Using CTE
		WITH actor_films AS (
		    SELECT 
		        a.actor_id,
		        a.first_name,
		        a.last_name,
		        f.release_year
		    FROM public.actor a
		    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
		    INNER JOIN public.film f ON f.film_id = fa.film_id
		),
		film_gaps AS (
		    SELECT 
		        af1.actor_id,
		        af1.first_name,
		        af1.last_name,
		        MAX(af2.release_year - af1.release_year) AS max_gap
		    FROM actor_films af1
		    INNER JOIN actor_films af2 ON af1.actor_id = af2.actor_id AND af2.release_year > af1.release_year
		    GROUP BY af1.actor_id, af1.first_name, af1.last_name
		)
		SELECT *
		FROM film_gaps
		ORDER BY max_gap DESC;
		
		
		-- V2: Using subquery
		SELECT 
		    a.first_name,
		    a.last_name,
		    (
		        SELECT MAX(f2.release_year - f1.release_year)
		        FROM public.film_actor fa1
		        INNER JOIN public.film f1 ON f1.film_id = fa1.film_id
		        INNER JOIN public.film_actor fa2 ON fa1.actor_id = fa2.actor_id
		        INNER JOIN public.film f2 ON f2.film_id = fa2.film_id
		        WHERE fa1.actor_id = a.actor_id AND f2.release_year > f1.release_year
		    ) AS max_gap
		FROM public.actor a
		ORDER BY max_gap DESC;
		
		
		-- V2: Using JOIN directly
		SELECT 
		    a.first_name,
		    a.last_name,
		    MAX(f2.release_year - f1.release_year) AS max_gap
		FROM public.actor a
		INNER JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
		INNER JOIN public.film f1 ON fa1.film_id = f1.film_id
		INNER JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
		INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
		WHERE f2.release_year > f1.release_year
		GROUP BY a.actor_id, a.first_name, a.last_name
		ORDER BY max_gap DESC;



		
--The advantages and disadvantages(CTE, Subquery, JOIN)

--CTE (Common Table Expression):
--CTE makes queries easier to read and understand because it lets you build the result step by step. 
--It’s very useful when a query has many parts or needs to reuse the same logic. 
--But sometimes it can use a bit more memory, and in some databases it can be slower than a normal join if used many times.

--Subquery:
--Subqueries are short and simple for small tasks, especially when you just need to get one value or count from another table. 
--But they can become hard to read if you use many of them, and sometimes they make the query run slower 
--because the database has to run the inner query multiple times.

--JOIN:
--JOIN is usually the most common and fast way to combine tables. 
--It clearly shows how data from different tables are connected. 
--It’s also easier for the database to optimize. 
--The only downside is that when you have many tables, the query can become long and harder to read.


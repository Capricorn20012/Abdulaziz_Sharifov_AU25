
--TASK 2


----Part 1: Creating table

CREATE TABLE table_to_delete as
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

--Updated Rows : 10000000
--Execute time : 23s
--Start time   : Mon Nov 21:17:14 QYZT 2025
--Finish time  : Mon Nov 21:17:38 QYZT 2025

----Part 2: 

SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_only
FROM (
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

--oid : 17,517
--total_bytes : 602,611,712
--index_bytes : 0
--toast_bytes : 8,192
--table_bytes : 602,603,520
--table_only  : 575 MB



----Part 3

--a

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

--b
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_only
FROM (
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

--c
VACUUM FULL VERBOSE table_to_delete;

--d
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_only
FROM (
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

--e
DROP TABLE IF EXISTS table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

--a) DELETE_statement : 11s 
		--(The DELETE operation took about 11 seconds.
		--It is slow because PostgreSQL has to scan all 10 million rows and mark some of them as deleted.)
--b) Table_size  : 575 MB
		--The table size did not change, DELETE only marks rows as deleted internally. 
--c) Execute_time : 4.4s, found 0 removable, 6666667 nonremovable row versions in 73536 pages
		--VACUUM FULL rebuilds the whole table and removes the deleted rows permanently
--d) --total_bytes : 401,580,032
	 --index_bytes : 0
	 --toast_bytes : 8,192
	 --table_bytes : 401,571,840
	 --table_only  : 383 MB
	 	--After VACUUM FULL, the table size decreased to 383 MB,
	 	--Only the remaining (live) rows are written into the new table file, so the table becomes physically smaller.



----Part 4

--a
TRUNCATE table_to_delete;

--b
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_only
FROM (
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

--a) Execute_time : 0.0s
		--TRUNCATE finished instantly (0.0 seconds). TRUNCATE does not delete rows one by one.
        --It simply removes all data by resetting the table, which is extremely fast.
--b) TRUNCATE was very fast comparing to DELETE
		--DELETE is slow because it processes rows individually, DELETE does not reduce table size.
		--TRUNCATE is almost instant, TRUNCATE frees all disk space immediately.
--c) --total_bytes : 8,192
	 --index_bytes : 0
	 --toast_bytes : 8,192
	 --table_bytes : 0
	 --table_only  : 0 MB
		--After TRUNCATE, the table size was only 8 KB (minimum size for an empty table).
        --TRUNCATE releases all storage and leaves only the empty table structure.


----Part 5
--a)Space consumption after creating a table 	= 575 MB
  --Space consumption after DELETE of 1/3 rows= 575 MB
  --Space consumption after VACUUM 			= 383 MB
  --Space consumption after TRUNCATE 			= 8KB
--b)Execution time of the DELETE function 	= 4.4s
  --Execution time of the TRUNCATE function	= 0.0s


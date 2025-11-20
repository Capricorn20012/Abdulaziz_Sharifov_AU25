
--DDL Homework


--Creating Database and schema
CREATE DATABASE recruitment_agency;
CREATE SCHEMA IF NOT EXISTS agency_data;


--Creating 17 tables


--1) Table country
CREATE TABLE IF NOT EXISTS agency_data.country (
    country_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL unique);
   
    
--2) Table region   
CREATE TABLE IF NOT EXISTS agency_data.region (
    region_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id INT NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (country_id) REFERENCES agency_data.country(country_id));
    
    
--3) Table city  
CREATE TABLE IF NOT EXISTS agency_data.city (
    city_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id INT NOT NULL,
    city_name VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (region_id) REFERENCES agency_data.region(region_id));
    
    
--4) Table location      
CREATE TABLE IF NOT EXISTS agency_data.location (
    location_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_id INT NOT NULL,
    address_line VARCHAR(255),
    FOREIGN KEY (city_id) REFERENCES agency_data.city(city_id));
    
    
--5) Table industry      
CREATE TABLE IF NOT EXISTS agency_data.industry (
    industry_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    industry_name VARCHAR(50) NOT NULL UNIQUE
);


--6) Table employer  
CREATE TABLE IF NOT EXISTS agency_data.employer (
    employer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    industry_id INT NOT NULL,
    location_id INT NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100) NOT NULL UNIQUE,
    contact_phone VARCHAR(20) UNIQUE,
    FOREIGN KEY (industry_id) REFERENCES agency_data.industry(industry_id),
    FOREIGN KEY (location_id) REFERENCES agency_data.location(location_id));
  
    
--7) Table job
CREATE TABLE IF NOT EXISTS agency_data.job (
    job_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employer_id INT NOT NULL,
    location_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    salary_min DECIMAL(10,2) CHECK (salary_min >= 0),
    salary_max DECIMAL(10,2) CHECK (salary_max >= 0),
    posted_date DATE NOT NULL CHECK (posted_date > '2000-01-01'),
    status VARCHAR(20) CHECK (status IN ('Open', 'Closed', 'Paused')),
    FOREIGN KEY (employer_id) REFERENCES agency_data.employer(employer_id),
    FOREIGN KEY (location_id) REFERENCES agency_data.location(location_id)
);


--8) Table skill
CREATE TABLE IF NOT EXISTS agency_data.skill (
    skill_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL
);


--9) Table education_level
CREATE TABLE IF NOT EXISTS agency_data.education_level (
    education_level_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    education_level VARCHAR(50) NOT NULL UNIQUE
);


--10) Table candidate
CREATE TABLE IF NOT EXISTS agency_data.candidate (
    candidate_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    education_level_id INT NOT NULL,
    location_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    experience_years INT NOT NULL CHECK (experience_years >= 0),
    FOREIGN KEY (education_level_id) REFERENCES agency_data.education_level(education_level_id),
    FOREIGN KEY (location_id) REFERENCES agency_data.location(location_id)
);


--11) Table job_skill
CREATE TABLE agency_data.job_skill (
    job_id INT NOT NULL,
    skill_id INT NOT NULL,
    required_level VARCHAR(20) CHECK (required_level IN ('Beginner', 'Intermediate', 'Advanced')) NOT NULL,
    PRIMARY KEY (job_id, skill_id),
    FOREIGN KEY (job_id) REFERENCES agency_data.job(job_id),
    FOREIGN KEY (skill_id) REFERENCES agency_data.skill(skill_id)
);


--12) Table candidate_skill
CREATE TABLE agency_data.candidate_skill (
    candidate_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level VARCHAR(20) CHECK (proficiency_level IN ('Beginner', 'Intermediate', 'Advanced')) NOT NULL,
    PRIMARY KEY (candidate_id, skill_id),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (skill_id) REFERENCES agency_data.skill(skill_id)
);


--13) Table services
CREATE TABLE IF NOT EXISTS agency_data.services (
    service_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0)
);


--14) Table candidate_service
CREATE TABLE agency_data.candidate_service (
    candidate_id INT NOT NULL,
    service_id INT NOT NULL,
    status VARCHAR(20),
    purchase_date DATE NOT NULL CHECK (purchase_date > '2000-01-01'),
    PRIMARY KEY (candidate_id, service_id),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (service_id) REFERENCES agency_data.services(service_id)
);


--15) Table application 
CREATE TABLE IF NOT EXISTS agency_data.application (
    application_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidate_id INT NOT NULL,
    job_id INT NOT NULL,
    application_date DATE NOT NULL CHECK (application_date > '2000-01-01'),
    status VARCHAR(20) CHECK (status IN ('Submitted', 'Reviewed', 'Rejected', 'Accepted')),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (job_id) REFERENCES agency_data.job(job_id)
);


--16) Table interview
CREATE TABLE IF NOT EXISTS agency_data.interview (
    interview_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id INT NOT NULL,
    interview_date TIMESTAMP NOT NULL CHECK (interview_date > '2000-01-01'),
    interviewer_name VARCHAR(100),
    result VARCHAR(20) CHECK (result IN ('Passed', 'Failed', 'Pending')),
    notes TEXT,
    FOREIGN KEY (application_id) REFERENCES agency_data.application(application_id)
);


--17) Table placement
CREATE TABLE IF NOT EXISTS agency_data.placement (
    placement_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id INT NOT NULL,
    candidate_id INT NOT NULL,
    start_date DATE NOT NULL CHECK (start_date > '2000-01-01'),
    end_date DATE,
    salary_offered DECIMAL(10,2) NOT NULL CHECK (salary_offered > 0),
    FOREIGN KEY (job_id) REFERENCES agency_data.job(job_id),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id)
);



--Adding Samples

--1) Table country
	INSERT INTO agency_data.country (country_name)
	VALUES 
	('Uzbekistan'),
	('Germany')
	ON CONFLICT DO NOTHING;

--2) Table region  
	INSERT INTO agency_data.region (country_id, region_name)
	SELECT c.country_id, 'Tashkent Region'
	FROM agency_data.country c
	WHERE c.country_name = 'Uzbekistan'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.region (country_id, region_name)
	SELECT c.country_id, 'Bavaria'
	FROM agency_data.country c
	WHERE c.country_name = 'Germany'
	ON CONFLICT DO NOTHING;

--3) Table city  
	INSERT INTO agency_data.city (region_id, city_name)
	SELECT r.region_id, 'Tashkent'
	FROM agency_data.region r
	WHERE r.region_name = 'Tashkent Region'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.city (region_id, city_name)
	SELECT r.region_id, 'Munich'
	FROM agency_data.region r
	WHERE r.region_name = 'Bavaria'
	ON CONFLICT DO NOTHING;

--4) Table location 
	INSERT INTO agency_data.location (city_id, address_line)
	SELECT c.city_id, 'Chilanzar 15'
	FROM agency_data.city c
	WHERE c.city_name = 'Tashkent'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.location (city_id, address_line)
	SELECT c.city_id, 'Marienplatz 1'
	FROM agency_data.city c
	WHERE c.city_name = 'Munich'
	ON CONFLICT DO NOTHING;

--5) Table industry
	INSERT INTO agency_data.industry (industry_name)
	VALUES 
	('IT'),
	('Construction')
	ON CONFLICT DO NOTHING;

--6) Table employer 
	INSERT INTO agency_data.employer (industry_id, location_id, company_name, contact_name, contact_email, contact_phone)
	SELECT 
	    i.industry_id,
	    l.location_id,
	    'Tech Solutions',
	    'Kim Alex',
	    'alice@tech.com',
	    '+998901234567'
	FROM agency_data.industry i
	JOIN agency_data.location l ON l.address_line = 'Chilanzar 15'
	WHERE i.industry_name = 'IT'
	ON CONFLICT DO NOTHING;


	INSERT INTO agency_data.employer (industry_id, location_id, company_name, contact_name, contact_email, contact_phone)
	SELECT 
	    i.industry_id,
	    l.location_id,
	    'BuildCorp',
	    'Bob Müller',
	    'bob@build.com',
	    '+498912345678'
	FROM agency_data.industry i
	JOIN agency_data.location l ON l.address_line = 'Marienplatz 1'
	WHERE i.industry_name = 'Construction'
	ON CONFLICT DO NOTHING;

--7) Table job
	INSERT INTO agency_data.job (employer_id, location_id, title, description, salary_min, salary_max, posted_date, status)
	SELECT 
	    e.employer_id,
	    e.location_id,
	    'Software Engineer',
	    'Develop software applications',
	    1000.00,
	    2000.00,
	    '2025-01-01',
	    'Open'
	FROM agency_data.employer e
	WHERE e.company_name = 'Tech Solutions'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.job (employer_id, location_id, title, description, salary_min, salary_max, posted_date, status)
	SELECT 
	    e.employer_id,
	    e.location_id,
	    'Project Manager',
	    'Manage construction projects',
	    1500.00,
	    2500.00,
	    '2025-01-05',
	    'Open'
	FROM agency_data.employer e
	WHERE e.company_name = 'BuildCorp'
	ON CONFLICT DO NOTHING;

--8) Table skill
	INSERT INTO agency_data.skill (skill_name, category)
	VALUES 
	('Python', 'Programming'),
	('Project Management', 'Management')
	ON CONFLICT DO NOTHING;

--9) Table education_level
	INSERT INTO agency_data.education_level (education_level)
	VALUES 
	('Bachelor'),
	('Master')
	ON CONFLICT DO NOTHING;

--10) Table candidate
	INSERT INTO agency_data.candidate (education_level_id, location_id, first_name, last_name, email, phone, experience_years)
	SELECT 
	    e.education_level_id,
	    l.location_id,
	    'Abdulaziz',
	    'Sharifov',
	    'john@example.com',
	    '+998901112233',
	    3
	FROM agency_data.education_level e
	JOIN agency_data.location l ON l.address_line = 'Chilanzar 15'
	WHERE e.education_level = 'Bachelor'
	ON CONFLICT DO NOTHING;
	
	
	INSERT INTO agency_data.candidate (education_level_id, location_id, first_name, last_name, email, phone, experience_years)
	SELECT 
	    e.education_level_id,
	    l.location_id,
	    'Maria',
	    'Schmidt',
	    'maria@example.de',
	    '+498912223344',
	    5
	FROM agency_data.education_level e
	JOIN agency_data.location l ON l.address_line = 'Marienplatz 1'
	WHERE e.education_level = 'Master'
	ON CONFLICT DO NOTHING;

--11) Table job_skill
	INSERT INTO agency_data.job_skill (job_id, skill_id, required_level)
	SELECT 
	    j.job_id,
	    s.skill_id,
	    'Advanced'
	FROM agency_data.job j, agency_data.skill s
	WHERE j.title = 'Software Engineer'
	  AND s.skill_name = 'Python'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.job_skill (job_id, skill_id, required_level)
	SELECT 
	    j.job_id,
	    s.skill_id,
	    'Intermediate'
	FROM agency_data.job j, agency_data.skill s
	WHERE j.title = 'Project Manager'
	  AND s.skill_name = 'Project Management'
	ON CONFLICT DO NOTHING;

--12) Table candidate_skill
	INSERT INTO agency_data.candidate_skill (candidate_id, skill_id, proficiency_level)
	SELECT 
	    c.candidate_id,
	    s.skill_id,
	    'Intermediate'
	FROM agency_data.candidate c, agency_data.skill s
	WHERE c.email = 'john@example.com'
	  AND s.skill_name = 'Python'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.candidate_skill (candidate_id, skill_id, proficiency_level)
	SELECT 
	    c.candidate_id,
	    s.skill_id,
	    'Advanced'
	FROM agency_data.candidate c, agency_data.skill s
	WHERE c.email = 'maria@example.de'
	  AND s.skill_name = 'Project Management'
	ON CONFLICT DO NOTHING;

--13) Table services
	INSERT INTO agency_data.services (service_name, description, price)
	VALUES
	('Resume Review', 'Professional resume review service', 50.00),
	('Interview Coaching', 'Prepare for interviews', 100.00)
	ON CONFLICT DO NOTHING;

--14) Table candidate_service
	INSERT INTO agency_data.candidate_service (candidate_id, service_id, status, purchase_date)
	SELECT 
	    c.candidate_id,
	    s.service_id,
	    'Completed',
	    '2025-11-01'
	FROM agency_data.candidate c, agency_data.services s
	WHERE c.email = 'john@example.com'
	  AND s.service_name = 'Resume Review'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.candidate_service (candidate_id, service_id, status, purchase_date)
	SELECT 
	    c.candidate_id,
	    s.service_id,
	    'Pending',
	    '2025-11-03'
	FROM agency_data.candidate c, agency_data.services s
	WHERE c.email = 'maria@example.de'
	  AND s.service_name = 'Interview Coaching'
	ON CONFLICT DO NOTHING;

--15) Table application 
	INSERT INTO agency_data.application (candidate_id, job_id, application_date, status)
	SELECT 
	    c.candidate_id,
	    j.job_id,
	    '2025-11-05',
	    'Submitted'
	FROM agency_data.candidate c, agency_data.job j
	WHERE c.email = 'john@example.com'
	  AND j.title = 'Software Engineer'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.application (candidate_id, job_id, application_date, status)
	SELECT 
	    c.candidate_id,
	    j.job_id,
	    '2025-11-06',
	    'Submitted'
	FROM agency_data.candidate c, agency_data.job j
	WHERE c.email = 'maria@example.de'
	  AND j.title = 'Project Manager'
	ON CONFLICT DO NOTHING;

--16) Table interview
	INSERT INTO agency_data.interview (application_id, interview_date, interviewer_name, result, notes)
	SELECT 
	    a.application_id,
	    '2025-11-10 10:00',
	    'Alice Smith',
	    'Pending',
	    'First round'
	FROM agency_data.application a
	JOIN agency_data.candidate c ON c.candidate_id = a.candidate_id
	WHERE c.email = 'john@example.com'
	ON CONFLICT DO NOTHING;
	
	INSERT INTO agency_data.interview (application_id, interview_date, interviewer_name, result, notes)
	SELECT 
	    a.application_id,
	    '2025-11-11 14:00',
	    'Bob Müller',
	    'Pending',
	    'First round'
	FROM agency_data.application a
	JOIN agency_data.candidate c ON c.candidate_id = a.candidate_id
	WHERE c.email = 'maria@example.de'
	ON CONFLICT DO NOTHING;

--17) Table placement
	INSERT INTO agency_data.placement (job_id, candidate_id, start_date, end_date, salary_offered)
	SELECT 
	    j.job_id,
	    c.candidate_id,
	    '2025-12-01',
	    NULL,
	    1500.00
	FROM agency_data.job j, agency_data.candidate c
	WHERE j.title = 'Software Engineer'
	  AND c.email = 'john@example.com'
	ON CONFLICT DO NOTHING;
	
	
	INSERT INTO agency_data.placement (job_id, candidate_id, start_date, end_date, salary_offered)
	SELECT 
	    j.job_id,
	    c.candidate_id,
	    '2025-12-15',
	    NULL,
	    2000.00
	FROM agency_data.job j, agency_data.candidate c
	WHERE j.title = 'Project Manager'
	  AND c.email = 'maria@example.de'
	ON CONFLICT DO NOTHING;


--Adding record_ts

--1
ALTER TABLE agency_data.country
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--2
ALTER TABLE agency_data.region
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--3
ALTER TABLE agency_data.city
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--4
ALTER TABLE agency_data.location
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--5
ALTER TABLE agency_data.industry
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--6
ALTER TABLE agency_data.employer
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--7
ALTER TABLE agency_data.job
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--8
ALTER TABLE agency_data.skill
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--9
ALTER TABLE agency_data.education_level
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--10
ALTER TABLE agency_data.candidate
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--11
ALTER TABLE agency_data.job_skill
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--12
ALTER TABLE agency_data.candidate_skill
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--13
ALTER TABLE agency_data.services
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--14
ALTER TABLE agency_data.candidate_service
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--15
ALTER TABLE agency_data.application
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--16
ALTER TABLE agency_data.interview
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--17
ALTER TABLE agency_data.placement
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;



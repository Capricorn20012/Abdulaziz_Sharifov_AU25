
--DDL Homework


--Creating Database and schema
CREATE DATABASE recruitment_agency;
CREATE SCHEMA IF NOT EXISTS agency_data;


--Creating 17 tables


--1) Table country
CREATE TABLE IF NOT EXISTS agency_data.country (
    country_id INT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL unique);
   
    
--2) Table region   
CREATE TABLE IF NOT EXISTS agency_data.region (
    region_id INT PRIMARY KEY,
    country_id INT NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (country_id) REFERENCES agency_data.country(country_id));
    
    
--3) Table city  
CREATE TABLE IF NOT EXISTS agency_data.city (
    city_id INT PRIMARY KEY,
    region_id INT NOT NULL,
    city_name VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (region_id) REFERENCES agency_data.region(region_id));
    
    
--4) Table location      
CREATE TABLE IF NOT EXISTS agency_data.location (
    location_id INT PRIMARY KEY,
    city_id INT NOT NULL,
    address_line VARCHAR(255),
    FOREIGN KEY (city_id) REFERENCES agency_data.city(city_id));
    
    
--5) Table industry      
CREATE TABLE IF NOT EXISTS agency_data.industry (
    industry_id INT PRIMARY KEY,
    industry_name VARCHAR(50) NOT NULL UNIQUE
);


--6) Table employer  
CREATE TABLE IF NOT EXISTS agency_data.employer (
    employer_id INT PRIMARY KEY,
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
    job_id INT PRIMARY KEY,
    employer_id INT NOT NULL,
    location_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    salary_min DECIMAL(10,2) CHECK (salary_min >= 0),
    salary_max DECIMAL(10,2) CHECK (salary_max >= 0),
    posted_date DATE NOT NULL CHECK (posted_date > '2000-01-01'),
    status VARCHAR(20),
    FOREIGN KEY (employer_id) REFERENCES agency_data.employer(employer_id),
    FOREIGN KEY (location_id) REFERENCES agency_data.location(location_id)
);


--8) Table skill
CREATE TABLE IF NOT EXISTS agency_data.skill (
    skill_id INT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL
);


--9) Table education_level
CREATE TABLE IF NOT EXISTS agency_data.education_level (
    education_level_id INT PRIMARY KEY,
    education_level VARCHAR(50) NOT NULL UNIQUE
);


--10) Table candidate
CREATE TABLE IF NOT EXISTS agency_data.candidate (
    candidate_id INT PRIMARY KEY,
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
CREATE TABLE IF NOT EXISTS agency_data.job_skill (
    id SERIAL PRIMARY KEY, 
    job_id INT NOT NULL,
    skill_id INT NOT NULL,
    required_level VARCHAR(20) NOT NULL,
    UNIQUE(job_id, skill_id),  
    FOREIGN KEY (job_id) REFERENCES agency_data.job(job_id),
    FOREIGN KEY (skill_id) REFERENCES agency_data.skill(skill_id)
);


--12) Table candidate_skill
CREATE TABLE IF NOT EXISTS agency_data.candidate_skill (
    id SERIAL PRIMARY KEY,  
    candidate_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level VARCHAR(20) NOT NULL,
    UNIQUE(candidate_id, skill_id),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (skill_id) REFERENCES agency_data.skill(skill_id)
);


--13) Table services
CREATE TABLE IF NOT EXISTS agency_data.services (
    service_id INT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0)
);


--14) Table candidate_service
CREATE TABLE IF NOT EXISTS agency_data.candidate_service (
    id SERIAL PRIMARY KEY,
    candidate_id INT NOT NULL,
    service_id INT NOT NULL,
    status VARCHAR(20),
    purchase_date DATE NOT NULL CHECK (purchase_date > '2000-01-01'),
    UNIQUE(candidate_id, service_id),  
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (service_id) REFERENCES agency_data.services(service_id)
);


--15) Table application 
CREATE TABLE IF NOT EXISTS agency_data.application (
    application_id INT PRIMARY KEY,
    candidate_id INT NOT NULL,
    job_id INT NOT NULL,
    application_date DATE NOT NULL CHECK (application_date > '2000-01-01'),
    status VARCHAR(20),
    FOREIGN KEY (candidate_id) REFERENCES agency_data.candidate(candidate_id),
    FOREIGN KEY (job_id) REFERENCES agency_data.job(job_id)
);


--16) Table interview
CREATE TABLE IF NOT EXISTS agency_data.interview (
    interview_id INT PRIMARY KEY,
    application_id INT NOT NULL,
    interview_date TIMESTAMP NOT NULL CHECK (interview_date > '2000-01-01'),
    interviewer_name VARCHAR(100),
    result VARCHAR(20),
    notes TEXT,
    FOREIGN KEY (application_id) REFERENCES agency_data.application(application_id)
);


--17) Table placement
CREATE TABLE IF NOT EXISTS agency_data.placement (
    placement_id INT PRIMARY KEY,
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
	INSERT INTO agency_data.country (country_id, country_name)
	VALUES
	(1, 'Uzbekistan'),
	(2, 'Germany')
	ON CONFLICT (country_id) DO NOTHING;

--2) Table region  
	INSERT INTO agency_data.region (region_id, country_id, region_name)
	VALUES
	(1, 1, 'Tashkent Region'),
	(2, 2, 'Bavaria')
	ON CONFLICT (region_id) DO NOTHING;

--3) Table city  
	INSERT INTO agency_data.city (city_id, region_id, city_name)
	VALUES
	(1, 1, 'Tashkent'),
	(2, 2, 'Munich')
	ON CONFLICT (city_id) DO NOTHING;

--4) Table location 
	INSERT INTO agency_data.location (location_id, city_id, address_line)
	VALUES
	(1, 1, 'Chilanzar 15'),
	(2, 2, 'Marienplatz 1')
	ON CONFLICT (location_id) DO NOTHING;

--5) Table industry
	INSERT INTO agency_data.industry (industry_id, industry_name)
	VALUES
	(1, 'IT'),
	(2, 'Construction')
	ON CONFLICT (industry_id) DO NOTHING;

--6) Table employer 
	INSERT INTO agency_data.employer (employer_id, industry_id, location_id, company_name, contact_name, contact_email, contact_phone)
	VALUES
	(1, 1, 1, 'Tech Solutions', 'Kim Alex', 'alice@tech.com', '+998901234567'),
	(2, 2, 2, 'BuildCorp', 'Bob Müller', 'bob@build.com', '+498912345678')
	ON CONFLICT (employer_id) DO NOTHING;

--7) Table job
	INSERT INTO agency_data.job (job_id, employer_id, location_id, title, description, salary_min, salary_max, posted_date, status)
	VALUES
	(1, 1, 1, 'Software Engineer', 'Develop software applications', 1000.00, 2000.00, '2025-01-01', 'Open'),
	(2, 2, 2, 'Project Manager', 'Manage construction projects', 1500.00, 2500.00, '2025-01-05', 'Open')
	ON CONFLICT (job_id) DO NOTHING;

--8) Table skill
	INSERT INTO agency_data.skill (skill_id, skill_name, category)
	VALUES
	(1, 'Python', 'Programming'),
	(2, 'Project Management', 'Management')
	ON CONFLICT (skill_id) DO NOTHING;

--9) Table education_level
	INSERT INTO agency_data.education_level (education_level_id, education_level)
	VALUES
	(1, 'Bachelor'),
	(2, 'Master')
	ON CONFLICT (education_level_id) DO NOTHING;

--10) Table candidate
	INSERT INTO agency_data.candidate (candidate_id, education_level_id, location_id, first_name, last_name, email, phone, experience_years)
	VALUES
	(1, 1, 1, 'Abdulaziz', 'Sharifov', 'john@example.com', '+998901112233', 3),
	(2, 2, 2, 'Maria', 'Schmidt', 'maria@example.de', '+498912223344', 5)
	ON CONFLICT (candidate_id) DO NOTHING;

--11) Table job_skill
	INSERT INTO agency_data.job_skill (job_id, skill_id, required_level)
	VALUES
	(1, 1, 'Advanced'),
	(2, 2, 'Intermediate')
	ON CONFLICT (job_id, skill_id) DO NOTHING;

--12) Table candidate_skill
	INSERT INTO agency_data.candidate_skill (candidate_id, skill_id, proficiency_level)
	VALUES
	(1, 1, 'Intermediate'),
	(2, 2, 'Advanced')
	ON CONFLICT (candidate_id, skill_id) DO NOTHING;

--13) Table services
	INSERT INTO agency_data.services (service_id, service_name, description, price)
	VALUES
	(1, 'Resume Review', 'Professional resume review service', 50.00),
	(2, 'Interview Coaching', 'Prepare for interviews', 100.00)
	ON CONFLICT (service_id) DO NOTHING;

--14) Table candidate_service
	INSERT INTO agency_data.candidate_service (candidate_id, service_id, status, purchase_date)
	VALUES
	(1, 1, 'Completed', '2025-11-01'),
	(2, 2, 'Pending', '2025-11-03')
	ON CONFLICT (candidate_id, service_id) DO NOTHING;

--15) Table application 
	INSERT INTO agency_data.application (application_id, candidate_id, job_id, application_date, status)
	VALUES
	(1, 1, 1, '2025-11-05', 'Submitted'),
	(2, 2, 2, '2025-11-06', 'Submitted')
	ON CONFLICT (application_id) DO NOTHING;

--16) Table interview
	INSERT INTO agency_data.interview (interview_id, application_id, interview_date, interviewer_name, result, notes)
	VALUES
	(1, 1, '2025-11-10 10:00', 'Alice Smith', 'Pending', 'First round'),
	(2, 2, '2025-11-11 14:00', 'Bob Müller', 'Pending', 'First round')
	ON CONFLICT (interview_id) DO NOTHING;

--17) Table placement
	INSERT INTO agency_data.placement (placement_id, job_id, candidate_id, start_date, end_date, salary_offered)
	VALUES
	(1, 1, 1, '2025-12-01', NULL, 1500.00),
	(2, 2, 2, '2025-12-15', NULL, 2000.00)
	ON CONFLICT (placement_id) DO NOTHING;


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



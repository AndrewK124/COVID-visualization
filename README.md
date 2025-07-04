# COVID-19 Data Exploration and Visualization Project 

This project analyzes global COVID data from January 2020 to March 2025 to discover insights on vaccination rollouts, mortality rates, and policy effectiveness across countries and continents using Excel, SQL, and Tableau

The questions at hand are as follows: 
1. What's the relationship between vaccination rates and COVID-19 mortality rates across countries? 
2. How did the COVID-19 reproduction rate change before and after mass rollouts in different countries? 
3. Which continents achieved the fastest vaccination rollout relative to their peak daily new cases? 
4. Which countries had the most effective response measures?
--- 
## Key Findings: 
- Countries with higher vaccination rates generally experienced lower deaths per million after achieving >=50% vaccination coverage.
- Average COVID reproduction rates decreased overall after mass rollouts in most countries.
- Asia achieved 50% vaccination coverage well before its peak cases, suggesting a proactice vaccine rollout.
- Countries with stricter stringency measures saw varied effectiveness in reducing new cases post-policy implementation
---
## Dashboard: 
![Dashboard](https://github.com/user-attachments/assets/f0f4bfc9-8dc4-4f03-9a0a-75a72fb95b6d)

---
## Data Source and Preparation:
I gathered the data by going to [OurWorldInData's datasets](https://docs.owid.io/projects/etl/api/covid/#download-data) and downloading their "Cases and Deaths" and "Vaccinations" datasets. After downloading the .csv files, I transformed them into Excel files, cleaned them a little bit by removing extraneous columns, then imported them into SSMS. 

Date Range: January 2020 – March 2025

Scope: 200+ countries and territories
---
## Tools Used:
- Microsoft Excel: Data cleaning, .csv to .xlsx transformation, and SQL to Tableau importing
- Microsoft SQL Server Management Studio (SSMS): Data exploration and analytical querying
- Tableau Public: Visualizing SQL queries
---
## SQL Queries and Result-sets: 
Query #1 Purpose: This query answers the question: "What's the relationship between vaccination rates and COVID-19 mortality rates across countries?". It analyzes the relationship between each's country's vaccination coverage (>=50%) and their post-vaccination COVID mortality rates to assess real-world vaccine impact. 
```
-- Calculating post-vaccination death metrics for countries with >=50% vaccination coverage 
WITH vax_coverage_date AS (
	-- Get the date when each country first reached 50% vaccination coverage 
	SELECT 
		country, 
		MIN(date) AS date_50pct
	FROM CovidVaccinations
	WHERE TRY_CAST(people_vaccinated_per_hundred AS float) >= 50 
	GROUP BY country 
), 
post_vax_deaths AS (
	-- Calculate total deaths, number of days, and population after reaching 50% vaccination coverage 
	SELECT d.country, 
		   SUM(d.new_deaths) AS total_deaths_post_vax_coverage, -- Total deaths after reaching 50% vaccination coverage 
		   COUNT(DISTINCT d.date) AS num_days_post_vax_coverage, -- Number of days after reaching 50% vaccination coverage 
		   MAX(d.population) AS population -- Maximum recorded population for scaling per million
	FROM CovidDeaths d 
	JOIN vax_coverage_date v ON d.country = v.country 
	WHERE d.date >= v.date_50pct -- Only consider the deaths on or after 50% vaccination coverage has been achieved 
	GROUP BY d.country 
), 
latest_vax AS ( 
	-- Get the most recent vaccination record date for each country
	SELECT country, 
		   MAX(date) AS latest_date 
	FROM CovidVaccinations
	WHERE people_fully_vaccinated_per_hundred IS NOT NULL
	GROUP BY country 
) 
SELECT 
	v.country, 
	lv.latest_date, -- Most recent vaccination date 
	v.people_fully_vaccinated_per_hundred, -- Percent of people fully vaccinated 
	p.total_deaths_post_vax_coverage, -- Total deaths after 50% vaccination threshold
	p.num_days_post_vax_coverage, -- Number of days after 50% vaccination threshold
	(p.total_deaths_post_vax_coverage * 1.0 / p.num_days_post_vax_coverage) AS avg_daily_deaths_post_vax_coverage, -- Average daily deaths post 50% vaccination coverage
	CASE 
		WHEN p.population IS NOT NULL AND p.population > 0 
		THEN (p.total_deaths_post_vax_coverage * 1.0 / p.population) * 1000000 -- Deaths per million post 50% vaccination coverage
		ELSE NULL
	END AS deaths_per_million_post_vax_coverage
FROM latest_vax lv
JOIN CovidVaccinations v ON lv.country = v.country 
	 AND lv.latest_date = v.date -- This makes sure the most recent vaccination data is pulled 
JOIN post_vax_deaths p ON v.country = p.country 
WHERE v.continent IS NOT NULL -- Exclude aggregate rows or non-country records
ORDER BY v.people_fully_vaccinated_per_hundred DESC; 
```
Result-set: 

![Query1](https://github.com/user-attachments/assets/5e80fcfc-4788-4013-b939-be4741e67a88)

---
Query #2 Purpose: This query answers the question: "How did the COVID-19 reproduction rate change before and after mass rollouts in different countries?". It evaluates the impact of mass vaccination rollouts on the COVID reproduction rate (transmission rate). This query calculates the average reproduction rate 30 days before and after each country reached 50% vaccination coverage, enabling comparison of transmission trends and pre and post vaccination rollout. 
```
-- Finding the earliest date when each country reached at least 50% vaccination coverage 
WITH rollout_dates AS ( 
	SELECT country, 
		   MIN(date) AS rollout_date 
	FROM CovidVaccinations
	WHERE TRY_CAST(people_vaccinated_per_hundred AS float) >= 50 -- 50% vaccination coverage
	GROUP BY Country
), 
-- Calculate the average COVID reproduction rate 30 days before and 30 days after the rollout date
pre_post_reproduction AS ( 
	SELECT 
		d.country, 
		r.rollout_date, 
		-- Average reproduction rate 30 days before the rollout date
		AVG(CASE 
			WHEN d.date < r.rollout_date 
			AND d.date >= DATEADD(day, -30, r.rollout_date) 
			THEN TRY_CAST(d.reproduction_rate AS float) END) AS avg_COVID_reproduction_pre_rollout,  
		-- Average reproduction rate 30 days after the rollout date
		AVG(CASE 
			WHEN d.date >= r.rollout_date 
			AND d.date < DATEADD(day, 30, r.rollout_date) 
			THEN TRY_CAST(d.reproduction_rate AS float) END) AS avg_COVID_reproduction_post_rollout
	FROM CovidDeaths d 
	JOIN rollout_dates r ON d.country = r.country 
	WHERE d.reproduction_rate IS NOT NULL -- Filter out missing values 
	GROUP BY d.country, r.rollout_date 
) 
SELECT *, (avg_COVID_reproduction_post_rollout - avg_COVID_reproduction_pre_rollout) / avg_COVID_reproduction_pre_rollout * 100 AS reproduction_percent_change 
FROM pre_post_reproduction
ORDER BY reproduction_percent_change ASC; 
```
Result-set: 

![Query2](https://github.com/user-attachments/assets/d9c90189-d3c7-45e0-9043-fb067416eb52)

---
Query #3 Purpose: This query answers the question: "Which continents achieved the fastest vaccination rollout relative to their peak daily new cases?". It evaluates how proactive each continent was in vaccinating their populations relative to their peak daily COVID cases. This query identifies whether continents reached 50% vaccination coverage before, after, or on the same day as their peak infection date, offering insights into rollout responsiveness. 
```
-- Calculating the timing between 50% vaccination coverage and peak daily new COVID cases

-- Finding the peak number of daily new cases per continent 
WITH continent_peak_cases AS ( 
	SELECT 
		continent, 
		MAX(new_cases) AS peak_cases
	FROM CovidDeaths 
	WHERE continent IS NOT NULL 
	GROUP BY continent 
), 

-- Finding the date when each continent experienced its peak daily new cases 
continent_peaks_dates AS ( 
	SELECT 
		d.continent, 
		d.date AS peak_cases_date, 
		p.peak_cases 
	FROM CovidDeaths d 
	JOIN continent_peak_cases p ON d.continent = p.continent AND d.new_cases = p.peak_cases 
	WHERE ISDATE(d.date) = 1
), 
continent_vax_coverage_50pct AS ( 
	SELECT 
		v.continent, 
		MIN(CAST(v.date AS date)) AS vax_coverage_50pct_date
	FROM CovidVaccinations v 
	WHERE 
		TRY_CAST(v.people_vaccinated_per_hundred AS float) >= 50 -- 50% of population vaccinated
		AND v.continent IS NOT NULL 
		AND ISDATE(v.date) = 1 
	GROUP BY v.continent 
) 
SELECT  
	p.continent, 
	p.peak_cases_date, 
	v.vax_coverage_50pct_date, 
	DATEDIFF(day, v.vax_coverage_50pct_date, p.peak_cases_date) AS days_difference, 
	CASE
		WHEN DATEDIFF(day, v.vax_coverage_50pct_date, p.peak_cases_date) > 0 THEN '50% of population vaxxed before peak COVID cases'
		WHEN DATEDIFF(day, v.vax_coverage_50pct_date, p.peak_cases_date) < 0 THEN '50% of population vaxxed after peak COVID cases'
		ELSE '50% of population vaxxed same day as peak COVID cases' 
	END AS peak_occurence
FROM continent_peaks_dates p 
JOIN continent_vax_coverage_50pct v ON p.continent = v.continent 
ORDER BY days_difference ASC;
```
Result-set: 

![Query3](https://github.com/user-attachments/assets/2b2cb9a5-ba9d-41eb-b123-6b8b75df8b6b)

---
Query #4 Purpose: This query answers the question: "Which countries had the most effective response measures?". It determines which countries' policy responses were most effective in reducing COVID cases. This query analyzes the percent change in average new cases per million before and after each country's peak stringency index date, highlighting the real-world impact of strcier measures on infection rates. 
```
-- Calculating percent change in new cases per million before and after peak stringency index per country
WITH peak_stringency AS ( 
	SELECT 
		country, 
		date, 
		stringency_index, 
		ROW_NUMBER() OVER (PARTITION BY country ORDER BY stringency_index DESC, date ASC) as rn 
	FROM CovidDeaths 
	WHERE stringency_index IS NOT NULL 
), 
country_peaks AS ( 
	SELECT 
		country, 
		date AS peak_cases_date, 
		stringency_index 
	FROM peak_stringency 
	WHERE rn = 1
), 
-- Calculating average new cases per million, 14 days before and after the peak stringency 
before_after_cases AS ( 
	SELECT 
		c.country, 
		p.peak_cases_date, 
		AVG(CASE WHEN c.date BETWEEN DATEADD(day, -14, p.peak_cases_date) AND DATEADD(day, -1, p.peak_cases_date) THEN c.new_cases_per_million END) as avg_cases_before_peak, 
		AVG(CASE WHEN c.date BETWEEN p.peak_cases_date AND DATEADD(day, 14, p.peak_cases_date) THEN c.new_cases_per_million END) AS avg_cases_after_peak
	FROM CovidDeaths c 
	JOIN country_peaks p ON c.country = p.country 
	WHERE c.new_cases_per_million IS NOT NULL 
	GROUP BY c.country, p.peak_cases_date
) 
-- Calculating % change 
SELECT 
	b.country, 
	s.stringency_index, 
	b.peak_cases_date, 
	b.avg_cases_before_peak, 
	b.avg_cases_after_peak, 
	CASE WHEN b.avg_cases_before_peak = 0 THEN NULL ELSE ((b.avg_cases_after_peak - b.avg_cases_before_peak) / b.avg_cases_before_peak) * 100 END AS cases_percent_change 
FROM before_after_cases b
JOIN country_peaks s ON b.country = s.country 
ORDER BY cases_percent_change; 
```
Result-set: 

![Query4](https://github.com/user-attachments/assets/c8a68d52-f0e7-4873-b1f5-8619ca7d2be1)

---
## Dashboard Link

Tableau Public: https://public.tableau.com/app/profile/andrew.key3510/viz/CovidViz_17514850600140/Dashboard1
---
## Side Note:

This project was originally a guided project created by [Alex The Analyst](https://www.youtube.com/watch?v=qfyynHBFOsM&list=PLUaB-1hjhk8H48Pj32z4GZgGWyylqv85f&index=2) (thank you, Alex!). I completely overhauled it, incorporating more realistic and exploratory analyses, and creating original visualization to reflect real-world Data Analyst projects. 

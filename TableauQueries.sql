----- Query 1: Retrieves the global number of cases, deaths, and the case fatality rate -----
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM PortfolioProject2..CovidDeaths 
WHERE continent IS NOT NULL 
ORDER BY 1,2;

----- Query 2: Retrieves the number of deaths per continent -----
SELECT 
	country, 
	SUM(CAST(new_deaths AS int)) AS total_death_count 
FROM PortfolioProject2..CovidDeaths  
WHERE continent IS NULL AND country IN ('Europe', 'North America', 'South America', 'Asia', 'Oceania', 'Africa' ) 
GROUP BY country 
ORDER BY total_death_count DESC;

----- Query 3: Retrieves the countries with the highest infection rate -----
SELECT 
	country, 
	population, 
	MAX(total_cases) AS highest_infection_count, 
	MAX(total_cases/population)*100 AS percent_population_infected
FROM PortfolioProject2..CovidDeaths 
WHERE 
	population IS NOT NULL 
	AND 
	total_cases IS NOT NULL 
GROUP BY country, population 
ORDER BY percent_population_infected DESC; 

----- Query 4: Retrieves the countries with the highest number of cases in a country on a given date and the percentage of the population that was infected ----- 
SELECT 
	country, 
	population, 
	date, 
	MAX(total_cases) AS highest_infection_count, 
	(MAX(total_cases) / population) * 100 AS percent_population_infected
FROM PortfolioProject2..CovidDeaths
WHERE 
	population IS NOT NULL 
	AND 
	total_cases IS NOT NULL 
GROUP BY country, population, date 
ORDER BY percent_population_infected DESC;
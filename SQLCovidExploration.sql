----- Take a look at the Data -----
SELECT * 
FROM PortfolioProject2..CovidDeaths
WHERE continent IS NOT NULL -- Removes groupings by continent
ORDER BY 3,4

----- Select Data that we're going to be using -----
SELECT country, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject2..CovidDeaths
WHERE continent IS NOT NULL -- Removes groupings by continent
ORDER BY 1,2 -- Order by country and date

----- Looking at Total Cases vs. Total Deaths -----
-- Shows probability of passing away if you contract Covid in your country --
SELECT country, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject2..CovidDeaths
WHERE continent IS NOT NULL AND total_cases <> 0 -- Removes groupings by continent and removes instances where there are no cases
ORDER BY 1,2

----- Looking at Total Cases vs. Population --
-- Shows what percentage of the population that contracted Covid --
SELECT country, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
FROM PortfolioProject2..CovidDeaths
WHERE continent IS NOT NULL AND total_cases <> 0 -- Removes groupings by continent and removes instances where there are no cases
ORDER BY 1,2

----- Looking at countries with the Highest Infection Rate compared to the Population -----
SELECT country, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject2..CovidDeaths
WHERE continent IS NOT NULL -- Removes groupings by continent
GROUP BY country, population
ORDER BY percent_population_infected DESC 

----- Showing the countries with the highest death count per population -----
SELECT country, MAX(cast(total_deaths AS int)) as total_death_count 
FROM PortfolioProject2..CovidDeaths 
WHERE continent IS NOT NULL -- Removes groupings by continent
GROUP BY country 
ORDER BY total_death_count DESC

------- Let's break things down by continent -------

----- Showing continents with the highest death count per population -----
SELECT continent, MAX(cast(total_deaths AS int)) AS total_death_count 
FROM PortfolioProject2..CovidDeaths 
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY total_death_count DESC 


----- Showing the global daily number of cases and deaths along with the death percentage for that day -----
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject2..CovidDeaths 
WHERE continent IS NOT NULL AND new_cases <> 0 -- Removes groupings by continent and removes instances where there are no cases
GROUP BY date 
ORDER BY 1,2

----- Looking at total population vs. vaccinations -----
----- Shows the total amount of people globally that have been vaccinated -----
SELECT dea.continent, dea.country, dea.date, dea.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.country ORDER BY dea.country, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject2..CovidDeaths dea
JOIN PortfolioProject2..CovidVaccinations vacc ON dea.country = vacc.country AND dea.date = vacc.date 
WHERE dea.continent IS NOT NULL AND TRY_CAST(vacc.new_vaccinations AS BIGINT) IS NOT NULL
ORDER BY 2,3

----- Using a CTE to gather the percentage of global new vaccinations ----- 
WITH PopvsVac (continent, country, date, population, new_vaccinations, rolling_people_vaccinated) 
AS 
(
SELECT dea.continent, dea.country, dea.date, dea.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.country ORDER BY dea.country, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject2..CovidDeaths dea
JOIN PortfolioProject2..CovidVaccinations vacc ON dea.country = vacc.country AND dea.date = vacc.date 
WHERE dea.continent IS NOT NULL AND TRY_CAST(vacc.new_vaccinations AS BIGINT) IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (CAST(rolling_people_vaccinated AS FLOAT) / population) * 100 AS vaccination_percentage
FROM PopVsVac

-- TEMP TABLE -- 
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
( 
continent nvarchar(255), 
country nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
people_vaccinated_rolling numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.country, dea.date, dea.population, vacc.new_vaccinations, 
SUM(CAST(vacc.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject2..CovidDeaths dea
JOIN PortfolioProject2..CovidVaccinations vacc ON dea.country = vacc.country AND dea.date = vacc.date 
WHERE dea.continent IS NOT NULL 

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for future visualizations -- 
-- CREATE VIEW PercentPopulationVaccinated AS 
-- SELECT dea.continent, dea.country, dea.date, dea.population, vacc.new_vaccinations, 
-- SUM(CAST(vacc.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
-- FROM PortfolioProject2..CovidDeaths dea 
-- JOIN PortfolioProject2..CovidVaccinations vacc on dea.country = vacc.country AND dea.date = vacc.date 
-- WHERE dea.continent IS NOT NULL 
-- Select columns that will be mostly used
SELECT continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths
FROM PortProject1.dbo.CovidDeaths$


-- Viewing total cases versus total deaths 
-- Shows chance of death if contracted by Covid (Daily chance according to country)
-- Viewing population versus total cases
-- Shows what percentage of people are infected
SELECT location, date,
ROUND((total_deaths/total_cases) * 100, 2) AS death_percentage,
ROUND((total_cases/population) * 100, 2) AS infection_percentage
FROM PortProject1.dbo.CovidDeaths$
ORDER BY location, date


-- Viewing total cases versus total deaths for specific country
SELECT location, date,
ROUND((total_deaths/total_cases) * 100, 2) AS death_percentage,
ROUND((total_cases/population) * 100, 2) AS infection_percentage
FROM PortProject1.dbo.CovidDeaths$ 
WHERE location = 'Nepal'
ORDER BY location, date


-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS highest_infection_cases, 
ROUND(MAX(total_cases/population) * 100, 2) AS highest_infection_rate
FROM PortProject1.dbo.CovidDeaths$
GROUP BY location, population
ORDER BY highest_infection_rate DESC


-- Showing contintents with the highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_deaths_by_continent
FROM PortProject1.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths_by_continent DESC


-- GLOBAL NUMBERS
-- Shows total cases, total deaths, total death percentage
SELECT date, SUM(new_cases) AS global_cases, SUM(CAST(new_deaths AS INT)) AS global_deaths, 
ROUND(SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100, 2) AS global_death_percentage
FROM PortProject1.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Shows what Percentage of Population that has recieved at least one Covid Vaccine

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccinations
FROM PortProject1.dbo.CovidVaccinations$ AS vac
JOIN PortProject1.dbo.CovidDeaths$ AS death
	ON vac.location = death.location AND vac.date = death.date
	WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date


-- Using CTE to perform Calculation on Partition By in previous query

WITH totalPopvsVac (Continent, Location, Date, Population,
New_Vaccinations, cumulative_vaccinations)
AS (
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccinations
FROM PortProject1.dbo.CovidVaccinations$ AS vac
JOIN PortProject1.dbo.CovidDeaths$ AS death
	ON vac.location = death.location AND vac.date = death.date
	WHERE death.continent IS NOT NULL
)
SELECT Location, Date,
ROUND((cumulative_vaccinations/Population) * 100, 2) AS cumu_percentage FROM totalPopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #temp_table
	CREATE TABLE #temp_table (
	Continent varchar(255),
	Location varchar(255),
	Date datetime,
	Population NUMERIC,
	new_vaccination NUMERIC,
	cumulative_vaccination NUMERIC
)
INSERT INTO #temp_table
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccinations
FROM PortProject1.dbo.CovidVaccinations$ AS vac
JOIN PortProject1.dbo.CovidDeaths$ AS death
	ON vac.location = death.location AND vac.date = death.date
	WHERE death.continent IS NOT NULL

SELECT ROUND((cumulative_vaccination/population) * 100, 2) AS vaccinated_percentage
FROM #temp_table

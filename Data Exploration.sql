--SELECT *
--FROM CovidDeaths
--ORDER BY 3, 4

--SELECT *
--FROM CovidVacications
--ORDER BY 3, 4

-- Select the data that we are going to be working with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY location, date

-- Show the death percentages of those who got covid and those who actually died from it.
-- Looking at the Total Cases VS Total Deaths
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100  AS DeathPercentage
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY location, date

-- Show the percentage of the population that got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationInfectedPercentage
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY location, date

-- What countries have the highest infection rates compared to population?
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PopulationInfectedPercentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC

-- What countries have the highest death count per population
SELECT location, population, MAX(CAST(total_cases AS int)) AS TotalDeath
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeath DESC

-- What continents have the highest death count per population
SELECT continent, MAX(CAST(total_cases AS int)) AS TotalDeath
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeath DESC

-- Looking at total vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVacRollingCount
FROM CovidDeaths AS dea
JOIN CovidVacications AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location, date

-- Looking at total population VS vaccinations
-- With CTEs
WITH PopvsVac (continent, location, date, population, new_vaccinations, NewVacRollingCount)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVacRollingCount
FROM CovidDeaths AS dea
JOIN CovidVacications AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (NewVacRollingCount/population)*100 AS PercentageRollingPopulationVaccinated
FROM PopvsVac

-- With Temp Table
DROP TABLE IF EXISTS #PercentageRollingPopulationVaccinated
CREATE TABLE #PercentageRollingPopulationVaccinated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	NewVacRollingCount numeric
)

INSERT INTO #PercentageRollingPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVacRollingCount
FROM CovidDeaths AS dea
JOIN CovidVacications AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location, date

SELECT *, (NewVacRollingCount/population)*100 AS PercentageRollingPopulationVaccinated
FROM #PercentageRollingPopulationVaccinated

-- Creating Views for later Visualization
CREATE VIEW PercentageRollingPopulationVaccinated 
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVacRollingCount
FROM CovidDeaths AS dea
JOIN CovidVacications AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT * FROM PercentageRollingPopulationVaccinated
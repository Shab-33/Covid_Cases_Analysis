/*
    COVID-19 Data Exploration 

    Skills Demonstrated:
    - Joins
    - Common Table Expressions (CTEs)
    - Temporary Tables
    - Window Functions
    - Aggregate Functions
    - Creating Views
    - Data Type Conversion
*/

/* ====================================
   Initial Data Overview
==================================== */
-- Querying all data from the CovidDeaths table
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY continent, location;

/* ====================================
   Data Selection
==================================== */
-- Selecting relevant columns to start exploration
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

/* ====================================
   Total Cases vs Total Deaths
==================================== */
-- Analyzing the likelihood of death after contracting COVID-19
SELECT location, date, total_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, date;

/* ====================================
   Total Cases vs Population
==================================== */
-- Calculating the percentage of the population infected with COVID-19
SELECT location, date, population, total_cases,
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;

/* ====================================
   Countries with the Highest Infection Rates
==================================== */
-- Identifying countries with the highest infection rates compared to their population
SELECT location, population,
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

/* ====================================
   Countries with the Highest Death Count
==================================== */
-- Identifying countries with the highest total death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

/* ====================================
   Death Count by Continent
==================================== */
-- Showing continents with the highest death counts
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

/* ====================================
   Global Numbers
==================================== */
-- Calculating global totals for cases, deaths, and death percentage
SELECT SUM(new_cases) AS TotalCases,
       SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

/* ====================================
   Total Population vs Vaccinations
==================================== */
-- Analyzing the percentage of the population vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

/* ====================================
   Using CTE for Partitioned Calculation
==================================== */
-- Using a CTE to calculate rolling vaccinations per population
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PopvsVac;

/* ====================================
   Using Temp Table for Partitioned Calculation
==================================== */
-- Dropping the temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

-- Creating a temporary table
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Inserting data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date;

-- Querying the temporary table
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated;

/* ====================================
   Creating a View
==================================== */
-- Creating a view to store vaccination data for visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

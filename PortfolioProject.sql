SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

--Select data to be used
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--Show total_deaths vs total_cases -> likelihood of death in a country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --continent is NULL when location column is already the continent's name
ORDER BY 1, 2

--Show total_cases vs population -> percentage of population infected with Covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS CovidInfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Show countries with highest infection rate per population
SELECT location, population, MAX(total_cases) AS HighestInfection, MAX((total_cases/population)) * 100 AS CovidInfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY CovidInfectedPercentage DESC

--Show countries with highest death count per population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Show continents with highest death count 
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS -> daily numbers
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Join Tables

--Show running sum vaccination per population by day
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSumVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Show percentage of vaccination per population -> alias column ("RollingSumVaccination") needed in SELECT
--Use CTE
WITH PopVaccine (continent, location, date, population, new_vaccinations, RollingSumVaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSumVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT *, (RollingSumVaccination/population) * 100 AS PercentageVaccination
FROM PopVaccine

--Show highest percentage of vaccination per population by country -> total_vaccinations possibly record multiple doses
WITH VaccinePercent (continent, location, population, TotalVaccine)
AS
(
SELECT dea.continent, dea.location, dea.population, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location) AS TotalVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT *, (TotalVaccine/population) * 100 AS VacPercentage
FROM VaccinePercent
WHERE TotalVaccine IS NOT NULL
ORDER BY VacPercentage DESC

--Use Temp Table
DROP TABLE IF EXISTS #VaccinatedPopulationPercent
CREATE TABLE #VaccinatedPopulationPercent
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations float,
rolling_sum_vaccination float
)

INSERT INTO #VaccinatedPopulationPercent
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSumVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_sum_vaccination/population) * 100
FROM #VaccinatedPopulationPercent

--Create view to store data for visualizations
USE PortfolioProject
GO
CREATE VIEW VaccinatedPopulationPercent AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSumVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM VaccinatedPopulationPercent
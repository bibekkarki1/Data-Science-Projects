/* Covid-19 Data Exploration
Data from: January 1, 2020 to December 19, 2021
*/ 

## Select data that will be used

SELECT Location, date, population, total_cases, new_cases, total_deaths
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

## Percent of the US population infected

SELECT Location, date, population, total_cases, ROUND((((total_cases/population)*100)), 3) AS PercentOfPopulationInfected
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL AND Location = 'United States' 
ORDER BY 1,2;

## Liklihood of death among the infected in the US

SELECT Location, date, total_cases, total_deaths, ROUND((((total_deaths/total_cases)*100)), 2) AS DeathRate_Percentage
FROM CovidProject.CovidDeaths
WHERE Location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2;

## Countries with the highest infection rate relative to population

SELECT Location,population, MAX(total_cases) AS MaximumInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location,population
ORDER BY PercentPopulationInfected desc;

## Top 10 Countries with highest death count
Select Location, MAX(CAST(Total_deaths AS INT64)) AS TotalDeathCount
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC
LIMIT 10;

## Highest Death Count by Continent
Select continent, MAX(CAST(Total_deaths AS INT64)) AS TotalDeathCount
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

## World Covid Statistics (as of December 19, 2021)
## Total cases, total deaths, infecction percentage and the death percentage for the world
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT64)) AS Total_Deaths, SUM(DISTINCT(population)) AS world_population,
 (SUM(new_cases)/SUM(DISTINCT(population)))*100 AS Infection_Rate, 
 SUM(CAST(new_deaths AS INT64))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

# Total Vaccinated compared to the population
SELECT cde.date, cde.continent, cde.location, cde.population, cva.new_vaccinations,
 SUM(CAST(cva.new_vaccinations AS INT64)) 
 OVER (PARTITION BY cde.location ORDER BY cde.location, cde.date) AS RollingVaccinatedCount
FROM CovidProject.CovidDeaths AS cde
JOIN CovidProject.CovidVaccinations AS cva
ON cde.location = cva.location AND cde.date = cva.date
WHERE cde.continent IS NOT NULL
ORDER BY 3,2;

#Using temp table to find percentage of people vaccinated in a country's population
CREATE TABLE IF NOT EXISTS CovidProject.PercentPopVaccinated
(
Date datetime,
Continent STRING,
Location STRING,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO CovidProject.PercentPopVaccinated
SELECT cde.date, cde.continent, cde.location, cde.population, cva.new_vaccinations,
 SUM(CAST(cva.new_vaccinations AS INT64)) 
 OVER (PARTITION BY cde.location ORDER BY cde.location, cde.date) AS RollingVaccinatedCount
FROM CovidProject.CovidDeaths AS cde
JOIN CovidProject.CovidVaccinations AS cva
ON cde.location = cva.location AND cde.date = cva.date;

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM CovidProject.PercentPopVaccinated;

## Using CTE to find percentage of people vaccinated in a country's population
WITH PerVac AS 
(
SELECT cde.date, cde.continent, cde.location, cde.population, cva.new_vaccinations,
 SUM(CAST(cva.new_vaccinations AS INT64)) 
 OVER (PARTITION BY cde.location ORDER BY cde.location, cde.date) AS RollingVaccinatedCount
FROM CovidProject.CovidDeaths AS cde
JOIN CovidProject.CovidVaccinations AS cva
ON cde.location = cva.location AND cde.date = cva.date
WHERE cde.continent IS NOT NULL
)
SELECT *, (RollingVaccinatedCount/population)*100 AS Percent_pop_Vaccinated
FROM PerVac;

## Creating virtual tables (Views)  
## Can be used to limit access to certain data or be used to store data for data visualization

CREATE VIEW CovidProject.Death_Count AS 
SELECT Location, MAX(CAST(Total_deaths AS INT64)) AS TotalDeathCount
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

CREATE VIEW CovidProject.Infection_Death_Stats
AS
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT64)) AS Total_Deaths, SUM(DISTINCT(population)) AS world_population,
 (SUM(new_cases)/SUM(DISTINCT(population)))*100 AS Infection_Rate, 
 SUM(CAST(new_deaths AS INT64))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject.CovidDeaths
WHERE continent IS NOT NULL;


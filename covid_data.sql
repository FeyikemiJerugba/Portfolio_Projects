SELECT * FROM project_1..covid_vaccinations
WHERE continent is NOT NULL
order by 3,4
-- some countries where grouped as continents, this not null statement changes that.
--SELECT * FROM project_1..CovidDeaths$
--order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM project_1..covid_deaths
WHERE continent is NOT NULL
Order by 1,2
--the numbers after the order by clause represent the columns

SELECT * FROM project_1..covid_deaths
Order by 3,4

-- looking at the total cases vs total deaths
--this shows the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM project_1..covid_deaths
where location like '%Nigeria%'
and continent is NOT NULL
Order by 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM project_1..covid_deaths
where location = 'Nigeria'
and continent is NOT NULL
Order by 1,2

--the same output

-- looking at total cases vs population now.
-- shows the percentage of the population that gets covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS percentage_population_affected
FROM project_1..covid_deaths
where location = 'Nigeria'
and continent is NOT NULL
Order by 1,2

--looking at countries with the highest infection rate compared to the population
SELECT location, population, MAX(total_cases)AS highest_infection_count, MAX((total_cases/population ))*100 AS percentage_population_affected
FROM project_1..covid_deaths
--where location = 'Nigeria'
WHERE continent is NOT NULL
GROUP BY location, population 
Order by percentage_population_affected desc

--looking at countries with the highest deaths in the population
SELECT location, population, MAX(cast(total_deaths AS int))AS total_death_count, MAX((total_deaths/population ))*100 AS percentage_population_death
FROM project_1..covid_deaths
--where location = 'Nigeria'
WHERE continent is NOT NULL
GROUP BY location, population 
Order by percentage_population_death desc

SELECT location, population, MAX(cast(total_deaths AS int))AS total_death_count
FROM project_1..covid_deaths
--where location = 'Nigeria'
WHERE continent is NOT NULL
GROUP BY location, population 
Order by total_death_count desc


--BREAKING THINGS DOWN BY CONTINENT
SELECT continent, MAX(cast(total_deaths AS int))AS total_death_count
FROM project_1..covid_deaths
--where location = 'Nigeria'
WHERE continent is NOT NULL
GROUP BY continent
Order by total_death_count desc

--SHOWING CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(population)AS continent_population, MAX(cast(total_deaths AS int))AS total_death_count, MAX((total_deaths/population ))*100 AS percentage_population_death
FROM project_1..covid_deaths
--where location = 'Nigeria'
WHERE continent is NOT NULL
GROUP BY continent
Order by percentage_population_death desc

--GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS Death_Percentage
FROM project_1..covid_deaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS Death_Percentage
FROM project_1..covid_deaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

--JOIN THE TWO TABLES
SELECT * 
FROM project_1..covid_deaths dea
JOIN project_1..covid_vaccinations vacc
ON dea.location = vacc.location
AND dea.date = vacc.date 

--LOOKING AT TOTAL POPULATION VS VACCINATIONS
--we have included a rolling sum of the new vaccinations and have partitioned it by location so it starts again for each location.
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingsum_vaccinated
FROM project_1..covid_deaths dea
JOIN project_1..covid_vaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date 
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--USE CTE
With POPvsVAC (continent, location, date, population, new_vaccinations, rollingsum_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingsum_vaccinated
FROM project_1..covid_deaths dea
JOIN project_1..covid_vaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date 
WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (rollingsum_vaccinated/population)*100 AS percentage_vaccinated
FROM POPvsVAC



--TEMP TABLE
DROP TABLE IF EXISTS #Percent_Population_vaccinated
CREATE TABLE #Percent_Population_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rollingsum_vaccinated numeric
)
INSERT INTO #Percent_Population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingsum_vaccinated
FROM project_1..covid_deaths dea
JOIN project_1..covid_vaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date 
--WHERE dea.continent is NOT NULL
--ORDER BY 2,3
SELECT *, (rollingsum_vaccinated/population)*100 AS percentage_vaccinated
FROM #Percent_Population_vaccinated


-- CREATING VIEW TO STORE DATA FOR VISUALIZATIONS
USE project_1
GO
CREATE VIEW Percent_Population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rollingsum_vaccinated
FROM project_1..covid_deaths dea
JOIN project_1..covid_vaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date 
WHERE dea.continent is NOT NULL
--ORDER BY 2,3

SELECT* FROM Percent_Population_vaccinated 


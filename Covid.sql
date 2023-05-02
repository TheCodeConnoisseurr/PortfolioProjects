-- COVID DATA EXPLORATION 
-- Skills Used: JOINS, CTE's, TEmp Tablea, Windows Functions, Aggregate Functions, Creating Views

-- Looking at all Death Data  
Select * from covid.deaths
Where continent is not null
order by 4,5;

-- Looking at all Vaccinations Data
Select *
FROM Covid.vaccinations
order by 3,4;

-- Selecting Data we are starting with 

Select location, date, total_cases, new_cases, total_deaths, population
from covid.deaths
WHERE continent !=''
order by 1,2;

-- Total cases VS  total deaths 
-- Shows the likely hood of dying if you contact covid in your country 

SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS DeathPercentage
FROM covid.deaths
WHERE continent !='' AND location = "United kingdom" 
ORDER BY 1, 2;


-- Total cases Vs Population
-- Shows what percentage of population got covid

SELECT location, date, population, total_cases, ((total_cases/population)*100) AS PercentPopulationInfected
FROM covid.deaths
WHERE continent !='' AND total_cases > 0 AND location = "United kingdom"
ORDER BY 1, 2;

-- Countries with highest infection rate compared to population 

SELECT location, population, MAX(total_cases) as HighestInfectionCount, (Max((total_cases/population))*100) as PercentPopulationInfected
FROM covid.deaths
-- WHERE continent !='' AND total_cases > 0 AND location = "United kingdom"
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) as totaldeathcount
FROM covid.deaths
-- WHERE continent !='' AND total_cases > 0 AND location = "United kingdom"
WHERE continent !=''
GROUP BY Location
ORDER BY totaldeathcount DESC;

-- DATA BY CONTINENTs 

-- Continents with the highest death count 


SELECT location, MAX(total_deaths) as totaldeathcount
FROM covid.deaths
WHERE continent =""
GROUP BY location 
ORDER BY totaldeathcount DESC;

-- Continents with the highest case Count

SELECT location, SUM(new_cases) as totalcasecount
FROM covid.deaths
WHERE continent =""
GROUP BY location 
ORDER BY totalcasecount DESC;

-- How Did Vaccinations Impact Death Rate (per 1000) 

SELECT  dea.location as Continent, 
		dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(dea.new_deaths) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingDeaths, 
        ((SUM(dea.new_deaths) OVER (Partition by dea.location Order by dea.location,dea.date) / dea.population) * 1000) as DeathRate
FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location
WHERE dea.continent = '' 
ORDER BY 1,2;

 
 
 -- DATA BY GLOBAL NUMBERS
 -- Deaths , Cases and death rate
 
SELECT location, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS DeathPercentage
FROM covid.deaths
WHERE location = "World" AND date = (SELECT MAX(date) FROM covid.deaths WHERE location = "World");

-- JOIN STATEMENT DEATH AND VAC 

SELECT * FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vacine 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location
WHERE dea.continent !=""
ORDER BY 2, 3;

-- USE CTE to perform Calculation on Partition by in previous query 

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location
WHERE dea.continent !=""
-- ORDER BY 2, 3
)
SELECT *, ((rollingPeopleVaccinated/Population)*100)
FROM PopvsVac
ORDER BY Location, Date;

-- TEMP TABLE to perform calculation on Partition in previous query 

USE covid;
DROP TABLE if exists PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated 
(
    Continent TEXT,
    Location TEXT,
    Date DATETIME,
    Population NUMERIC,
    new_vacinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);


INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location
WHERE dea.continent != ''
;

SELECT * ,((RollingPeopleVaccinated/Population)*100) AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;



-- CREATING VIEW TO STORE TO STORE DATA FOR LATER VISUALISATIONS 
-- THIS VIEW shows % of population that is vaccinated 

Create View PercentagePopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid.deaths dea
JOIN covid.vaccinations vac
ON dea.date = vac.date
AND dea.location = vac.location
WHERE dea.continent != ''
Order by 2,3;
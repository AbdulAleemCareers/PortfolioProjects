SELECT * FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

--SELECT * FROM PortfolioProject..CovidVaccinations
--ORDER By 3,4;

--Select Data that we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Compare Total Cases and Total Deaths
-- Displays the mortality rate associated with COVID-19 infection in your country.
SELECT location, date, total_cases, total_deaths, (CONVERT(decimal, total_deaths) / CONVERT(decimal, total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%canada%'
ORDER BY 1, 2;

-- Compare Total Cases and Population
SELECT location, date, population, total_cases, (CONVERT(decimal, total_cases) / CONVERT(decimal, population)) * 100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%canada%'
ORDER BY 1, 2;

-- Examining Countries with the Highest COVID-19 Infection Rate per Capita
SELECT location, population, MAX(cast(total_cases as bigint)) as HighestInfectionCount, MAX((CONVERT(decimal, total_cases) / CONVERT(decimal, population)) * 100) AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage desc;

-- Examining Countries with the Highest COVID-19 Death Rate per Capita
SELECT location, population, MAX(cast(total_deaths as bigint)) as TotalDeathCount, MAX((CONVERT(decimal, total_deaths) / CONVERT(decimal, population)) * 100) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- since the data also includes location (e.g, Asia) with NULL continent
GROUP BY location, population
ORDER BY DeathPercentage desc;

-- Display Continents with the Highest Death Count per Population
SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- since the data also includes location (e.g, Asia) with NULL continent
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths,
       CASE WHEN SUM(new_cases) = 0 THEN 0
            ELSE SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100
       END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Looking at Total Population VS Vaccinations

-- USE CTE
WITH PopVsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
as 
(
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--,(RollingPeopleVacctinated/population)*100
FROM
    PortfolioProject..CovidDeaths dea
JOIN 
	PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac


-- USE TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--,(RollingPeopleVacctinated/population)*100
FROM
    PortfolioProject..CovidDeaths dea
JOIN 
	PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated 

-- Creating View to Store Data for Later Visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--,(RollingPeopleVacctinated/population)*100
FROM
    PortfolioProject..CovidDeaths dea
JOIN 
	PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
-- ORDER BY 2,3


SELECT * FROM PercentPopulationVaccinated
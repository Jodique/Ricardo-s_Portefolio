select * from coviddeaths c
where continent <> '';

--select * from covidvaccinations c;

-- Select Data that are going we are going to be using

select location, date, total_cases, new_cases, total_deaths, population 
from coviddeaths c
where continent <> '' 
;

-- Loking at Total Cases Vs Total Deaths

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths / total_cases) * 100 AS death_percentage
FROM 
    coviddeaths c
where continent <> '' ;

-- Looking at the Total Cases vs Population

SELECT 
    location, 
    date, 
    population, 
    total_deaths, 
    (total_cases / population) * 100 AS cases_percentage
FROM 
    coviddeaths c
where continent <> '' ;

-- Looking at countries with highest infection rate compared to population

SELECT 
    location, 
    population, 
    HighestInfectionCount,
    Percent_Population_Infected
FROM (
    SELECT 
        location, 
        population, 
        MAX(total_cases) AS HighestInfectionCount,
        MAX((total_cases::float / population) * 100) AS Percent_Population_Infected
    FROM 
        coviddeaths c
    where continent <> '' 
    GROUP BY 
        location, 
        population
) subquery
WHERE
    Percent_Population_Infected IS NOT NULL
ORDER BY 
    Percent_Population_Infected DESC;

-- Showing Countries with Highest Death Count per Population

SELECT 
    location,
    TotalDeathCount
FROM (
    SELECT 
        location,
        continent,  -- Include continent in the subquery
        MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
    FROM 
        coviddeaths c
	where 
		continent <> '' 
    GROUP BY
        location,
        continent  -- Group by continent as well
) subquery
WHERE
    TotalDeathCount IS NOT NULL
ORDER BY 
    TotalDeathCount DESC;

-- Showing continents with the highest dead count per population

SELECT 
    continent,
    TotalDeathCount
FROM (
    select
        continent,  -- Include continent in the subquery
        MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
    FROM 
        coviddeaths c
	where 
		continent <> '' 
    GROUP by
        continent  -- Group by continent as well
) subquery
WHERE
    TotalDeathCount IS NOT NULL
ORDER BY 
    TotalDeathCount desc

-- Global Numbers

SELECT 
    date, 
    sum(new_cases) as total_cases, 
    sum(cast(new_deaths as int)) as total_deaths, 
    (sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as death_percentage
FROM 
    coviddeaths c
where continent <> ''
group by 
	date;

-- Looking at Total Population vs Vaccinations

SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS INT)) OVER (
        PARTITION BY cd.location 
        ORDER BY cd.date
    ) AS cumulative_vaccinations,
--    (cumulative_vaccinations/population )*100
FROM 
    coviddeaths cd
JOIN 
    covidvaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE 
    cd.continent <> ''
ORDER BY 
    cd.location,
    cd.date;

-- Use CTE (Common Table Expression) (Option 1)

WITH PopvsVac (continentt, location, date, population, cumulative_vaccinations) AS (
    SELECT 
        cd.continent, 
        cd.location, 
        cd.date, 
        cd.population,
        SUM(CAST(cv.new_vaccinations AS INT)) OVER (
            PARTITION BY cd.location 
            ORDER BY cd.date
        ) AS cumulative_vaccinations
    FROM 
        coviddeaths cd
    JOIN 
        covidvaccinations cv
        ON cd.location = cv.location
        AND cd.date = cv.date
    WHERE 
        cd.continent <> ''
)
SELECT 
	*,
	(cumulative_vaccinations/population)*100
FROM PopvsVac
ORDER BY 
    location,
    date;

-- Temp Table (Option 2)

drop table if exists PercentPopulationVaccinated

CREATE TEMP TABLE PercentPopulationVaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date TIMESTAMP,
    population NUMERIC,
    new_vaccinations NUMERIC,
    cumulative_vaccinations NUMERIC
);

INSERT INTO PercentPopulationVaccinated (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
SELECT 
    cd.continent, 
    cd.location, 
    CAST(cd.date AS TIMESTAMP) AS date, -- Explicitly cast date to TIMESTAMP
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS NUMERIC)) OVER (
        PARTITION BY cd.location 
        ORDER BY CAST(cd.date AS TIMESTAMP) -- Ensure proper ordering
    ) AS cumulative_vaccinations
FROM 
    coviddeaths cd
JOIN 
    covidvaccinations cv
    ON cd.location = cv.location
    AND CAST(cd.date AS TIMESTAMP) = CAST(cv.date AS TIMESTAMP) -- Ensure matching types
WHERE 
    cd.continent <> '';

SELECT 
    *,
    (cumulative_vaccinations / population) * 100 AS percent_population_vaccinated
FROM PercentPopulationVaccinated
ORDER BY 
    location,
    date;

-- Creating View to store data for later visualizations

create view percent_population_vaccinated as
SELECT 
    cd.continent, 
    cd.location, 
    CAST(cd.date AS TIMESTAMP) AS date, -- Explicitly cast date to TIMESTAMP
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS NUMERIC)) OVER (
        PARTITION BY cd.location 
        ORDER BY CAST(cd.date AS TIMESTAMP) -- Ensure proper ordering
    ) AS cumulative_vaccinations
FROM 
    coviddeaths cd
JOIN 
    covidvaccinations cv
    ON cd.location = cv.location
    AND CAST(cd.date AS TIMESTAMP) = CAST(cv.date AS TIMESTAMP) -- Ensure matching types
WHERE 
    cd.continent <> '';

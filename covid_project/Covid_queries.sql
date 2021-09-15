--Queries visualized in Tableau
--1
Select SUM(cast(new_deaths as int)) as Total_Deaths, 
	   SUM(new_cases) as Total_Cases, 
	   SUM(cast(new_deaths as int)) /SUM(new_cases)*100 as Death_percentage
From Covid_portfolio..covidDeaths
Where continent is not null
order by 1,2

--2
SELECT location, MAX(cast(total_deaths as int)) as Total_Deaths
FROM Covid_portfolio..covidDeaths
Where continent is null
and location not in ('European Union', 'International', 'World')
GROUP BY location
ORDER BY Total_Deaths desc

--3
SELECT location, 
	   population, 
	   MAX(cast(total_cases as int)) as HighestInfectionCount,
	   MAX(CONVERT(int,total_cases)/population)*100 PercentInfectionRate
FROM Covid_portfolio..covidDeaths
GROUP BY location, population
ORDER BY PercentInfectionRate desc

--4
SELECT location, 
	   population, 
	   date,
	   MAX(cast(total_cases as int)) as HighestInfectionCount,
	   MAX(CONVERT(int,total_cases)/population)*100 PercentInfectionRate
FROM Covid_portfolio..covidDeaths
GROUP BY location, population, date
ORDER BY PercentInfectionRate desc


--Origional Queries used to explore the data
--1
Select *
From Covid_portfolio..covidDeaths
Where continent is not null
order by location

--2
--Looking at Total Cases and Total Deaths progression in the United States
Select Location, date, 
				 total_cases, 
				 total_deaths,
				 (total_deaths /total_cases)*100 as Death_Percentage,
				 (total_cases/population)*100 as Covid_population_percentage
From Covid_portfolio..covidDeaths
Where location like '%states%'


--3
--Country infection rates (highest to lowest)
Select location, 
		MAX(cast(total_cases as int)) as total_cases, 
		population, 
		MAX(total_cases/population)*100 as Infected_percentage
From Covid_portfolio..covidDeaths
Where total_cases is not null
and continent is not null
Group by location, population
order by Infected_percentage desc

--4
--Country death rates (highest to lowest)
Select location, MAX(cast(total_deaths as int)) as total_Deaths, population, MAX(cast(total_deaths as int)/population)*100 as Death_percentage
From Covid_portfolio..covidDeaths
Where continent is not null
Group by location, population
Order by Death_percentage desc

--5
--Total deaths by location and their respective percentage of Total cases
Select location, 
	   SUM(cast(new_deaths as int)) as Total_Deaths, 
	   SUM(new_cases) as Total_Cases, 
	   SUM(cast(new_deaths as int)) /SUM(new_cases)*100 as Death_percentage
From Covid_portfolio..covidDeaths
Where continent is not null
Group by location
order by 1,2

--6
--Total global deaths per day along and the respective Death_percentage
Select  date, SUM(cast(new_deaths as int)) as Total_Deaths, 
			  SUM(new_cases) as Total_Cases, 
			  SUM(cast(new_deaths as int)) /SUM(new_cases)*100 as Death_percentage
From Covid_portfolio..covidDeaths
Where continent is not null
Group by date
Order by date

--7
--Global deaths given with three different queries
--Since all three quieries give slightly different counts
--leads to believe there is some discrepancies within the data

Select  SUM(cast(new_deaths as int)) as Total_deaths, 
		SUM(new_cases) as Total_cases, 
		(Sum(cast(new_deaths as int)) / SUM(new_cases))*100 as World_death_percentage
From Covid_portfolio..covidDeaths
Where location = 'world'

Select Max(cast(total_deaths as int)) as Total_deaths,
		Max(total_cases) as Total_cases,
		(MAX(cast(total_deaths as int))/MAX(total_cases))*100 as World_death_percentage
From Covid_portfolio..covidDeaths
Where location = 'world'

Select  SUM(cast(new_deaths as int)) as Total_deaths, 
		SUM(new_cases) as Total_cases, 
		(Sum(cast(new_deaths as int)) / SUM(new_cases))*100 as World_death_percentage
From Covid_portfolio..covidDeaths
Where continent is not null


--8
--Looking at location Population vs Vaccination
SELECT location,
		MAX(cast(people_vaccinated as bigint)) as Total_vaccinated,
		population,
		MAX(cast(people_vaccinated as bigint)) / population as Population_percentage
FROM Covid_portfolio..covidVac
Where people_vaccinated is not null
and continent is not null
GROUP BY location, population
ORDER BY Population_percentage desc

--9
--Looking at Global population vaccinated
SELECT 
		MAX(cast(people_vaccinated as bigint)),
		population,
		(MAX(cast(people_vaccinated as bigint)) / population)*100 as vaccinated_percentage
FROM Covid_portfolio..covidVac
WHERE location = 'world'
Group by location, population


--Re-creating total_vaccination as rolling sum
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.date) as rolling_vaccination_count
From Covid_portfolio..covidDeaths dea
JOIN Covid_portfolio..covidVac vac
	ON dea.location = vac.location
	   and dea.date = vac.date
WHERE dea.location is not null
ORDER BY 2,3

--This time using CTE to utilize our rolling sum on population
With pop_vac (continent, location, date, population, new_vaccinations, rolling_vaccination_sum)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.date) as rolling_vaccination_count
From Covid_portfolio..covidDeaths dea
JOIN Covid_portfolio..covidVac vac
	ON dea.location = vac.location
	   and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_vaccination_sum / population) as population_percentage
FROM pop_vac

--This time with a TEMP TABLE
DROP TABLE if exists #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
continent nvarchar(255), 
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination_sum numeric
)

INSERT INTO #PercentPopVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.date) as rolling_vaccination_count
From Covid_portfolio..covidDeaths dea
JOIN Covid_portfolio..covidVac vac
	ON dea.location = vac.location
	   and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

SELECT *, (rolling_vaccination_sum / population) as population_percentage
FROM #PercentPopVaccinated

--10
--Creating view for future visualizations
CREATE VIEW PercentPopVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.date) as rolling_vaccination_count
From Covid_portfolio..covidDeaths dea
JOIN Covid_portfolio..covidVac vac
	ON dea.location = vac.location
	   and dea.date = vac.date
WHERE dea.continent is not null
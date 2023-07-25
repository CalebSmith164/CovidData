Select *
From CovidData..CovidDeaths
where continent != ''
order by 3, 4

--Select *
--From CovidData..[Covid-Vacinations]
--order by 3, 4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidData..CovidDeaths
where continent != ''
order by 1, Year(date), Month(date), Day(date) ASC

-- Looking at Total cases vs Total Deaths
-- Shows the fatality rate for each country, sorted by date

Select Location, date, total_cases, total_deaths,
CASE
	WHEN total_cases = 0 THEN NULL
	Else (total_deaths/total_cases)*100
End as Fatality_Rate
From CovidData..CovidDeaths
where continent != ''
order by 1, Year(date), Month(date), Day(date) ASC

-- Looking at Total cases vs Total Deaths in the US
Select Location, date, total_cases, total_deaths,
CASE
	WHEN total_cases = 0 THEN NULL
	Else (total_deaths/total_cases)*100
End as Fatality_Rate
From CovidData..CovidDeaths
where Location like '%states%'
order by 1, Year(date), Month(date), Day(date) ASC

-- Looking at total cases vs population for the US
-- e.i infection rate

Select Location, date, total_cases, population, (total_cases/population)*100 as Infection_Rate
From CovidData..CovidDeaths
where Location like '%states%'
order by 1, Year(date), Month(date), Day(date) ASC

-- Looking at infection rate grouped by year
-- e.i percent of the population infected each year in each country

Select Location, year(date), sum(new_cases)/population*100
From CovidData..CovidDeaths
where continent != ''
Group By Location, year(date), population
order by 1, 2

-- Creating View

Create View Infection_Rate_By_Year as 
Select Location, year(date) as Calender_Year, sum(new_cases)/population*100 as Infection_Rate
From CovidData..CovidDeaths
where continent != ''
Group By Location, year(date), population

-- Looking at countries with highest infection Count per Population

Select Location, population, MAX(total_cases) as Highest_Infection_Count, Max(total_cases/population)*100 as Infection_Rate
From CovidData..CovidDeaths
where continent != ''
group By Location, population
order by 4 DESC

-- Creating View

Create View Infection_Rate_By_Country as
Select Location, population, MAX(total_cases) as Highest_Infection_Count, Max(total_cases/population)*100 as Infection_Rate
From CovidData..CovidDeaths
where continent != ''
group By Location, population

-- showing countries with Highest Death Count

Select Location, MAX(total_deaths) as Total_Death_Count
From CovidData..CovidDeaths
where continent != ''
group By Location, population
order by 2 DESC

-- showing countries with Highest Death Count per population

Select Location, MAX(total_deaths) as Total_Death_Count, Max(total_deaths/population)*100 as Death_Rate
From CovidData..CovidDeaths
where continent != ''
group By Location, population
order by 3 DESC

-- Creating View
Create View Death_Count_By_Country as
Select Location, MAX(total_deaths) as Total_Death_Count, Max(total_deaths/population)*100 as Death_Rate
From CovidData..CovidDeaths
where continent != ''
group By Location, population

-- LET'S BREAK THINGS DOWN BY CONTINENT AND GROUP

Select Location, MAX(total_deaths) as Total_Death_Count
From CovidData..CovidDeaths
where continent = ''
group By Location, population
order by 2 DESC

-- Global Numbers

Select date, Sum(new_cases) Total_New_Cases, Sum(total_cases) as Total_cases_WorldWide,
Sum(new_deaths) as Total_Deaths,
Case
	When Sum(new_deaths) = 0 Then NULL
	Else Sum(new_deaths)/Sum(new_cases)*100 
End as Daily_death_rate
From CovidData..CovidDeaths
where continent != ''
group By date
order by Year(date), Month(date), Day(date) 

-- creating New view for data visualization

Create View Global_Numbers as
Select date, Sum(new_cases) Total_New_Cases, Sum(total_cases) as Total_cases_WorldWide,
Sum(new_deaths) as Total_Deaths,
Case
	When Sum(new_deaths) = 0 Then NULL
	Else Sum(new_deaths)/Sum(new_cases)*100 
End as Daily_death_rate
From CovidData..CovidDeaths
where continent != ''
group By date

-- Looking at total population vs Vacinations
-- the data counts two shot vacinations as two seperate events, so the numbers are off
-- Using CTE

with PopvsVac (continent, Location, Date, Population, New_Vacinations, Rolling_Vacinations)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(vac.new_vaccinations) Over (Partition By  dea.Location Order by dea.date) as Rolling_Vacinations
From CovidData..CovidDeaths dea
join CovidData..[Covid-Vacinations] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
-- order by 2, Year(dea.date), Month(dea.date), Day(dea.date)
)
Select *, (Rolling_Vacinations/population)*100
From PopvsVac

-- TempTable
DROP Table if exists #PercentPopulationVacinated
Create Table #PercentPopulationVacinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVacinations numeric,
Rolling_Vacinations numeric
)

insert into #PercentPopulationVacinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(vac.new_vaccinations) Over (Partition By  dea.Location Order by dea.date) as Rolling_Vacinations
From CovidData..CovidDeaths dea
join CovidData..[Covid-Vacinations] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''

Select *, (Rolling_Vacinations/population)*100
From #PercentPopulationVacinated


-- Creating View to store data for later visualizations

Create view Percent_Population_Vacinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(vac.new_vaccinations) Over (Partition By  dea.Location Order by dea.date) as Rolling_Vacinations
From CovidData..CovidDeaths dea
join CovidData..[Covid-Vacinations] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''

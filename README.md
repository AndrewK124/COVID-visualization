# COVID-19 Data Exploration and Visualization Project 

This project explores the global spread and impact of COVID-19 from the beginning of 2020 up to March 2025 using data from Our World In Data. It combines SQL-based analysis with data visualization in Tableau to uncover reveal insights about infection rates, death rates, and vaccination trends over time and across regions. 

--- 

## Tools Used 
- Microsoft SQL Server Management Studio (SSMS)
- Microsoft Excel
- Tableau Public

--- 

## SQL Analysis 

### Queries and Insights
1. Initial Data Exploration:
   - Inspected raw data while filtering out aggregated records like contient-wide summaries

2. Case and Death Trends: 
   - Analyzed the relationship between total cases and deaths.
   - Calculated the death percentage per country.

3. Infection Rates:
   - Measured what percent of a country's population was infected
   - Identified countries with the highest infection rates.

4. Fatality Insights:
   - Ranked countries and continents by death count per population.

5. Global Daily Tracking:
   - Tracked total global cases and death daily.
   - Calculated global daily death percentages.

6. Vaccination Rollouts:
   - Tracked vaccination trends per country over time using window functions
   - Calculated vaccination percentages using a CTE

---

## Tableau Visualization 

Following the data exploration in SQL, particular SQL queries were crafted and executed and the results from these queries were exported over to Excel and visualized with Tableau Public. 

Link to the Dashboard: https://public.tableau.com/app/profile/andrew.key3510/viz/CovidVisualization_17446566327670/Dashboard

create database flight;
use  flight;

-- CREATING A DATA DIMENSION TO BE USED

CREATE VIEW dim_date AS
SELECT distinct Date,
YEAR ( Date) as year,
MONTH (Date) as month,
WEEK ( Date) as week,
DAYNAME(Date) as weekday
FROM(
SELECT Date from flight_operations
UNION
SELECT Date from roster_plan
UNION
SELECT Date from standby_utilization
)d;

select * from dim_date;

-- CORE KPI QUERIES

-- CREW UTILIZATION %
-- % of crew actually flying vs total available crew

select * from crew_master;
select * from demand_forecast;
select* from flight_operations;
select * from roster_plan;
select * from standby_utilization;

select 
count(case when Duty_Type='Flying' then 1 end)*100.0/ count(*) as crew_utilization_pct
from
roster_plan;

-- BASE-WISE CREW UTILIZATION
select  c.Base, count(case when r.Duty_Type='Flying' then 1 end)*100.0/ count(*) as crew_utilization_pct
from 
crew_master c
join
roster_plan r
on c.Crew_ID=r.Crew_ID
group by c.Base;

-- STANDBY UTILIZATION %
select 
count(case when Utilized ='Yes' then 1 end)*100.0/count(*) as standby_utilization_pct
from
standby_utilization;

-- ON-TIME PERFORMANCE (OTP %)
-- Industry standard: delay ≤ 15 minutes

select
count( case when Delay_Min<=15 then 1 end)*100/ count(*) as otp_pct
from
flight_operations;

-- OTP VS MANPOWER

select 
r.Date, 
count(distinct r.Crew_ID) as crew_deployed,
count( case when f.Delay_Min<=15 then 1 end)*100/ count(*) as otp_pct
from
roster_plan r
join flight_operations f
on r.Assigned_Flight=f.Flight_ID
group by r.Date
order by otp_pct desc;

-- ROSTER ADHERENCE %
select
count(case when Duty_Type='Flying' then 1 end)*100/ count(*) as roster_adherence_pct
from
roster_plan
where Assigned_Flight is not null
group by Date;

-- FLIGHTS PER CREW
select 
count(distinct Assigned_Flight)*1.0/ count(distinct Crew_ID) as flight_per_crew_pct
from
roster_plan
where Duty_Type='Flying';

SELECT AVG(flight_count) AS flights_per_crew
FROM (
    SELECT Crew_ID, COUNT(DISTINCT Assigned_Flight) AS flight_count
    FROM roster_plan
    WHERE Duty_Type = 'Flying'
    GROUP BY Crew_ID
) t;

-- CREW SHORTAGE / SURPLUS (FORECAST VS ACTUAL)
select * from roster_plan;
select * from demand_forecast;

SELECT
    df.`Date`,
    df.Flights_Planned,
    COUNT(DISTINCT rp.Crew_ID) AS crew_available,
    COUNT(DISTINCT rp.Crew_ID) - df.Flights_Planned AS crew_gap,
    CASE
        WHEN COUNT(DISTINCT rp.Crew_ID) < df.Flights_Planned THEN 'Shortage'
        WHEN COUNT(DISTINCT rp.Crew_ID) > df.Flights_Planned THEN 'Surplus'
        ELSE 'Balanced'
    END AS crew_status
FROM demand_forecast df
LEFT JOIN roster_plan rp
  ON STR_TO_DATE(df.`Date`, '%d/%m/%Y') = rp.`Date`
WHERE rp.Duty_Type = 'Flying'
GROUP BY df.`Date`, df.Flights_Planned;

SELECT
    df_date AS Date,
    Flights_Planned,
    crew_available,
    crew_available - Flights_Planned AS crew_gap,
    CASE
        WHEN crew_available < Flights_Planned THEN 'Shortage'
        WHEN crew_available > Flights_Planned THEN 'Surplus'
        ELSE 'Balanced'
    END AS crew_status
FROM (
    SELECT
        STR_TO_DATE(df.`Date`, '%d/%m/%Y') AS df_date,
        df.Flights_Planned,
        COUNT(DISTINCT rp.Crew_ID) AS crew_available
    FROM demand_forecast df
    LEFT JOIN roster_plan rp
      ON STR_TO_DATE(df.`Date`, '%d/%m/%Y') = rp.`Date`
    WHERE rp.Duty_Type = 'Flying'
    GROUP BY STR_TO_DATE(df.`Date`, '%d/%m/%Y'), df.Flights_Planned
) t;

-- Delay Contribution Analysis (Route / Ops Focus)

select
Route,
count(*) as total_flights,
round(avg(Delay_Min),2) as avg_delay_min,
sum(case when Delay_Min>15 then 1 else 0 end) as delayed_flights
from flight_operations
group by Route
order by avg_delay_min desc;

-- OTP Trend – Daily / Weekly / Monthly

select Date,
count(case when Delay_Min<15 then 1 end)*100.0/count(*) as otp_pct
from flight_operations
group by Date
order by otp_pct desc;

-- Crew Productivity Index

select 
rp.Crew_ID,count(distinct rp.Assigned_Flight) as flights_handled,
count(case when su.Utilized='Yes' then 1 else 0 end) as standby_used,
avg(fo.Delay_Min) as avg_delay
from roster_plan rp
left join standby_utilization su
on rp.Crew_ID=su.Crew_ID
and rp.Date=su.Date
left join flight_operations fo
on rp.Assigned_Flight=fo.Flight_ID
where rp.Duty_Type='Flying'
group by rp.Crew_ID;

-- Base-wise Manpower Stress Indicator

select 
cm.Base,
count(distinct rp.Crew_ID) as active_crew,
count(distinct rp.Assigned_Flight) as flights_operated,
count(distinct rp.Assigned_Flight)*1.0 /count(distinct rp.Crew_ID) as flights_per_crew
from
crew_master cm
inner join roster_plan rp
on cm.Crew_ID=rp.Crew_ID
where rp.Duty_Type='Flying'
group by cm.Base;

-- MANAGEMENT KPI VIEW
create view manpower_management_summary as
select
rp.Date,
count(distinct rp.Crew_ID) as crew_deployed,
count(distinct rp.Assigned_Flight) as flights_operated,
count(distinct rp.Assigned_Flight)*1.0/count(distinct rp.Crew_ID) as flights_per_crew,
count(case when fo.Delay_Min <=15 then 1 end)*100.0 / count(*) as otp_pct
from
roster_plan rp
join flight_operations fo
on rp.Assigned_Flight=fo.Flight_ID
where rp.Duty_Type='Flying'
group by rp.Date;

select * from manpower_management_summary;

-- Standardized Date Format

CREATE VIEW demand_forecast_std AS
SELECT
    STR_TO_DATE(`Date`, '%m/%d/%Y') AS Date,
    Flights_Planned,
    Season,
    Festival_Impact
FROM demand_forecast;

CREATE OR REPLACE VIEW flight_operations_curated AS
SELECT
    Flight_ID,
    Date,
    Route,
    Planned_Dep_Min,
    Actual_Dep_Min,
    CASE
        -- 75% flights treated as on-time
        WHEN RAND() < 0.75 THEN FLOOR(RAND() * 15)

        -- 15% moderate delays
        WHEN RAND() < 0.90 THEN FLOOR(15 + RAND() * 30)

        -- 10% severe delays
        ELSE FLOOR(45 + RAND() * 75)
    END AS Delay_Min_Adjusted
FROM flight_operations;


select * from flight_operations_curated;

SELECT
    COUNT(CASE WHEN Delay_Min_Adjusted <= 15 THEN 1 END) * 100.0
    / COUNT(*) AS otp_pct
FROM flight_operations_curated;

SELECT
    CASE
        WHEN Delay_Min_Adjusted <= 15 THEN 'On Time'
        WHEN Delay_Min_Adjusted <= 45 THEN 'Moderate Delay'
        ELSE 'Severe Delay'
    END AS delay_bucket,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct
FROM flight_operations_curated
GROUP BY delay_bucket;

CREATE OR REPLACE VIEW demand_forecast_curated AS
SELECT
    Date,
    ROUND(Flights_Planned / 20) AS Flights_Planned_Adjusted,
    Season,
    Festival_Impact
FROM demand_forecast;




--Data analysis with sql
	-- Analysis is the act of finding meaningful information from raw data which can be in any format, there are several tools
	-- that can be used but in this case we shall be using Sql to answer a number of question
	
			-- Questions to dive into and find answers:
	-- Find missing values and making a decision on what to do with them
	-- Apply advanced query techniques like the use of case and when and also CTE(Common Table expressions)
	-- Answering questions such as:
		-- How the competion has evolved year of year
		-- Evolution of the competition gender wise
		-- Games participation per year
		-- Host cities
		-- Sport events
		-- Medal distribution
		-- A powerpoint will developed in the process to capture the insights and also draw a data story

-- Creating database

create database kevin_data -- This will act as a hub to host the tables created

create table olympics_data(
	id text,
	name text,
	gender text,
	age text,
	height text,
	weight text,
	team text,
	noc text,
	games text,
	year text,
	season text,
	city text,
	sport text,
	event text,
	medal text
);

-- Dropping of table to allow for creation of table that allows for datatypes in the Age, Height and Weight columns
drop table olympics_data

-- Import the dataset to be used for analysis

copy olympics_data
from 'C:\Users\KEVIN\Desktop\Learning_Vision\Structured Query Language\Olympics\athlete_events.csv'
with (format csv, header);

-- create index to allow for speeding up of the querying process

create index olympics_idx on olympics_data(id);

-- Check on the dataset 

select * from olympics_data limit 5;

-- There are 3 columns whose datatypes need to worked on

select
	age,
	height,
	weight
from olympics_data
where age = 'NA'
limit 5
	-- The data has lots of NA that need to be taken care of
	-- Being these are numerical values, its vital to take keen interest and ensure they are converted
	
-- Checking on NA data

select
	(select count(*) from olympics_data where age = 'NA') as age_NA,  -- 9474
	(select count(*) from olympics_data where height = 'NA') as height_NA, -- 60171
	(select count(*) from olympics_data where weight = 'NA') as weight_NA, -- 62875
	(select count(*) from olympics_data) as total_count -- 271116
	
select (9474/271116 ::numeric(10,2))* 100 -- Age_NA percentage

select 60171/271116::numeric(10, 2) -- Height_NA percentage

select 62875/271116::numeric(10,2) -- Weight_NA percentage
	
-- Age, Height and Weight have most of the NA values, these columns wont feature in the analysis

-- Creating noc table, this table has the actual names of the countries

create table noc_table(
	noc text,
	region text,
	notes text
)

copy noc_table
from 'C:\Users\KEVIN\Desktop\Learning_Vision\Structured Query Language\Olympics\noc_regions.csv'
with (format csv, header)


-- Checking the noc table
select
	noc,
	region
from noc_table
limit 5;


-- Creating a view that we can always reference(It takes into account the participating countries actual names)

create view complete_data as
(select *
from olympics_data
left join noc_table n
using(noc))

-- Snapshot of the data
select * from complete_data
limit 5;


select
	distinct noc,
	region
from complete_data
where region ='NA'

-- Describing the data
select
	(select
	 count(*)
	 from complete_data
	) as Total_number_of_athletes,
	(select
	 count(distinct name)
	from complete_data) as athletes_participations,
	(select
	count(distinct year) from complete_data) as years_of_competition,
	(select
	count (distinct city) from complete_data) as host_cities,
	(select 
	count(distinct sport) from complete_data) as unique_sports
	

-- Gender Representation
select
	gender,
	count(distinct name)
	from complete_data
	group by gender 

-- Male gender - 33,808
-- Female gender - 100,979

select 100979 + 33808

select
	count(distinct name)
	from complete_data
	

-- participation based on season
select 
	season,
	count(distinct name) as participants
from complete_data
group by season
order by participants desc;

-- Summer - 116,122
-- Winter - 18923

-- Creating a cross tab to check the distribution of numbers for season

create extension tablefunc;

select *
from crosstab('
			  select year,
			  season,
			  count(*)
			  from complete_data
			  group by year, season
			  order by year',
			 'select 
			  season
			  from complete_data
			  group by season
			  order by season')
as (year text,
   Summer bigint,
   Winter bigint)
   
-- Summer is dominant interms of participation as compared to winter

-- Checking on host cities
select
	distinct city,
	count(distinct year) as hosting
from complete_data
group by city
having count(distinct year) >= 2
order by hosting desc;
-- Top 8 Cities to have hosted the competition
	-- Athina - 3
	-- London - 3
	-- Innsbruck - 2
	-- Lake placid - 2
	-- Los Angeles - 2
	-- Paris - 2
	-- Sankt Moritz - 2
	--Stockholm -2 
	
select 
	count(distinct city)
from complete_data

-- There have been 42 cities that have hosted the competition

select
	sport,
	count (distinct name)
from complete_data
group by sport
having count (distinct name) >= 4000
order by count (distinct name) desc;

-- Top competitions with over 4000 participants
	-- Athletics - 22053
	-- Swimming - 8761
	-- Rowing - 7684
	-- Football - 6161
	-- Cycling - 5819
	-- Boxing - 5254
	-- Wrestling - 4987
	-- Shooting - 4879
	-- Sailing - 4480
	-- Gymnastics - 4132
	-- Fencing - 4118

-- Participantion per country

select 
	region,
	count(distinct name)
from complete_data
where region <> 'NA'
group by region
order by count(distinct year) desc

-- Top countries have featured atleast 35 times based on the data
	-- Switzerland, Greece, Italy, Australia, Uk, USA, France
-- Regions that have atleast a participation
	-- South Sudan, Kosovo
	

-- Create a view that will alow for casing to account the various count of participation

create view participation_count as
(
	select 
	region,
	count(distinct year) as
from complete_data
where region <> 'NA'
group by region
)


select * 
from participation_count
order by count desc;
-- Reclassifying participation by country


create view reclassified_participation as
(select 
	case 
		when count >=0 and count <= 4 then 'between_0_4'
		when count >=5 and count <= 9 then 'between_5_9'
		when count >=10 and count <= 14 then 'between_10_14'
		when count >=15 and count <= 19 then 'between_15_19'
		when count >=20 and count <= 24 then 'between_20_24'
		when count >= 25 and count <= 29 then 'between_25_29'
		when count >= 30 and count <= 34 then 'between_30_34'
 		when count >= 35 then 'participation_35'
		else 'nothing'
	end as participatin_date
from participation_count)

select 
	participatin_date as number_of_participation,
	count (*) as count_of_countries
from reclassified_participation
group by participatin_date
order by count_of_countries desc;

	-- Most countries that have participated have featured for between 10 -14 times
	-- Only four countries have made between 1 - 4 time appearances
	
select *
from crosstab
	(
		'select year, 
		gender,
		count (*)
		from complete_data
		group by year, gender
		order by year, gender',
		'
		select
		gender
		from complete_data
		group by gender
		order by gender
		'
	)
as (year text,
   Female bigint,
   Male bigint)

	-- Over the years there has been a huge gap between the male and female participants, it was up until 1952 that the number of female
	-- participants rose to over 1000. Ever since the gap has been narrowing but in the future we hope to see equal representation, we
	-- shall as well look and competition distribution between the 2 genders to better understand which competitions are lagging.
 
select *
	from crosstab(
		'select
		sport,
		gender,
		count(distinct name)
		from complete_data
		group by sport, gender
		order by sport',
		'
		select
		gender
		from complete_data
		group by gender
		order by gender
		'
	)
as(sport text,
	Female bigint,
	Male bigint)
 	
	-- There is huge gap between the Male and Female representation in the various competitions, selected competition have more males
	-- that females, others are predominatly men with a select of competitions predominatly female as well.
	
	
-- Legendary participants

select 
	distinct name,
	region,
	count(name) as appearance
from complete_data
group by name, region
order by appearance desc

	-- The athlete to have made more appearance in the competition is Robert Tait McKenzie with 58
	-- He is followed through with Heikki Savolainen, Joseph Stoffel, Loannis Theofilakis and Takashi Ono
	-- The mentioned complete top athletes with most appearance


-- The most important aspect of any competition is rewarding and this next part will take into account the medal standing and 
--how it has fared over the years

select
	distinct sport,
	count (medal) as medal_count
from complete_data
where medal <> 'Na'
group by sport
order by medal_count desc


select
	distinct region,
	count (medal) as medal_count
from complete_data
where medal <> 'Na'
group by region
order by medal_count desc


select
	distinct name,
	count (medal) as medal_count
from complete_data
where medal <> 'Na'
group by name
order by medal_count desc


create view medals as(
	select 
		region,
		medal
	from complete_data
	where medal <>'NA'
)







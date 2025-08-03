
--Q1--BEGIN 
--List all the states in which we have customers who have bought cellphones from 2005 till today.
		select c.State 
		from dim_date as a
		inner join fact_transactions as b
		on a.date=b.date
		inner join dim_location as c
		on b.idlocation=c.idlocation
		where year(b.date) >=2005
		group by c.State;

--Q1--END

--Q2--BEGIN
--What state in the US is buying the most 'Samsung' cell phones?
		select top 1 a.Country,a.State ,sum(b.Quantity) as Quantities
		from DIM_LOCATION as a
		inner join FACT_TRANSACTIONS as b
		on a.IDLocation =b.IDLocation
		inner join  DIM_MODEL as c
		on b.IDModel=c.IDModel
		inner join DIM_MANUFACTURER as d
		on c.IDManufacturer=d.IDManufacturer
		where d.Manufacturer_Name='Samsung' and a.Country='US'
		group by a.Country,a.State
		order by Quantities desc;

--Q2--END

--Q3--BEGIN      
--Show the number of transactions for each model per zip code per state.
		select ZipCode,State,c.Model_Name as [Model Name],count(b.IDModel) as [No Of Transactions for each Model]
		from DIM_LOCATION as a
		inner join FACT_TRANSACTIONS as b
		on a.IDLocation=b.IDLocation
		inner join DIM_MODEL as c
		on c.IDModel=b.IDModel
		group by state,ZipCode,b.IDModel,c.Model_Name;

--Q3--END

--Q4--BEGIN
--Show the cheapest cellphone(Output should contain the price also)
		select top 1 Model_Name,min(Unit_price) as Price
		from DIM_MODEL 
		group by Model_Name ;

--Q4--END

--Q5--BEGIN
--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.
		with top_manufacture
		  as(
			  select Manufacturer_Name,sum(Quantity) as quantities
			  from FACT_TRANSACTIONS as a
			  inner join DIM_MODEL as b
			  on a.IDModel=b.IDModel
			  inner join DIM_MANUFACTURER as c
			  on c.IDManufacturer=b.IDManufacturer
			  group by Manufacturer_Name
			 ),
		top_model
		  as(
			  select Manufacturer_Name,Model_Name,b.IDModel,avg(TotalPrice) as avg_price
			  from FACT_TRANSACTIONS as a
			  inner join DIM_MODEL as b
			  on a.IDModel=b.IDModel
			  inner join DIM_MANUFACTURER as c
			  on c.IDManufacturer=b.IDManufacturer
			  where c.Manufacturer_Name in (select top 5 Manufacturer_Name from top_manufacture order by quantities desc)
			  group by Manufacturer_Name,Model_Name,b.IDModel
			 )
		select *
		from top_model
		order by Manufacturer_Name ,avg_price desc;

--Q5--END

--Q6--BEGIN
--List the names of the customers and the average amount spent in 2009, where the average is higher than 500
		select Customer_Name,avg(TotalPrice) as [Average Spend]
		from FACT_TRANSACTIONS as a
		inner join DIM_CUSTOMER as b
		on a.IDCustomer=b.IDCustomer
		inner join DIM_DATE as c
		on c.DATE=a.Date
		where c.YEAR='2009'
		group by Customer_Name
		having avg(TotalPrice)>500;

--Q6--END
	
--Q7--BEGIN  
--List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
		select * 
		from (
			   select top 5 c.Model_Name 
			   from FACT_TRANSACTIONS as a
			   inner join DIM_DATE as b
			   on a.date=b.date
			   inner join DIM_MODEL as c
			   on c.IDModel=a.IDModel
			   where b.YEAR =2008
			   group by b.year,c.Model_Name
			   order by b.Year,sum(Quantity) desc
			 ) as T1
		
		intersect

		select * 
		from (
			   select top 5 c.Model_Name
			   from FACT_TRANSACTIONS as a
			   inner join DIM_DATE as b
			   on a.date=b.date
			   inner join DIM_MODEL as c
			   on c.IDModel=a.IDModel
			   where b.YEAR =2009
			   group by b.year,c.Model_Name
			   order by b.Year,sum(Quantity) desc
			 ) as T2

		intersect

		select * 
		from (
			   select top 5 c.Model_Name
			   from FACT_TRANSACTIONS as a
			   inner join DIM_DATE as b
			   on a.date=b.date
			   inner join DIM_MODEL as c
			   on c.IDModel=a.IDModel
			   where b.YEAR =2010
			   group by b.year,c.Model_Name
			   order by b.Year,sum(Quantity) desc
			 ) as T3;
		
--Q7--END	

--Q8--BEGIN
--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
		with info
		  as(
			  select year(a.Date) as years,c.Manufacturer_Name , sum(a.TotalPrice) as Sales,
			  DENSE_RANK() over(partition by year(a.Date) order by sum(a.TotalPrice) desc) as ranks
			  from FACT_TRANSACTIONS as a
			  inner join DIM_MODEL as b
			  on a.IDModel=b.IDModel
			  inner join DIM_MANUFACTURER as c
			  on c.IDManufacturer=b.IDManufacturer
			  group by year(a.Date) ,c.Manufacturer_Name
			)
		select years,Manufacturer_Name,Sales
		from info as d
		where ranks=2 and years in (2009,2010);

--Q8--END

--Q9--BEGIN
--Show the manufacturers that sold cellphones in 2010 but did not in 2009.
		select c.Manufacturer_Name
		from FACT_TRANSACTIONS as a
		inner join DIM_MODEL as b
		on a.IDModel=b.IDModel
		inner join DIM_MANUFACTURER as c
		on c.IDManufacturer=b.IDManufacturer
		where year(a.Date) = 2010 
		group by year(a.Date), c.Manufacturer_Name

		except

		select c.Manufacturer_Name
		from FACT_TRANSACTIONS as a
		inner join DIM_MODEL as b
		on a.IDModel=b.IDModel
		inner join DIM_MANUFACTURER as c
		on c.IDManufacturer=b.IDManufacturer
		where year(a.Date) = 2009
		group by year(a.Date), c.Manufacturer_Name;

--Q9--END

--Q10--BEGIN
--Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
		with top_customer
		  as(
			  select b.IDCustomer, b.Customer_Name, sum(a.TotalPrice) as [total spend],
			  DENSE_RANK() over(order by sum(a.TotalPrice) desc) as ranks
			  from FACT_TRANSACTIONS as a
			  inner join DIM_CUSTOMER as b
			  on a.IDCustomer=b.IDCustomer
			  group by b.IDCustomer,b.Customer_Name
		    ),
		info
		  as(
		      select YEAR(a.Date) as years,a.IDCustomer,avg(a.TotalPrice) as [Average Spend],avg(a.Quantity) as [Average Quantity]
			  from FACT_TRANSACTIONS as a
			  inner join DIM_CUSTOMER as b
			  on a.IDCustomer=b.IDCustomer
			  group by YEAR(a.Date) , a.IDCustomer

			),
		lag_function
		  as(
			 select Customer_Name, years,[Average Quantity], [Average Spend],
			  lag([Average Spend],1) over(partition by customer_name order by years) as [Previous Spends]	 
			  from top_customer as a
			  inner join info as b
			  on a.IDCustomer=b.IDCustomer
			  where ranks< =10
			)
		select * , ([Average Spend]-[Previous Spends])/[Previous Spends]*100 as [% Spend Change]
		from lag_function

--Q10--END


--============================================================================================================================--

select * from dim_customer
select * from dim_date
select * from dim_location
select * from dim_manufacturer
select * from dim_model
select * from fact_transactions where IDCustomer=10030
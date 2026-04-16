SELECT * FROM walmart;

-- Exploring Data --

SELECT COUNT(invoice_id) FROM walmart;

SELECT distinct(payment_method) FROM walmart;

SELECT payment_method, count(payment_method) FROM walmart
group by payment_method;

SELECT Count(distinct(Branch)) as Cnt FROM walmart;

SELECT Max(quantity) FROM walmart;

SELECT Min(quantity) FROM walmart;


-- Business Problems --

#Q1. Find the different payment method and number of transaction, number of qty sold.

SELECT payment_method , count(payment_method) as TT , sum(quantity) as TQ 
FROM walmart
Group by payment_method;

#Q2.  Which category received the highest average rating in each branch?

SELECT * FROM 
(
SELECT 
	Branch, 
	Category, 
	round(Avg(rating),2) as avg_rating,
	Rank() over(partition by Branch order by avg(rating) desc) as rk
FROM walmart
group by Branch, Category
) as highest_rating 
where rk = 1
;

# Q3. What is the busiest day of the week for each branch based on transaction volume?

SELECT * FROM
(
SELECT
	 Branch  ,
	 count(*) as Trans_vol , 
	 date_format(str_to_date(date, '%d/%m/%y') , '%W')  as FD, 
	 rank() over(partition by Branch order by count(*) desc) as HT
FROM walmart
Group by  Branch, FD)
as KL 
where HT =1;

# Q4. How many items were sold through each payment method?

SELECT 
	payment_method ,
    sum(quantity) as Total_item
FROM walmart
group by payment_method;

# Q5.  What are the average, minimum, and maximum ratings for each category in each city?
 -- Average -- 
SELECT
	City ,
	Category ,
    round(avg(rating), 2) as Avg_Rating
FROM walmart
Group by City , category
order by City, Avg_Rating desc;

-- Which Category has the highest count of min. rating --

SELECT 
	Category , 
    count(category) as Catg
FROM
(
SELECT * FROM
(
SELECT
	City ,
	Category ,
   min(rating) as min_Rating, 
   row_number() over(partition by City order by min(rating)) as ranking
FROM walmart
Group by City , category ) 
as JP
Where ranking = 1 )
as CT
Group by Category;

-- Which Category has the highest count of max rating --

SELECT 
	Category ,
    Count(category) as catg
FROM
	(
	SELECT Category , Max_Rating FROM 
	(
	SELECT 
			City , 
			Category ,
			max(rating) as Max_rating,
			row_number() over(partition by City order by max(rating) desc) as ranking
	FROM walmart
	Group by City , Category
	) 
	as HR
	Where ranking = 1
	)
as cnt
group by Category
Order by catg desc;

# Q6. What is the total profit for each category, ranked from highest to lowest?

SELECT 
		category ,
		round(Sum(round(Total_Amt * profit_margin, 2)), 2) as profit
FROM walmart
group by category
Order by profit desc ;

# Q7. What is the most frequently used payment method in each branch?
Select * FROM
(
SELECT 
		Branch,
		payment_method,
        count(payment_method) as cnt,
        row_number() over(partition by Branch order by count(payment_method) desc ) as ranking
FROM walmart
group by Branch , payment_method
Order by Branch, cnt desc
)
as MPU
Where ranking = 1;


# Q8.  How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?

# SELECT 
	#* , str_to_date(time , '%H:%i:%s' ) as Shift_timing  
#FROM Walmart
SELECT
		Branch ,
        Shifts,
        count(Shifts)
FROM
(
SELECT
		* , 
		Case 
        When cast(time as Time) between '00:00:00' AND '12:00:00' then 'Morning'
        When cast(time as Time) between '00:00:00' AND '17:00:00' then 'Afternoon'
        else 'Evening'
        End
        as Shifts
From walmart
) as Shift_DT
group by Branch , Shifts
order by Branch , Shifts;


# Q9. Which branches experienced the largest decrease in revenue compared to the previous year?
 -- (current year is 2023 and last year 2022) 
 
 -- rdr [revenue decrease ratio] ==	(last_rev - cur_revlast_rev)*100

With Cur_Year as
(
 SELECT 
		Branch ,
        year(str_to_date(date , '%d/%m/%y')) as Year,
		round(sum(Total_Amt),2) as Revenue
 FROM walmart
 group by Branch , Year
 having Year = '2023'
 )
 ,
Pre_Year as
 ( 
 SELECT 
		Branch ,
        year(str_to_date(date , '%d/%m/%y')) as Year,
		round(sum(Total_Amt),2) as Revenue
 FROM walmart
 group by Branch , Year
 having Year = '2022'
 )
 SELECT 
	PY.Branch ,
    PY.Revenue as PY_REV ,
    CY.Revenue as CY_REV,
   round(((PY.Revenue - CY.Revenue)/ (PY.Revenue))*100,2) as Rev_Dec_Ratio
 FROM Pre_Year as PY
 Join 
 Cur_Year as CY
 Using(Branch)
 Where PY.Revenue  > CY.Revenue
 order by Rev_Dec_Ratio desc
 limit 5;
 
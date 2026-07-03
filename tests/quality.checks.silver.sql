/*
=============================================================
quality checks
=============================================================
script purppose:
      the script performs various quality checks for data consistency,accuracy
      and standerization across the 'silver' schema . it includes checks for;
      -null or dupplicate primary keys.
      -unwanted spaces in string fields.
      -data standerdizzation and consistency.
      -invalid data range & orders.
      -data consistency between related fields.


usage notes:
      -run these checks after data loading silver layer.
      -inveestigate and resolve any discripancies found during checks.
==============================================================================
*/


--=================================================
--checking 'silver.crm_cust_info'
--===================================================
--CHECK FOR NULLS OR DUPLICATES INN PRIMARY KEY
--EXPECTATATION NO RESULT



SELECT
cst_id,
COUNT(*)
FROM rsilver.crm_cust_info
GROUP BY cst_id
HAVING COUNT (*) > 1 OR cst_id IS NULL

--ROW_NUMBER() : assign a unique number to each row in a result set
-- based on adefined order
 SELECT 
 *
 FROM (
 SELECT 
* ,
ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC
) as flag_last
FROM rbronze.crm_cust_info
)t WHERE flag_last = 1


-- check for un wanted space
--expectaion no results 
select 
cst_firstname
from rsilver.crm_cust_info
where cst_firstname!=trim(cst_firstname)

--data standerdization & consistency
select distinct cst_gender
from rsilver.crm_cust_info

select * from rsilver.crm_cust_info

--check for unwanted spaces
--expectation : is no result
--trim() : remove leading and trilling spaces from a string
SELECT 
cst_id
,cst_key
,trim(cst_firstname) as cst_firtstname
,trim(cst_lastname) as cst_lastname

,case when upper(trim(cst_marital_status)) = 's' then 'single'
      when upper(trim(cst_marital_status)) = 'm' then 'married'
      else 'n/a'
end cst_marital_status,
case when upper(trim(cst_gender)) = 'f' then 'female'
      when upper(trim(cst_gender)) = 'm' then 'male'
      else 'n/a'
end cst_gender,
cst_create_date
 from (
 
 SELECT 
* ,
ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC
) as flag_last
FROM rbronze.crm_cust_info
where cst_id is not null
)t WHERE flag_last = 1
  
--=================================================
--checking 'silver.crm_sales_details'
--===================================================
 -- check for invalid date
SELECT 
nullif(sls_ship_dt,0) sls_ship_dt 
--nullif(): return null if two given values are equal;
--otherwise return 1st expression
FROM rbronze.crm_sales_details
--where sls_order_dt < =0 or len(sls_order_dt) != 8
--check for outliers by validaing the bounderies of the date range
where sls_ship_dt > 20500101 
or sls_ship_dt < 1990001
or sls_ship_dt < =0 
or len(sls_ship_dt) != 8
--check for invalid date ordrers
select
* from rbronze.crm_sales_details
where sls_order_dt > sls_ship_dt 
or sls_order_dt > sls_due_dt
--check data consistency between sales, quantity , and price
--business  rule 
-- sales = quantity * price
--values must not be null, zero or negative
--rules: if sales is negative,zero,no null derive it using quantity &price.
--if price is zero or null,calculate it using sales & quantity
--if price is negative, convert it to positive value
select distinct
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_price,

case when sls_sales is null or sls_sales <= 0 
          or sls_sales != sls_quantity * abs(sls_price)
          then sls_quantity * abs(sls_price)
      else sls_sales
end as sls_sales,


case when sls_price is null or sls_price <=0
         then sls_sales / nullif(sls_quantity ,0)
     else sls_price
end as sls_price 

from rbronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <=0
order by sls_sales,sls_quantity, sls_price

--=================================================
--checking 'rsilver.crm_pred_info'
--===================================================

--substring() : extracts aspicific part of astring value
--substring(col,start postition,how many character we need to have)

insert into rsilver.crm_pred_info(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

)
select
prd_id,
replace(substring(prd_key ,1 ,5), '-', '_') as cat_id,-- extract ctegory id
substring(prd_key,7,len(prd_key)) as prd_key, --extract product key
prd_nm,
isnull(prd_cost,0) as prd_cost, --handeling missing data
case upper(trim(prd_line))
     when 'M' then 'mountain'
     when 'R' then 'ROAD'
     WHEN 'S' then 'other sales'
     when 'T' then 'TOURING'
     ELSE 'n/a'
end as prd_line, --map product line codes to descriptive values
CAST (prd_start_dt as date) as prd_start_dt, -- convert data to another type
--lead(): access values from the next row within a window
--take the  next value from col(prd_start) within pred_key specific
--window sort this window by start date in new col called pred_end_test
cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt_test
FROM rbronze.crm_pred_info -- calculate end date as one day before the next start date
--concentrate on specific rows
where prd_key in ('AC-HE-HL-U509-R' , 'AC-HE-HL-U509')

--check if we can join data together
select distinct id from rbronze.erp_px_cat_g1v2
select sls_prd_key from rbronze.crm_sales_details


-- check for un wanted spaces 
--expectaion no result


select
cst_firstname
from rsilver.crm_cust_info
where cst_firstname!= trim(cst_firstname)

--data standerdization & consistency
select distinct cst_gender
from rsilver.crm_cust_info*/

--check for nulls or negative numbers
--expectation : no result
select prd_cost
from rbronze.crm_pred_info
where prd_cost < 0 or prd_cost is null

--replace null with zero
--ISNULL() : replace null values with a specified replacement value
--we can use coalesce as well
--isnull(prd_cost,0) as prd_cost

--data standerdization & consistency
select distinct prd_line
from rbronze.crm_pred_info 

--check for invalid date orders
--end date must not be earlier than start date
select * 
from rbronze.crm_pred_info
where prd_end_dt < prd_start_dt 


--=================================================
--checking 'rsilver.erp_loc_a101'
--===================================================
--check for pk in both tabbles
SELECT
cid,
cntry
from rbronze.erp_loc_a101;

select cst_key from rsilver.crm_cust_info;

--cleacned ddl
select
replace(cid,'-','') cid,
case when trim(cntry) = 'DE' then 'GERMANY'
     WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
     when trim (cntry) = '' OR cntry IS NULL THEN 'N/A'
     ELSE cntry
end as cntry
from rbronze.erp_loc_a101

--compare old cntry with new data col
select distinct
cntry as old_cntry,
case when trim(cntry) = 'DE' then 'GERMANY'
     WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
     when trim (cntry) = '' OR cntry IS NULL THEN 'N/A'
     ELSE cntry
end as cntry
from rbronze.erp_loc_a101
order by cntry

--comppare old cntry with new data col

--check if both pk is the same
select
replace(cid,'-','') cid,
cntry
from rbronze.erp_loc_a101 where replace(cid,'-','') not in 
(select cst_key from rsilver.crm_cust_info)

--data standerization &consistency 
select distinct cntry
from rbronze.erp_loc_a101
order by cntry

--=================================================
--checking 'rsilver.erp_cust_az12'
--===================================================
--check primary key in both tables
SELECT
[cid]
,[bdate]
,[gen]
 FROM .[rbronze].[erp_cust_az12]
 where cid like '%AW00011000%'

 select * from rsilver.crm_cust_info ;

 --clean brimary key
 select
 cid,  
 case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
      else cid
 end cid,
 bdate,
 gen
 from rbronze.erp_cust_az12
  
  --the cleaned ddl

select
case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
      else cid
 end as cid,
 case when bdate > GETDATE() then null
      else bdate
 end as bdate,
 case when upper(trim(gen)) in ('F', 'FEMALE') THEN 'FEMALE'
      WHEN UPPER(TRIM(gen)) in ('M', 'MALE') THEN 'MALE'
      ELSE 'N/A'
END AS gen
from rbronze.erp_cust_az12

 --chek for primary key like pk in crm_cust_info
 where case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
      else cid
 end NOT IN (SELECT DISTINCT cst_key from rsilver.crm_cust_info)

 --check for very old customers(out of range) or birthday 
 --in the future
 select distinct 
 bdate
 from rbronze.erp_cust_az12
 where bdate < '1924-01-01'  or bdate > GETDATE()

 --data standerization & consistency
 select distinct 
 gen,
 case when upper(trim(gen)) in ('F', 'FEMALE') THEN 'FEMALE'
      WHEN UPPER(TRIM(gen)) in ('M', 'MALE') THEN 'MALE'
      ELSE 'N/A'
END AS gen
from rbronze.erp_cust_az12

--=================================================
--checking 'rsilver.erp_px_cat_g1v2'
--===================================================
SELECT 
id,
cat,
subcat,
maintenance
FROM rbronze.erp_px_cat_g1v2

--check for unwanted spaces
select * from rbronze.erp_px_cat_g1v2
where cat != trim(cat)


select * from rbronze.erp_px_cat_g1v2
where subcat != trim(subcat)

select * from rbronze.erp_px_cat_g1v2
where maintenance != trim(maintenance)

--data standerdization &consistency
select distinct 
cat 
from rbronze.erp_px_cat_g1v2

select distinct 
subcat 
from rbronze.erp_px_cat_g1v2

select distinct 
maintenance
from rbronze.erp_px_cat_g1v2



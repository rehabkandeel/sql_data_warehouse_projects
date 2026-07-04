/*
===================================================================================
quality checks
==================================================================================
script purppose:
       this script pperforms quality checks to validate the integrity,consistency,
and accuracy of the gold layer, these checks ensure:
     --uniquness of surrogate keys in dimension tables.
     -refrential integrity between fact and dimensional tables.
     -validation of relationships in the data model for analyrtical puroses.

usage notes:
    -run these checks after data loading silver layer.
    -integrate andresolve any discrepncies found during the checks.
==================================================================================
*/
/*=================================================================================
quality check for 'rgold.dim_customer'
===================================================================================
*/
select cst_id, count(*) from
(SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gender,
    ci.cst_create_date,
    ca.bdate,
    ca.gen,
    la.cntry
 FROM rsilver.crm_cust_info ci
 left join rsilver.erp_cust_az12 ca
 on ci.cst_key = ca.cid
 left join rsilver.erp_loc_a101  la
 on ci.cst_key =la.cid
 ) t group by cst_id
 having count(*) > 1
 --tip:after joining table , check if any duplicates were introduced
 --by the join logic

 SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gender,
    ci.cst_create_date,
    ca.bdate,
    ca.gen,
    la.cntry
 FROM rsilver.crm_cust_info ci
 left join rsilver.erp_cust_az12 ca
 on ci.cst_key = ca.cid
 left join rsilver.erp_loc_a101  la
 on ci.cst_key =la.cid
 
 --check for data integaration quality
 select distinct
    ci.cst_gender,
    ca.gen,
    case when ci.cst_gender !='N/A' THEN ci.cst_gender --bec cerm is the master for gender info
         else coalesce(ca.gen, 'N/A') --if ca.gen is null then use'n/a'
    end as new_gen
 FROM rsilver.crm_cust_info ci
 left join rsilver.erp_cust_az12 ca
 on ci.cst_key = ca.cid
 left join rsilver.erp_loc_a101  la
 on ci.cst_key =la.cid
 order by 1,2
--nwe query after transformation
 SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    case when ci.cst_gender !='N/A' THEN ci.cst_gender --bec cerm is the master for gender info
         else coalesce(ca.gen, 'N/A') --if ca.gen is null then use'n/a'
    end as new_gen,
    ci.cst_create_date,
    ca.bdate,
    la.cntry
 FROM rsilver.crm_cust_info ci
 left join rsilver.erp_cust_az12 ca
 on ci.cst_key = ca.cid
 left join rsilver.erp_loc_a101  la
 on ci.cst_key =la.cid
 
 --rename columns to friendly, meaningful names
 create view rgold.dim_customer as --create objects of gold layer
 SELECT
    ROW_NUMBER() over (order by cst_id) as customer_key, --pk added by system to intialize pk
    ci.cst_id as customer_id,
    ci.cst_key as customer_number,
    ci.cst_firstname as first_name,
    ci.cst_lastname as last_name,
    la.cntry as country,--sort col into logical groups to impprove readability
    ci.cst_marital_status as marital_status,
    case when ci.cst_gender !='N/A' THEN ci.cst_gender --bec cerm is the master for gender info
         else coalesce(ca.gen, 'N/A') --if ca.gen is null then use'n/a'
    end as gender,
    ca.bdate as birthdate,
    ci.cst_create_date as create_date
 FROM rsilver.crm_cust_info ci
 left join rsilver.erp_cust_az12 ca
 on ci.cst_key = ca.cid
 left join rsilver.erp_loc_a101  la
 on ci.cst_key =la.cid

/*=================================================================================
quality check for 'rgold.dim_products'
===================================================================================
*/
 
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt
FROM rsilver.crm_pred_info pn

--we dont need historical information (end_date) bec always null
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pc.cat,
pc.subcat,
pc.maintenance
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--check for duplicates in pk
select prd_key, count(*) from (
SELECT 
pn.prd_id,
pn.prd_key,
pn.prd_nm,
pn.cat_id,
pc.cat,
pc.subcat,
pc.maintenance,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)
)t group by prd_key
having count(*) >1

--sort the col into logical gps to improve readability

SELECT 
pn.prd_id,
pn.prd_key,
pn.prd_nm,
pn.cat_id,
pc.cat,
pc.subcat,
pc.maintenance,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--rename col to friendly , meaningful names

SELECT 
pn.prd_id as product_id,
pn.prd_key as product_number,
pn.prd_nm as product_name,
pn.cat_id as category_id,
pc.cat as category,
pc.subcat as subcategory,
pc.maintenance ,
pn.prd_cost as cost,
pn.prd_line as product_line,
pn.prd_start_dt as start_date
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--create pk
select
   ROW_NUMBER() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
    pn.prd_id as product_id,
    pn.prd_key as product_number,
    pn.prd_nm as product_name,
    pn.cat_id as category_id,
    pc.cat as category,
    pc.subcat as subcategory,
    pc.maintenance ,
    pn.prd_cost as cost,
    pn.prd_line as product_line,
    pn.prd_start_dt as start_date
    FROM rsilver.crm_pred_info pn
    left join rsilver.erp_px_cat_g1v2 pc
    on pn.cat_id = pc.id
    where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--build the view
create view rgold.dim_products as
select
   ROW_NUMBER() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
    pn.prd_id as product_id,
    pn.prd_key as product_number,
    pn.prd_nm as product_name,
    pn.cat_id as category_id,
    pc.cat as category,
    pc.subcat as subcategory,
    pc.maintenance ,
    pn.prd_cost as cost,
    pn.prd_line as product_line,
    pn.prd_start_dt as start_date
    FROM rsilver.crm_pred_info pn
    left join rsilver.erp_px_cat_g1v2 pc
    on pn.cat_id = pc.id
    where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

/*==================================
create dim_products
===================================*/
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt
FROM rsilver.crm_pred_info pn

--we dont need historical information (end_date) bec always null
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pc.cat,
pc.subcat,
pc.maintenance
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--check for duplicates in pk
select prd_key, count(*) from (
SELECT 
pn.prd_id,
pn.prd_key,
pn.prd_nm,
pn.cat_id,
pc.cat,
pc.subcat,
pc.maintenance,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)
)t group by prd_key
having count(*) >1

--sort the col into logical gps to improve readability

SELECT 
pn.prd_id,
pn.prd_key,
pn.prd_nm,
pn.cat_id,
pc.cat,
pc.subcat,
pc.maintenance,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--rename col to friendly , meaningful names

SELECT 
pn.prd_id as product_id,
pn.prd_key as product_number,
pn.prd_nm as product_name,
pn.cat_id as category_id,
pc.cat as category,
pc.subcat as subcategory,
pc.maintenance ,
pn.prd_cost as cost,
pn.prd_line as product_line,
pn.prd_start_dt as start_date
FROM rsilver.crm_pred_info pn
left join rsilver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--create pk
select
   ROW_NUMBER() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
    pn.prd_id as product_id,
    pn.prd_key as product_number,
    pn.prd_nm as product_name,
    pn.cat_id as category_id,
    pc.cat as category,
    pc.subcat as subcategory,
    pc.maintenance ,
    pn.prd_cost as cost,
    pn.prd_line as product_line,
    pn.prd_start_dt as start_date
    FROM rsilver.crm_pred_info pn
    left join rsilver.erp_px_cat_g1v2 pc
    on pn.cat_id = pc.id
    where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

--build the view
create view rgold.dim_products as
select
   ROW_NUMBER() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
    pn.prd_id as product_id,
    pn.prd_key as product_number,
    pn.prd_nm as product_name,
    pn.cat_id as category_id,
    pc.cat as category,
    pc.subcat as subcategory,
    pc.maintenance ,
    pn.prd_cost as cost,
    pn.prd_line as product_line,
    pn.prd_start_dt as start_date
    FROM rsilver.crm_pred_info pn
    left join rsilver.erp_px_cat_g1v2 pc
    on pn.cat_id = pc.id
    where prd_end_dt is null --filter out all historical data(remove all nulls from enddate)

/*=================================================================================
quality check for 'rgold.fact_sales'
===================================================================================
*/

--fact check :checks if all dimensions tables can successfully
--to the fact table
-- forign key integrity(dimensions):if all dimensions tables can
--successfully join to the fact table(join with dim_cust)
--expectation: no data
select *
from rgold.fact_sales f
left join rgold.dim_customer c
on c.customer_key = f.customer_key
where c.customer_key is null

--check for joining with dim_product
select *
from rgold.fact_sales f
left join rgold.dim_products p
on p.product_key = f.product_key
where p.product_key is null

--building fact:use the dimensionn pk insted of ids to easily connect fact(no.)
--from silver layer with dimesions from gold layer by replacing
--originAL ids from silver layer by new pk(suurogate key from gold
--layer

SELECT
sd.sls_ord_num,
pr.product_key,
cu.customer_key,
sd.sls_order_dt,
sd.sls_ship_dt,
sd.sls_due_dt,
sd.sls_sales,
sd.sls_quantity,
sd.sls_price
from rsilver.crm_sales_details sd
left join rgold.dim_products pr
on sd.sls_prd_key = pr.product_number
left join rgold.dim_customer cu
on sd.sls_cust_id = cu.customer_id

--rename columns to friendly ,meaningful names
--sort the col into logigal groups to improve readability
--order : dim_key,date,measure

SELECT
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as shippping_date,
sd.sls_due_dt as due_date,
sd.sls_sales as sales_amount,
sd.sls_quantity as sales_quantity,
sd.sls_price
from rsilver.crm_sales_details sd
left join rgold.dim_products pr
on sd.sls_prd_key = pr.product_number
left join rgold.dim_customer cu
on sd.sls_cust_id = cu.customer_id

--create view
create view rgold.fact_sales as
SELECT
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as shippping_date,
sd.sls_due_dt as due_date,
sd.sls_sales as sales_amount,
sd.sls_quantity as sales_quantity,
sd.sls_price
from rsilver.crm_sales_details sd
left join rgold.dim_products pr
on sd.sls_prd_key = pr.product_number
left join rgold.dim_customer cu
on sd.sls_cust_id = cu.customer_id

/*
===========================================================================================
ddl script : create gold views
===========================================================================================
script purpose:
      this script creats views for the gold layer in the data warehouse.
      the gold layer represents the final dimensions and fact tables(star schema)

      each view performs transformations and combines data from the silver layer
      to produce a clean , enriched, and business ready dataset.

usage:
     - these views can be queried directly for analytics and reporting.
============================================================================================
*/


--==========================================================================================
-- create dimensions : gold.dim_customer
--==========================================================================================
if object_id('rgold.dim_customer', 'v') is not null
   drop view rgold.dim_customer;
go

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

 go
--==========================================================================================
-- create dimensions : rgold.dim_products
--==========================================================================================
if object_id('rgold.dim_products', 'v') is not null
   drop view rgold.dim_products;
go

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
go
--==========================================================================================
-- create dimensions : rgold.fact_sales
--==========================================================================================
if object_id('rgold.fact_sales', 'v') is not null
   drop view rgold.fact_sales;
go


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

go

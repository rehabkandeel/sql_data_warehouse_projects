/*
================================================================================
Stored Procedure : Load SILVER Layer (bronze -> silver)
================================================================================
Script Purpose:
	This stored procedure performs the elt(extract,transform,load) process to populate the 'rsilver' schema 
 table from the 'bronze' schema.
	Actions Performed:
		-Truncate silver tables.
		-inserts transformed and cleaned data from bronze into silver tables.

		parameters:
			None.
		  This stored procedure doesnot accept any parameters or return any values.

		Usage Examlpes:
		    EXEC rsilver.load_rsilver;
==================================================================================
*/
EXEC rsilver.load_rsilver
CREATE OR ALTER PROCEDURE rsilver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time datetime, @batch_end_time datetime;
    --ADD TRY..CATCH :ENSURE ERROR HANDLING,DATA INTEGRITY
	--AND ISSUE LOGGING FOR EASY DEBUGGING
	BEGIN TRY
		set @batch_start_time = GETDATE();
		print '=========================================';
		print 'Loading Bronze Layer' ;
		print '=========================================';

		print '_________________________________________';
		print 'Loading CRM TABLE'  ;
		print '_________________________________________';


        --loading silver.crm_cust_info
        set @start_time = GETDATE();
        print'>> truncating tables  : rsilver.crm_cust_info';
        truncate table rsilver.crm_cust_info ;
        print '>>  insertintg data into : rsilver.crm_cust_info' ;
        insert into rsilver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
             cst_gender,
             cst_create_date
        )
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
            )t 
            WHERE flag_last = 1
            set @end_time = GETDATE()
            print '>>load duration ;' +cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds'
            print '>>---------------';

            --loading rsilver.crm_sales_details
            set @start_time = GETDATE();
            print'>> truncating tables  :rsilver.crm_sales_details';
            truncate table rsilver.crm_sales_details  ;
            print '>>  insertintg data into : rsilver.crm_sales_details' ;
            insert into rsilver.crm_sales_details (
            sls_ord_num ,
            sls_prd_key ,
            sls_cust_id ,
            sls_order_dt ,
            sls_ship_dt  ,
            sls_due_dt  ,
            sls_sales   ,
            sls_quantity  ,
            sls_price  
            )
            SELECT  
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,
                case when sls_order_dt =0 or len(sls_order_dt) != 8 then null
                          else  cast(cast(sls_order_dt as varchar) as date) --in sql we had to convert int to varchar 
                --then to date
                end as sls_order_dt,

                case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
                          else  cast(cast(sls_ship_dt as varchar) as date) 
                end as sls_ship_dt,

                case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
                          else  cast(cast(sls_due_dt as varchar) as date) 
                end as sls_due_dt,

                case when sls_sales is null or sls_sales <= 0 
                          or sls_sales != sls_quantity * abs(sls_price)
                          then sls_quantity * abs(sls_price)
                      else sls_sales
                end as sls_sales,

                sls_quantity,


                case when sls_price is null or sls_price <=0
                         then sls_sales / nullif(sls_quantity ,0)
                     else sls_price
                end as sls_price 

            FROM rbronze.crm_sales_details
            set @end_time = GETDATE()
            print '>>load duration ;' +cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds'
            print '>>---------------';

            set @start_time = GETDATE()
            print'>> truncating tables  : rsilver.crm_pred_info'
            truncate table rsilver.crm_pred_info ;
            print '>>  insertintg data into : rsilver.crm_pred_info'

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

                     cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt_test
                  FROM rbronze.crm_pred_info -- calculate end date as one day before the next start date
                  set @end_time = GETDATE()
                  print '>>load duration ;' +cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds'
                  print '>>---------------';

                  truncate table rsilver.erp_loc_a101 ;
                  print '>>  insertintg data into : rsilver.erp_loc_a101'
                  insert into rsilver.erp_loc_a101
                  (cid,cntry)
                   select
                       replace(cid,'-','') cid,
                       case when trim(cntry) = 'DE' then 'GERMANY'
                       WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
                       when trim (cntry) = '' OR cntry IS NULL THEN 'N/A'
                       ELSE cntry
                       end as cntry
                   from rbronze.erp_loc_a101
                   set @end_time = GETDATE()
                   print '>>load duration ;' +cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds'
                   print '>>---------------';

                   set @start_time = GETDATE()
                   print'>> truncating tables : rsilver.erp_cust_az12'
                   truncate table rsilver.erp_cust_az12  ;
                   print '>>  insertintg data into : rsilver.erp_cust_az12 '
                   insert into rsilver.erp_cust_az12 (
                   cid,
                   bdate,
                   gen
                   )

                    select
                        case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid)) --remove 'nas' prefix 
                              else cid
                         end as cid,
                         case when bdate > GETDATE() then null
                              else bdate
                         end as bdate, --set future date to nulll
                         case when upper(trim(gen)) in ('F', 'FEMALE') THEN 'FEMALE'
                              WHEN UPPER(TRIM(gen)) in ('M', 'MALE') THEN 'MALE'
                              ELSE 'N/A'
                        END AS gen -- normalize gender value and handle unkown cases
                    from rbronze.erp_cust_az12
                    set @end_time = GETDATE()
                    print '>>load duration ;' +cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds'
                    print '>>---------------';

                    set @start_time = GETDATE()
                    print'>> truncating tables : rsilver.erp_px_cat_g1v2'
                    truncate table rsilver.erp_px_cat_g1v2;
                    print '>>  insertintg data into : rsilver.erp_px_cat_g1v2'
                    insert into rsilver.erp_px_cat_g1v2
                    (id,
                    cat,
                    subcat,
                    maintenance)

                    SELECT 
                        id,
                        cat,
                        subcat,
                        maintenance
                    FROM rbronze.erp_px_cat_g1v2;
                    set @end_time = GETDATE();
	                PRINT '>>LOADING DURATION : ' + cast(datediff(second, @start_time ,@end_time) as nvarchar) + 'seconds' ;
	                print '>>__________________'

	                set @batch_end_time = getdate();
                    PRINT'========================================';
	                print' loading SILVER layer is completed';
	                print ' TOTAL LOAD DURATION :'+ CAST(DATEDIFF(second, @batch_start_time,@batch_end_time ) as nvarchar) + 'secondas';
	                PRINT'========================================';

           END TRY 
	       BEGIN CATCH
		        PRINT'========================================';
		        PRINT'ERROR OCCURED DURING LOADING SILVEWR LAYER';
		        PRINT'ERROR MEASSAGE' + ERROR_MESSAGE();
		        PRINT'ERROR MESSAGE' + CAST (ERROR_NUMBER() AS NVARCHAR);
		        PRINT'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
		        PRINT'========================================';
	       END CATCH
       end


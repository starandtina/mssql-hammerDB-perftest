-- 5.3.13.4 DM_C
CREATE view custv as
SELECT 	c_customer_sk,
	cust_customer_id c_customer_id,
	cd_demo_sk c_current_cdemo_sk,
	hd_demo_sk c_current_hdemo_sk,
	ca_address_sk, c_current_addr_sk,
	d1.d_date_sk c_first_shipto_date_sk,
	d2.d_date_sk c_first_sales_date_sk,
	cust_salutation c_calutation,
	cust_first_name c_first_name,
	cust_last_name c_last_name,
	cust_preferred_flag  c_preferred_cust_flag,
	DATEPART(dd, cust_birth_date) c_birth_day,
	DATEPART(mm, cust_birth_date) c_birth_month,
	DATEPART(yyyy, cust_birth_date) c_birth_year,
--	extract(day FROM cast(cust_birth_date as date)) c_birth_day,
--	extract(month FROM cast(cust_birth_date as date)) c_birth_month,
--	extract(year FROM cast(cust_burth_date as date)) c_birth_year,
	cust_birth_country c_birth_coutry,
	cust_login_id c_login,
	cust_email_address c_email_address,
	cust_last_review_date c_last_review_date
FROM	s_customer
LEFT OUTER JOIN customer on (c_customer_id= cust_customer_id)
LEFT OUTER JOIN customer_address 
	on 	(c_current_addr_sk = ca_address_sk),
		customer_demographics,
		household_demographics,
		income_band ib,
		date_dim d1,
		date_dim d2
WHERE	cust_gender = cd_gender
AND cust_marital_status = cd_marital_status
AND cust_educ_status = cd_education_status
AND cust_purch_est = cd_purchase_estimate
AND cust_credit_rating = cd_credit_rating
AND cust_depend_cnt = cd_dep_count
AND cust_depend_emp_cnt = cd_dep_employed_count
AND cust_depend_college_cnt = cd_dep_college_count
AND round(cust_annual_income, 0) between ib.ib_lower_bound and ib.ib_upper_bound
AND hd_income_band_sk = ib_income_band_sk
AND cust_buy_potential = hd_dep_count
AND cust_depend_cnt = hd_dep_count
AND cust_vehicle_cnt = hd_vehicle_count
AND d1.d_date = cust_first_purchase_date
AND d2.d_date = cust_first_shipto_date
-- HAMMERORA GO

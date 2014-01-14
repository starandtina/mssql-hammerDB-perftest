-- 5.3.13.3 DM_CA
CREATE VIEW cadrv AS
SELECT 	ca_address_sk,
	ca_address_id,
	cust_street_number ca_street_number,
	rtrim(cust_street_name1) + ' ' + rtrim(cust_street_name2) ca_street_name,
	cust_street_type ca_street_type,
	cust_suite_number ca_suite_number,
	cust_city ca_city,
	cust_county ca_county,
	cust_state ca_state,
	cust_zip ca_zip,
	cust_country ca_country,
	zipg_gmt_offset ca_gmt_offset,
	cust_loc_type caLocation_type
FROM 	s_customer, 
	customer customer,
	customer_address cat,
	s_zip_to_gmt
WHERE	cust_customer_id = c_customer_id
AND	c_current_addr_sk = ca_address_sk
AND	cust_zip = zipg_zip
-- HAMMERORA GO

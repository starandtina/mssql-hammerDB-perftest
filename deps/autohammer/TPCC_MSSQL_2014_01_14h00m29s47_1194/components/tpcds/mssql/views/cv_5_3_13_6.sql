-- 5.3.13.6 DM_CC
CREATE VIEW ccs AS
SELECT
--    cc_seq cc_call_center_sk,
	call_center_id cc_call_center_id,
	GETDATE() cc_rec_start_date,
	cast(NULL AS DATE) cc_rec_end_date,
	d1.d_date_sk cc_closed_date_sk,
	d2.d_date_sk cc_open_date_sk,
	call_center_name cc_name,
	call_center_class ccclass,
	call_center_employees cc_employees,
	call_center_sq_ft cc_sq_ft,
	call_center_hours cc_hours,
	call_center_manager ccmanager,
	cc_mkt_id,
	cc_mkt_class,
	cc_mkt_desc,
	cc_market_manager,
	cc_division,
	cc_division_name,
	cc_company,
	cc_company_name,
	cc_street_number,cc_street_name,cc_street_type, cc_suite_number, cc_city,
	cc_county, cc_state, cc_zip,
	cc_country,
	cc_gmt_offset,
	call_center_tax_percentage cc_tax_percentage
FROM s_call_center
LEFT OUTER JOIN date_dim d2 ON d2.d_date = cast(call_closed_date AS DATE)
LEFT OUTER JOIN date_dim d1 on d1.d_date = cast(call_open_date AS DATE)
LEFT OUTER JOIN call_center ON  cc_rec_end_date IS NULL
-- LEFT OUTER JOIN call_center ON (call_center_id = cc_call_center_id AND cc_rec_end_date IS NULL)
-- HAMMERORA GO

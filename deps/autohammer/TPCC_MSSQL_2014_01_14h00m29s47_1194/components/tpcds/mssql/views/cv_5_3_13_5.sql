-- 5.3.13.5 DM_W
CREATE VIEW wrhsv AS
SELECT	w_warehouse_sk,
	wrhs_warehouse_id w_warehouse_id,
	wrhs_warehouse_desc w_warehouse_name,
	wrhs_warehouse_sq_ft w_warehouse_sq_ft,
	w_street_number,
	w_street_name,
	w_street_type,
	w_suite_number,
	w_city,
	w_county,
	w_state,
	w_zip,
	w_country,
	w_gmt_offset
FROM	s_warehouse,
	warehouse
WHERE	wrhs_warehouse_id = w_warehouse_id
-- HAMMERORA GO

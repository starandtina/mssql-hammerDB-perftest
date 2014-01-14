-- 5.3.13.1 DM_S
CREATE VIEW storv AS
SELECT
	stor_store_id s_store_id,
	GETDATE() s_rec_start_date,
	cast(NULL as datetime) s_rec_end_date,
	dl.d_date_sk s_closed_date_sk,
	stor_name _store_name,
	stor_employees s_number_employees,
	stor_floor_space s_floor_space,
	stor_hours s_hours,
	stor_store_manager s_manager,
	stor_market_id s_market_id,
	stor_geography_class s_geography_class,
	s_market_desc,
	stor_market_manager s_market_manager,
	s_division_id,
	s_division_name,
	s_company_id,
	s_company_name,
	s_street_number,
	s_street_name,
	s_street_type,
	s_suite_number,
	s_city,
	s_county,
	s_state,
	s_zip,
	s_country,
	s_gmt_offset,
	stor_tax_percentage s_tax_percentage
FROM s_store
	LEFT OUTER JOIN store
	ON (stor_store_id = s_store_id AND s_rec_end_date is NULL)
	LEFT OUTER JOIN date_dim dl ON (cast(s_closed_date_sk as datetime) = dl.d_date)
-- HAMMERORA GO

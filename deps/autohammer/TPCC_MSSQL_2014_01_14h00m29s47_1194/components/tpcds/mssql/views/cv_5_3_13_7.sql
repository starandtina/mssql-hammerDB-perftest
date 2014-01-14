-- 5.3.13.7 DM_CP
CREATE VIEW catv AS
SELECT	cp_catalog_page_sk,
	scp.cpag_id cp_catalog_page_id,
	startd.d_date_sk cp_start_date_sk,
	endd.d_date_sk cp_end_date_sk,
	cpag_department cp_department,
	cpag_catalog_number cp_catalog_number,
	cpag_catalog_page_number cp_catalog_page_number,
	scp.cpag_description cp_description,
	scp.cpag_type cp_type
FROM	s_catalog_page scp
INNER JOIN date_dim startd ON (scp.cpag_start_date = startd.d_date)
INNER JOIN date_dim endd ON (scp.cpag_end_date = endd.d_date)
INNER JOIN catalog_page cp ON (scp.cpag_id = cp.cp_catalog_page_id)
-- HAMMERORA GO

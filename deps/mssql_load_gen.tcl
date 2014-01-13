#!/usr/local/bin/tclsh8.6
if [catch {package require tclodbc 2.5.1} ] { error "Failed to load tclodbc - ODBC Library Error" }
proc CreateStoredProcs { odbc schema } {
if { $schema != "updated" } {
#original stored procedures from SSMA
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) {CREATE PROCEDURE dbo.NEWORD  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY
SET @no_o_all_local = 0
SELECT @no_c_discount = CUSTOMER.C_DISCOUNT, @no_c_last = CUSTOMER.C_LAST, @no_c_credit = CUSTOMER.C_CREDIT, @no_w_tax = WAREHOUSE.W_TAX FROM dbo.CUSTOMER, dbo.WAREHOUSE WHERE WAREHOUSE.W_ID = @no_w_id AND CUSTOMER.C_W_ID = @no_w_id AND CUSTOMER.C_D_ID = @no_d_id AND CUSTOMER.C_ID = @no_c_id
UPDATE dbo.DISTRICT SET @no_d_tax = d_tax, @o_id = D_NEXT_O_ID,  D_NEXT_O_ID = DISTRICT.D_NEXT_O_ID + 1 WHERE DISTRICT.D_ID = @no_d_id AND DISTRICT.D_W_ID = @no_w_id
INSERT dbo.ORDERS( O_ID, O_D_ID, O_W_ID, O_C_ID, O_ENTRY_D, O_OL_CNT, O_ALL_LOCAL) VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)
INSERT dbo.NEW_ORDER(NO_O_ID, NO_D_ID, NO_W_ID) VALUES (@o_id, @no_d_id, @no_w_id)
SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)
SELECT @no_i_price = ITEM.I_PRICE, @no_i_name = ITEM.I_NAME, @no_i_data = ITEM.I_DATA FROM dbo.ITEM WHERE ITEM.I_ID = @no_ol_i_id
SELECT @no_s_quantity = STOCK.S_QUANTITY, @no_s_data = STOCK.S_DATA, @no_s_dist_01 = STOCK.S_DIST_01, @no_s_dist_02 = STOCK.S_DIST_02, @no_s_dist_03 = STOCK.S_DIST_03, @no_s_dist_04 = STOCK.S_DIST_04, @no_s_dist_05 = STOCK.S_DIST_05, @no_s_dist_06 = STOCK.S_DIST_06, @no_s_dist_07 = STOCK.S_DIST_07, @no_s_dist_08 = STOCK.S_DIST_08, @no_s_dist_09 = STOCK.S_DIST_09, @no_s_dist_10 = STOCK.S_DIST_10 FROM dbo.STOCK WHERE STOCK.S_I_ID = @no_ol_i_id AND STOCK.S_W_ID = @no_ol_supply_w_id
IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)
UPDATE dbo.STOCK SET S_QUANTITY = @no_s_quantity WHERE STOCK.S_I_ID = @no_ol_i_id AND STOCK.S_W_ID = @no_ol_supply_w_id
SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.ORDER_LINE( OL_O_ID, OL_D_ID, OL_W_ID, OL_NUMBER, OL_I_ID, OL_SUPPLY_W_ID, OL_QUANTITY, OL_AMOUNT, OL_DIST_INFO) VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(2) {CREATE PROCEDURE dbo.DELIVERY  
@d_w_id int,
@d_o_carrier_id int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter
SELECT TOP (1) @d_no_o_id = NEW_ORDER.NO_O_ID FROM dbo.NEW_ORDER WITH (serializable updlock) WHERE  NEW_ORDER.NO_W_ID = @d_w_id AND NEW_ORDER.NO_D_ID = @d_d_id
DELETE dbo.NEW_ORDER WHERE NEW_ORDER.NO_W_ID = @d_w_id AND NEW_ORDER.NO_D_ID = @d_d_id AND NEW_ORDER.NO_O_ID =  @d_no_o_id
SELECT @d_c_id = ORDERS.O_C_ID FROM dbo.ORDERS WHERE ORDERS.O_ID = @d_no_o_id AND ORDERS.O_D_ID = @d_d_id AND ORDERS.O_W_ID = @d_w_id
UPDATE dbo.ORDERS SET O_CARRIER_ID = @d_o_carrier_id WHERE ORDERS.O_ID = @d_no_o_id AND ORDERS.O_D_ID = @d_d_id AND ORDERS.O_W_ID = @d_w_id
UPDATE dbo.ORDER_LINE SET OL_DELIVERY_D = @TIMESTAMP WHERE ORDER_LINE.OL_O_ID = @d_no_o_id AND ORDER_LINE.OL_D_ID = @d_d_id AND ORDER_LINE.OL_W_ID = @d_w_id
SELECT @d_ol_total = sum(ORDER_LINE.OL_AMOUNT) FROM dbo.ORDER_LINE WHERE ORDER_LINE.OL_O_ID = @d_no_o_id AND ORDER_LINE.OL_D_ID = @d_d_id AND ORDER_LINE.OL_W_ID = @d_w_id
UPDATE dbo.CUSTOMER SET C_BALANCE = CUSTOMER.C_BALANCE + @d_ol_total WHERE CUSTOMER.C_ID = @d_c_id AND CUSTOMER.C_D_ID = @d_d_id AND CUSTOMER.C_W_ID = @d_w_id
IF @@TRANCOUNT > 0
COMMIT WORK 
PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(max)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(max)), '')
+ 
'time '
+ 
ISNULL(CAST(@TIMESTAMP AS nvarchar(max)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT  @d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @TIMESTAMP as N'@TIMESTAMP'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE dbo.PAYMENT  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY
UPDATE dbo.WAREHOUSE SET W_YTD = WAREHOUSE.W_YTD + @p_h_amount WHERE WAREHOUSE.W_ID = @p_w_id
SELECT @p_w_street_1 = WAREHOUSE.W_STREET_1, @p_w_street_2 = WAREHOUSE.W_STREET_2, @p_w_city = WAREHOUSE.W_CITY, @p_w_state = WAREHOUSE.W_STATE, @p_w_zip = WAREHOUSE.W_ZIP, @p_w_name = WAREHOUSE.W_NAME FROM dbo.WAREHOUSE WHERE WAREHOUSE.W_ID = @p_w_id
UPDATE dbo.DISTRICT SET D_YTD = DISTRICT.D_YTD + @p_h_amount WHERE DISTRICT.D_W_ID = @p_w_id AND DISTRICT.D_ID = @p_d_id
SELECT @p_d_street_1 = DISTRICT.D_STREET_1, @p_d_street_2 = DISTRICT.D_STREET_2, @p_d_city = DISTRICT.D_CITY, @p_d_state = DISTRICT.D_STATE, @p_d_zip = DISTRICT.D_ZIP, @p_d_name = DISTRICT.D_NAME FROM dbo.DISTRICT WHERE DISTRICT.D_W_ID = @p_w_id AND DISTRICT.D_ID = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(CUSTOMER.C_ID) FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_LAST = @p_c_last AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_W_ID = @p_c_w_id
DECLARE
c_byname CURSOR LOCAL FOR 
SELECT CUSTOMER.C_FIRST, CUSTOMER.C_MIDDLE, CUSTOMER.C_ID, CUSTOMER.C_STREET_1, CUSTOMER.C_STREET_2, CUSTOMER.C_CITY, CUSTOMER.C_STATE, CUSTOMER.C_ZIP, CUSTOMER.C_PHONE, CUSTOMER.C_CREDIT, CUSTOMER.C_CREDIT_LIM, CUSTOMER.C_DISCOUNT, CUSTOMER.C_BALANCE, CUSTOMER.C_SINCE FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_LAST = @p_c_last ORDER BY CUSTOMER.C_FIRST
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = CUSTOMER.C_FIRST, @p_c_middle = CUSTOMER.C_MIDDLE, @p_c_last = CUSTOMER.C_LAST, @p_c_street_1 = CUSTOMER.C_STREET_1, @p_c_street_2 = CUSTOMER.C_STREET_2, @p_c_city = CUSTOMER.C_CITY, @p_c_state = CUSTOMER.C_STATE, @p_c_zip = CUSTOMER.C_ZIP, @p_c_phone = CUSTOMER.C_PHONE, @p_c_credit = CUSTOMER.C_CREDIT, @p_c_credit_lim = CUSTOMER.C_CREDIT_LIM, @p_c_discount = CUSTOMER.C_DISCOUNT, @p_c_balance = CUSTOMER.C_BALANCE, @p_c_since = CUSTOMER.C_SINCE FROM dbo.CUSTOMER WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id 
END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = CUSTOMER.C_DATA FROM dbo.CUSTOMER WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.CUSTOMER SET C_BALANCE = @p_c_balance, C_DATA = @p_c_new_data WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
END
ELSE 
UPDATE dbo.CUSTOMER SET C_BALANCE = @p_c_balance WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
INSERT dbo.HISTORY( H_C_D_ID, H_C_W_ID, H_C_ID, H_D_ID, H_W_ID, H_DATE, H_AMOUNT, H_DATA) VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT  @p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1', @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city', @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip', @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2', @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state', @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first', @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1', @p_c_street_2 as N'@p_c_street_2', @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip', @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit', @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance', @p_c_data as N'@p_c_data'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE dbo.OSTAT 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id     INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount   INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN
SELECT @namecnt = count_big(CUSTOMER.C_ID) FROM dbo.CUSTOMER WHERE CUSTOMER.C_LAST = @os_c_last AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT CUSTOMER.C_BALANCE, CUSTOMER.C_FIRST, CUSTOMER.C_MIDDLE, CUSTOMER.C_ID FROM dbo.CUSTOMER WHERE CUSTOMER.C_LAST = @os_c_last AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id ORDER BY CUSTOMER.C_FIRST
OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = CUSTOMER.C_BALANCE, @os_c_first = CUSTOMER.C_FIRST, @os_c_middle = CUSTOMER.C_MIDDLE, @os_c_last = CUSTOMER.C_LAST FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_ID = @os_c_id AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.O_ID, @os_o_carrier_id = fci.O_CARRIER_ID, @os_entdate = fci.O_ENTRY_D
FROM 
(SELECT TOP 9223372036854775807 ORDERS.O_ID, ORDERS.O_CARRIER_ID, ORDERS.O_ENTRY_D FROM dbo.ORDERS WITH (serializable) WHERE ORDERS.O_D_ID = @os_d_id AND ORDERS.O_W_ID = @os_w_id AND ORDERS.O_C_ID = @os_c_id ORDER BY ORDERS.O_ID DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT ORDER_LINE.OL_I_ID, ORDER_LINE.OL_SUPPLY_W_ID, ORDER_LINE.OL_QUANTITY, ORDER_LINE.OL_AMOUNT, ORDER_LINE.OL_DELIVERY_D FROM dbo.ORDER_LINE WITH (repeatableread) WHERE ORDER_LINE.OL_O_ID = @os_o_id AND ORDER_LINE.OL_D_ID = @os_d_id AND ORDER_LINE.OL_W_ID = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT  @os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE dbo.SLEV  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY
SELECT @st_o_id = DISTRICT.D_NEXT_O_ID FROM dbo.DISTRICT WHERE DISTRICT.D_W_ID = @st_w_id AND DISTRICT.D_ID = @st_d_id
SELECT @stock_count = count_big(DISTINCT STOCK.S_I_ID) FROM dbo.ORDER_LINE, dbo.STOCK WHERE ORDER_LINE.OL_W_ID = @st_w_id AND ORDER_LINE.OL_D_ID = @st_d_id AND (ORDER_LINE.OL_O_ID < @st_o_id) AND ORDER_LINE.OL_O_ID >= (@st_o_id - 20) AND STOCK.S_W_ID = @st_w_id AND STOCK.S_I_ID = ORDER_LINE.OL_I_ID AND STOCK.S_QUANTITY < @threshold
SELECT  @st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
for { set i 1 } { $i <= 5 } { incr i } {
odbc  $sql($i)
        }
return
    } else {
#Updated stored procedures provided by Thomas Kejser
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) {CREATE PROCEDURE [dbo].[NEWORD]  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY

SET @no_o_all_local = 0
SELECT @no_c_discount = CUSTOMER.c_discount
, @no_c_last = CUSTOMER.c_last
, @no_c_credit = CUSTOMER.c_credit
, @no_w_tax = WAREHOUSE.w_tax 
FROM dbo.CUSTOMER, dbo.WAREHOUSE WITH (INDEX = W_Details)
WHERE WAREHOUSE.w_id = @no_w_id 
AND CUSTOMER.c_w_id = @no_w_id 
AND CUSTOMER.c_d_id = @no_d_id 
AND CUSTOMER.c_id = @no_c_id

UPDATE dbo.DISTRICT 
SET @no_d_tax = d_tax
, @o_id = d_next_o_id
,  d_next_o_id = DISTRICT.d_next_o_id + 1 
WHERE DISTRICT.d_id = @no_d_id 
AND DISTRICT.d_w_id = @no_w_id

INSERT dbo.ORDERS( o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)

INSERT dbo.NEW_ORDER(no_o_id, no_d_id, no_w_id) 
VALUES (@o_id, @no_d_id, @no_w_id)

SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)

SELECT @no_i_price = ITEM.i_price
, @no_i_name = ITEM.i_name
, @no_i_data = ITEM.i_data 
FROM dbo.ITEM 
WHERE ITEM.i_id = @no_ol_i_id

SELECT @no_s_quantity = STOCK.s_quantity
, @no_s_data = STOCK.s_data
, @no_s_dist_01 = STOCK.s_dist_01
, @no_s_dist_02 = STOCK.s_dist_02
, @no_s_dist_03 = STOCK.s_dist_03
, @no_s_dist_04 = STOCK.s_dist_04
, @no_s_dist_05 = STOCK.s_dist_05
, @no_s_dist_06 = STOCK.s_dist_06
, @no_s_dist_07 = STOCK.s_dist_07
, @no_s_dist_08 = STOCK.s_dist_08
, @no_s_dist_09 = STOCK.s_dist_09
, @no_s_dist_10 = STOCK.s_dist_10 
FROM dbo.STOCK
WHERE STOCK.s_i_id = @no_ol_i_id 
AND STOCK.s_w_id = @no_ol_supply_w_id


IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)

UPDATE dbo.STOCK
SET s_quantity = @no_s_quantity 
WHERE STOCK.s_i_id = @no_ol_i_id 
AND STOCK.s_w_id = @no_ol_supply_w_id

SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.ORDER_LINE( ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;

END}
set sql(2) {CREATE PROCEDURE [dbo].[DELIVERY]  
@d_w_id int,
@d_o_carrier_id int,
@timestamp datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter


DECLARE @d_out TABLE (d_no_o_id INT)

DELETE TOP (1) 
FROM dbo.NEW_ORDER 
OUTPUT deleted.no_o_id INTO @d_out -- @d_no_o_id
WHERE NEW_ORDER.no_w_id = @d_w_id 
AND NEW_ORDER.no_d_id = @d_d_id 
AND NEW_ORDER.no_o_id =  @d_no_o_id

SELECT @d_no_o_id = d_no_o_id FROM @d_out
 

UPDATE dbo.ORDERS 
SET o_carrier_id = @d_o_carrier_id 
, @d_c_id = ORDERS.o_c_id 
WHERE ORDERS.o_id = @d_no_o_id 
AND ORDERS.o_d_id = @d_d_id 
AND ORDERS.o_w_id = @d_w_id


 SET @d_ol_total = 0

UPDATE dbo.ORDER_LINE 
SET ol_delivery_d = @timestamp
    , @d_ol_total = @d_ol_total + ol_amount
WHERE ORDER_LINE.ol_o_id = @d_no_o_id 
AND ORDER_LINE.ol_d_id = @d_d_id 
AND ORDER_LINE.ol_w_id = @d_w_id


UPDATE dbo.CUSTOMER SET c_balance = CUSTOMER.c_balance + @d_ol_total 
WHERE CUSTOMER.c_id = @d_c_id 
AND CUSTOMER.c_d_id = @d_d_id 
AND CUSTOMER.c_w_id = @d_w_id


PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(4000)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(4000)), '')
+ 
'time '
+ 
ISNULL(CAST(@timestamp AS nvarchar(4000)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT  @d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @timestamp as N'@TIMESTAMP'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE [dbo].[PAYMENT]  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY

SELECT @p_w_street_1 = WAREHOUSE.w_street_1
, @p_w_street_2 = WAREHOUSE.w_street_2
, @p_w_city = WAREHOUSE.w_city
, @p_w_state = WAREHOUSE.w_state
, @p_w_zip = WAREHOUSE.w_zip
, @p_w_name = WAREHOUSE.w_name 
FROM dbo.WAREHOUSE WITH (INDEX = [W_Details])
WHERE WAREHOUSE.w_id = @p_w_id

UPDATE dbo.DISTRICT 
SET d_ytd = DISTRICT.d_ytd + @p_h_amount 
WHERE DISTRICT.d_w_id = @p_w_id 
AND DISTRICT.d_id = @p_d_id

SELECT @p_d_street_1 = DISTRICT.d_street_1
, @p_d_street_2 = DISTRICT.d_street_2
, @p_d_city = DISTRICT.d_city
, @p_d_state = DISTRICT.d_state
, @p_d_zip = DISTRICT.d_zip
, @p_d_name = DISTRICT.d_name 
FROM dbo.DISTRICT WITH (INDEX = D_Details)
WHERE DISTRICT.d_w_id = @p_w_id 
AND DISTRICT.d_id = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(CUSTOMER.c_id) 
FROM dbo.CUSTOMER WITH (repeatableread) 
WHERE CUSTOMER.c_last = @p_c_last 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_w_id = @p_c_w_id

DECLARE
c_byname CURSOR STATIC LOCAL FOR 
SELECT CUSTOMER.c_first
, CUSTOMER.c_middle
, CUSTOMER.c_id
, CUSTOMER.c_street_1
, CUSTOMER.c_street_2
, CUSTOMER.c_city
, CUSTOMER.c_state
, CUSTOMER.c_zip
, CUSTOMER.c_phone
, CUSTOMER.c_credit
, CUSTOMER.c_credit_lim
, CUSTOMER.c_discount
, C_BAL.c_balance
, CUSTOMER.c_since 
FROM dbo.CUSTOMER  AS CUSTOMER WITH (INDEX = [CUSTOMER_I2], repeatableread)
INNER LOOP JOIN dbo.CUSTOMER AS C_BAL WITH (INDEX = [CUSTOMER_I1], repeatableread) 
ON C_BAL.c_w_id = CUSTOMER.c_w_id
  AND C_BAL.c_d_id = CUSTOMER.c_d_id
  AND C_BAL.c_id = CUSTOMER.c_id
WHERE CUSTOMER.c_w_id = @p_c_w_id 
  AND CUSTOMER.c_d_id = @p_c_d_id 
  AND CUSTOMER.c_last = @p_c_last 
ORDER BY CUSTOMER.c_first
OPTION ( MAXDOP 1)
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = CUSTOMER.c_first, @p_c_middle = CUSTOMER.c_middle, @p_c_last = CUSTOMER.c_last
, @p_c_street_1 = CUSTOMER.c_street_1, @p_c_street_2 = CUSTOMER.c_street_2
, @p_c_city = CUSTOMER.c_city, @p_c_state = CUSTOMER.c_state
, @p_c_zip = CUSTOMER.c_zip, @p_c_phone = CUSTOMER.c_phone
, @p_c_credit = CUSTOMER.c_credit, @p_c_credit_lim = CUSTOMER.c_credit_lim
, @p_c_discount = CUSTOMER.c_discount, @p_c_balance = CUSTOMER.c_balance
, @p_c_since = CUSTOMER.c_since 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_id = @p_c_id 

END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = CUSTOMER.c_data FROM dbo.CUSTOMER WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id AND CUSTOMER.c_id = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.CUSTOMER SET c_balance = @p_c_balance, c_data = @p_c_new_data 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id AND CUSTOMER.c_id = @p_c_id
END
ELSE 
UPDATE dbo.CUSTOMER SET c_balance = @p_c_balance 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_id = @p_c_id

SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))

INSERT dbo.HISTORY( h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT  @p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1'
, @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city'
, @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip'
, @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2'
, @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state'
, @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first'
, @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1'
, @p_c_street_2 as N'@p_c_street_2'
, @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip'
, @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit'
, @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance'
, @p_c_data as N'@p_c_data'


UPDATE dbo.WAREHOUSE WITH (XLOCK)
SET w_ytd = WAREHOUSE.w_ytd + @p_h_amount 
WHERE WAREHOUSE.w_id = @p_w_id

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE [dbo].[OSTAT] 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id     INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount   INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN

SELECT @namecnt = count_big(CUSTOMER.c_id) 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_last = @os_c_last AND CUSTOMER.c_d_id = @os_d_id AND CUSTOMER.c_w_id = @os_w_id

IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT CUSTOMER.c_balance
, CUSTOMER.c_first
, CUSTOMER.c_middle
, CUSTOMER.c_id 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_last = @os_c_last 
AND CUSTOMER.c_d_id = @os_d_id 
AND CUSTOMER.c_w_id = @os_w_id 
ORDER BY CUSTOMER.c_first

OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = CUSTOMER.c_balance, @os_c_first = CUSTOMER.c_first
, @os_c_middle = CUSTOMER.c_middle, @os_c_last = CUSTOMER.c_last 
FROM dbo.CUSTOMER WITH (repeatableread) 
WHERE CUSTOMER.c_id = @os_c_id AND CUSTOMER.c_d_id = @os_d_id AND CUSTOMER.c_w_id = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.o_id, @os_o_carrier_id = fci.o_carrier_id, @os_entdate = fci.o_entry_d
FROM 
(SELECT TOP 9223372036854775807 ORDERS.o_id, ORDERS.o_carrier_id, ORDERS.o_entry_d 
FROM dbo.ORDERS WITH (serializable) 
WHERE ORDERS.o_d_id = @os_d_id 
AND ORDERS.o_w_id = @os_w_id 
AND ORDERS.o_c_id = @os_c_id 
ORDER BY ORDERS.o_id DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT ORDER_LINE.ol_i_id
, ORDER_LINE.ol_supply_w_id
, ORDER_LINE.ol_quantity
, ORDER_LINE.ol_amount
, ORDER_LINE.ol_delivery_d 
FROM dbo.ORDER_LINE WITH (repeatableread) 
WHERE ORDER_LINE.ol_o_id = @os_o_id 
AND ORDER_LINE.ol_d_id = @os_d_id 
AND ORDER_LINE.ol_w_id = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT  @os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE [dbo].[SLEV]  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY

SELECT @st_o_id = DISTRICT.d_next_o_id 
FROM dbo.DISTRICT 
WHERE DISTRICT.d_w_id = @st_w_id AND DISTRICT.d_id = @st_d_id

SELECT @stock_count = count_big(DISTINCT STOCK.s_i_id) 
FROM dbo.ORDER_LINE
, dbo.STOCK
WHERE ORDER_LINE.ol_w_id = @st_w_id 
AND ORDER_LINE.ol_d_id = @st_d_id 
AND (ORDER_LINE.ol_o_id < @st_o_id) 
AND ORDER_LINE.ol_o_id >= (@st_o_id - 20) 
AND STOCK.s_w_id = @st_w_id 
AND STOCK.s_i_id = ORDER_LINE.ol_i_id 
AND STOCK.s_quantity < @threshold
OPTION (LOOP JOIN, MAXDOP 1)

SELECT  @st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
for { set i 1 } { $i <= 5 } { incr i } {
odbc  $sql($i)
        }
return
    }
}

proc UpdateStatistics { odbc db } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "USE $db"
set sql(2) "EXEC sp_updatestats"
for { set i 1 } { $i <= 2 } { incr i } {
odbc  $sql($i)
        }
return
}

proc CreateDatabase { odbc db db_data_path db_log_path} {
set table_count 0
puts "CHECKING IF DATABASE $db EXISTS"
set db_exists [ odbc "IF DB_ID('$db') is not null SELECT 1 AS res ELSE SELECT 0 AS res" ]
if { $db_exists } {
odbc "use $db"
set table_count [ odbc "select COUNT(*) from sys.tables" ]
if { $table_count == 0 } {
puts "Empty database $db exists"
puts "Using existing empty Database $db for Schema build"
        } else {
puts "Database with tables $db exists"
error "Database $db exists but is not empty, specify a new or empty database name"
        }
} else {
puts "CREATING DATABASE $db"
odbc "CREATE DATABASE $db CONTAINMENT = PARTIAL ON  PRIMARY ( NAME = N'$db', FILENAME = N'${db_data_path}\\${db}.mdf')LOG ON ( NAME = N'${db}_log', FILENAME = N'${db_log_path}\\${db}_log.ldf')"
        }
}

proc CreateTables { odbc schema } {
if { $schema != "updated" } {
#original Tables from SSMA
puts "CREATING TPCC TABLES"
set sql(1) "create table dbo.CUSTOMER (c_id int, c_d_id tinyint, c_w_id int, c_discount smallmoney, c_credit_lim money, c_last char(16), c_first char(16), c_credit char(2), c_balance money, c_ytd_payment money, c_payment_cnt smallint, c_delivery_cnt smallint, c_street_1 char(20), c_street_2 char(20), c_city char(20), c_state char(2), c_zip char(9), c_phone char(16), c_since datetime, c_middle char(2), c_data char(500))"
set sql(2) "create table dbo.DISTRICT (d_id tinyint, d_w_id int, d_ytd money, d_next_o_id int, d_tax smallmoney, d_name char(10), d_street_1 char(20), d_street_2 char(20), d_city char(20), d_state char(2), d_zip char(9))"
set sql(3) "create table dbo.HISTORY (h_c_id int, h_c_d_id tinyint, h_c_w_id int, h_d_id tinyint, h_w_id int, h_date datetime, h_amount smallmoney, h_data char(24))"
set sql(4) "create table dbo.ITEM (i_id int, i_name char(24), i_price smallmoney, i_data char(50), i_im_id int)"
set sql(5) "create table dbo.NEW_ORDER (no_o_id int, no_d_id tinyint, no_w_id int)"
set sql(6) " create table dbo.ORDER_LINE (ol_o_id int, ol_d_id tinyint, ol_w_id int, ol_number tinyint, ol_i_id int, ol_delivery_d datetime, ol_amount smallmoney, ol_supply_w_id int, ol_quantity smallint, ol_dist_info char(24))"
set sql(7) "create table dbo.ORDERS (o_id int, o_d_id tinyint, o_w_id int, o_c_id int, o_carrier_id tinyint, o_ol_cnt tinyint, o_all_local tinyint, o_entry_d datetime)"
set sql(8) "create table dbo.STOCK (s_i_id int, s_w_id int, s_quantity smallint, s_ytd int, s_order_cnt smallint, s_remote_cnt smallint, s_data char(50), s_dist_01 char(24), s_dist_02 char(24), s_dist_03 char(24), s_dist_04 char(24), s_dist_05 char(24), s_dist_06 char(24), s_dist_07 char(24), s_dist_08 char(24), s_dist_09 char(24), s_dist_10 char(24))" 
set sql(9) "create table dbo.WAREHOUSE(W_ID int, w_ytd money, w_tax smallmoney, w_name char(10), w_street_1 char(20), w_street_2 char(20), w_city char(20), w_state char(2), w_zip char(9))"
for { set i 1 } { $i <= 9 } { incr i } {
odbc  $sql($i)
        }
return
    } else {
puts "CREATING TPCC TABLES"
#Updated Tables provided by Thomas Kejser
set sql(1) {CREATE TABLE [dbo].[CUSTOMER]( [c_id] [int] NOT NULL, [c_d_id] [tinyint] NOT NULL, [c_w_id] [int] NOT NULL, [c_discount] [smallmoney] NULL, [c_credit_lim] [money] NULL, [c_last] [char](16) NULL, [c_first] [char](16) NULL, [c_credit] [char](2) NULL, [c_balance] [money] NULL, [c_ytd_payment] [money] NULL, [c_payment_cnt] [smallint] NULL, [c_delivery_cnt] [smallint] NULL, [c_street_1] [char](20) NULL, [c_street_2] [char](20) NULL, [c_city] [char](20) NULL, [c_state] [char](2) NULL, [c_zip] [char](9) NULL, [c_phone] [char](16) NULL, [c_since] [datetime] NULL, [c_middle] [char](2) NULL, [c_data] [char](500) NULL)}
set sql(2) {CREATE TABLE [dbo].[DISTRICT]( [d_id] [tinyint] NOT NULL, [d_w_id] [int] NOT NULL, [d_ytd] [money] NOT NULL, [d_next_o_id] [int] NULL, [d_tax] [smallmoney] NULL, [d_name] [char](10) NULL, [d_street_1] [char](20) NULL, [d_street_2] [char](20) NULL, [d_city] [char](20) NULL, [d_state] [char](2) NULL, [d_zip] [char](9) NULL, [padding] [char](6000) NOT NULL, CONSTRAINT [PK_DISTRICT] PRIMARY KEY CLUSTERED ( [d_w_id] ASC, [d_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(3) {CREATE TABLE [dbo].[HISTORY]( [h_c_id] [int] NULL, [h_c_d_id] [tinyint] NULL, [h_c_w_id] [int] NULL, [h_d_id] [tinyint] NULL, [h_w_id] [int] NULL, [h_date] [datetime] NULL, [h_amount] [smallmoney] NULL, [h_data] [char](24) NULL)} 
set sql(4) {CREATE TABLE [dbo].[ITEM]( [i_id] [int] NOT NULL, [i_name] [char](24) NULL, [i_price] [smallmoney] NULL, [i_data] [char](50) NULL, [i_im_id] [int] NULL, CONSTRAINT [PK_ITEM] PRIMARY KEY CLUSTERED ( [i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(5) {CREATE TABLE [dbo].[NEW_ORDER]( [no_o_id] [int] NOT NULL, [no_d_id] [tinyint] NOT NULL, [no_w_id] [int] NOT NULL)} 
set sql(6) {CREATE TABLE [dbo].[ORDERS]( [o_id] [int] NOT NULL, [o_d_id] [tinyint] NOT NULL, [o_w_id] [int] NOT NULL, [o_c_id] [int] NOT NULL, [o_carrier_id] [tinyint] NULL, [o_ol_cnt] [tinyint] NULL, [o_all_local] [tinyint] NULL, [o_entry_d] [datetime] NULL)} 
set sql(7) {CREATE TABLE [dbo].[ORDER_LINE]( [ol_o_id] [int] NOT NULL, [ol_d_id] [tinyint] NOT NULL, [ol_w_id] [int] NOT NULL, [ol_number] [tinyint] NOT NULL, [ol_i_id] [int] NULL, [ol_delivery_d] [datetime] NULL, [ol_amount] [smallmoney] NULL, [ol_supply_w_id] [int] NULL, [ol_quantity] [smallint] NULL, [ol_dist_info] [char](24) NULL)} 
set sql(8) {CREATE TABLE [dbo].[STOCK]( [s_i_id] [int] NOT NULL, [s_w_id] [int] NOT NULL, [s_quantity] [smallint] NOT NULL, [s_ytd] [int] NOT NULL, [s_order_cnt] [smallint] NULL, [s_remote_cnt] [smallint] NULL, [s_data] [char](50) NULL, [s_dist_01] [char](24) NULL, [s_dist_02] [char](24) NULL, [s_dist_03] [char](24) NULL, [s_dist_04] [char](24) NULL, [s_dist_05] [char](24) NULL, [s_dist_06] [char](24) NULL, [s_dist_07] [char](24) NULL, [s_dist_08] [char](24) NULL, [s_dist_09] [char](24) NULL, [s_dist_10] [char](24) NULL, CONSTRAINT [PK_STOCK] PRIMARY KEY CLUSTERED ( [s_w_id] ASC, [s_i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(9) {CREATE TABLE [dbo].[WAREHOUSE]( [w_id] [int] NOT NULL, [w_ytd] [money] NOT NULL, [w_tax] [smallmoney] NOT NULL, [w_name] [char](10) NULL, [w_street_1] [char](20) NULL, [w_street_2] [char](20) NULL, [w_city] [char](20) NULL, [w_state] [char](2) NULL, [w_zip] [char](9) NULL, [padding] [char](4000) NOT NULL, CONSTRAINT [PK_WAREHOUSE] PRIMARY KEY CLUSTERED ( [w_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(10) {ALTER TABLE [dbo].[CUSTOMER] SET (LOCK_ESCALATION = DISABLE)}
set sql(11) {ALTER TABLE [dbo].[DISTRICT] SET (LOCK_ESCALATION = DISABLE)}
set sql(12) {ALTER TABLE [dbo].[HISTORY] SET (LOCK_ESCALATION = DISABLE)}
set sql(13) {ALTER TABLE [dbo].[ITEM] SET (LOCK_ESCALATION = DISABLE)}
set sql(14) {ALTER TABLE [dbo].[NEW_ORDER] SET (LOCK_ESCALATION = DISABLE)}
set sql(15) {ALTER TABLE [dbo].[ORDERS] SET (LOCK_ESCALATION = DISABLE)}
set sql(16) {ALTER TABLE [dbo].[ORDER_LINE] SET (LOCK_ESCALATION = DISABLE)}
set sql(17) {ALTER TABLE [dbo].[STOCK] SET (LOCK_ESCALATION = DISABLE)}
set sql(18) {ALTER TABLE [dbo].[WAREHOUSE] SET (LOCK_ESCALATION = DISABLE)}
set sql(19) {ALTER TABLE [dbo].[DISTRICT] ADD  CONSTRAINT [DF__DISTRICT__paddin__282DF8C2]  DEFAULT (replicate('X',(6000))) FOR [padding]}
set sql(20) {ALTER TABLE [dbo].[WAREHOUSE] ADD  CONSTRAINT [DF__WAREHOUSE__paddi__14270015]  DEFAULT (replicate('x',(4000))) FOR [padding]}
for { set i 1 } { $i <= 20 } { incr i } {
odbc  $sql($i)
        }
return
    }
}

proc CreateIndexes { odbc schema } {
if { $schema != "updated" } {
#original Indexes from SSMA
puts "CREATING TPCC INDEXES"
set sql(1) "CREATE UNIQUE CLUSTERED INDEX CUSTOMER_I1 ON CUSTOMER(c_w_id, c_d_id, c_id)"
set sql(2) "CREATE UNIQUE NONCLUSTERED INDEX CUSTOMER_I2 ON CUSTOMER(c_w_id, c_d_id, c_last, c_first, c_id)"
set sql(3) "CREATE UNIQUE CLUSTERED INDEX DISTRICT_I1 ON DISTRICT(d_w_id, d_id) WITH FILLFACTOR=100"
set sql(4) "CREATE UNIQUE CLUSTERED INDEX ITEM_I1 ON ITEM(i_id)"
set sql(5) "CREATE UNIQUE CLUSTERED INDEX NEW_ORDER_I1 ON NEW_ORDER(no_w_id, no_d_id, no_o_id)"
set sql(6) "CREATE UNIQUE CLUSTERED INDEX ORDER_LINE_I1 ON ORDER_LINE(ol_w_id, ol_d_id, ol_o_id, ol_number)"
set sql(7) "CREATE UNIQUE CLUSTERED INDEX ORDERS_I1 ON ORDERS(o_w_id, o_d_id, o_id)"
set sql(8) "CREATE INDEX ORDERS_I2 ON ORDERS(o_w_id, o_d_id, o_c_id, o_id)"
set sql(9) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK(s_i_id, s_w_id)"
set sql(10) "CREATE UNIQUE CLUSTERED INDEX WAREHOUSE_C1 ON WAREHOUSE(w_id) WITH FILLFACTOR=100"
for { set i 1 } { $i <= 10 } { incr i } {
odbc  $sql($i)
        }
return
    } else {
#Updated Indexes provided by Thomas Kejser
puts "CREATING TPCC INDEXES"
set sql(1) {CREATE UNIQUE CLUSTERED INDEX [CUSTOMER_I1] ON [dbo].[CUSTOMER] ( [c_w_id] ASC, [c_d_id] ASC, [c_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(2) {CREATE UNIQUE CLUSTERED INDEX [NEW_ORDER_I1] ON [dbo].[NEW_ORDER] ( [no_w_id] ASC, [no_d_id] ASC, [no_o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(3) {CREATE UNIQUE CLUSTERED INDEX [ORDERS_I1] ON [dbo].[ORDERS] ( [o_w_id] ASC, [o_d_id] ASC, [o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(4) {CREATE UNIQUE CLUSTERED INDEX [ORDER_LINE_I1] ON [dbo].[ORDER_LINE] ( [ol_w_id] ASC, [ol_d_id] ASC, [ol_o_id] ASC, [ol_number] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)} 
set sql(5) {CREATE UNIQUE NONCLUSTERED INDEX [CUSTOMER_I2] ON [dbo].[CUSTOMER] ( [c_w_id] ASC, [c_d_id] ASC, [c_last] ASC, [c_id] ASC) INCLUDE ([c_credit], [c_street_1], [c_street_2], [c_city], [c_state], [c_zip], [c_phone], [c_middle], [c_credit_lim], [c_since], [c_discount], [c_first]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(6) {CREATE NONCLUSTERED INDEX [D_Details] ON [dbo].[DISTRICT] ( [d_id] ASC, [d_w_id] ASC) INCLUDE ([d_name], [d_street_1], [d_street_2], [d_city], [d_state], [d_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)}
set sql(7) {CREATE NONCLUSTERED INDEX [ORDERS_I2] ON [dbo].[ORDERS] ( [o_w_id] ASC, [o_d_id] ASC, [o_c_id] ASC, [o_id] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(8) {CREATE UNIQUE NONCLUSTERED INDEX [W_Details] ON [dbo].[WAREHOUSE] ( [w_id] ASC) INCLUDE ([w_tax], [w_name], [w_street_1], [w_street_2], [w_city], [w_state], [w_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
for { set i 1 } { $i <= 8 } { incr i } {
odbc  $sql($i)
        }
return
    }
}

proc chk_thread {} {
    set chk [package provide Thread]
    if {[string length $chk]} {
        return "TRUE"
        } else {
        return "FALSE"
    }
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { odbc d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
    } else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
    }
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
    } else {
set c_credit "BC"
    }
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $$c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', getdate(), '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', getdate(), '$h_amount', '$h_data')
if { $bld_cnt<= 1 } { 
append c_val_list ,
append h_val_list ,
    }
incr bld_cnt
if { ![ expr {$c_id % 2} ] } {
odbc "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list"
odbc "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list"
    odbc commit
    set bld_cnt 1
    unset c_val_list
    unset h_val_list
        }
    }
puts "Customer Done"
return
}

proc Orders { odbc d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), '$o_carrier_id', '$o_ol_cnt', '1')
    }
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
        }
    } else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', getdate())
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
        }
    }
}
if { $bld_cnt<= 1 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
        }
        }
incr bld_cnt
 if { ![ expr {$o_id % 2} ] } {
 if { ![ expr {$o_id % 1000} ] } {
    puts "...$o_id"
    }
odbc "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
if { $o_id > 2100 } {
odbc "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
    }
odbc "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list"
    odbc commit 
    set bld_cnt 1
    unset o_val_list
    unset -nocomplain no_val_list
    unset ol_val_list
            }
        }
    odbc commit
    puts "Orders Done"
    return
}

proc LoadItems { odbc MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
    }
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
    }
}
    odbc "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 50000} ] } {
    puts "Loading Items - $i_id"
            }
        }
    odbc commit 
    puts "Item done"
    return
    }

proc Stock { odbc w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
    }
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
        }
    }
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 1 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 2} ] } {
odbc "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
    odbc commit
    set bld_cnt 1
    unset val_list
    }
      if { ![ expr {$s_i_id % 20000} ] } {
    puts "Loading Stock - $s_i_id"
            }
    }
    odbc commit
    puts "Stock done"
    return
}

proc District { odbc w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
odbc "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
    }
    odbc commit
    puts "District done"
    return
}

proc LoadWare { odbc ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
odbc "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
    Stock odbc $w_id $MAXITEMS
    District odbc $w_id $DIST_PER_WARE
    odbc commit 
    }
}

proc LoadCust { odbc ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
    Customer odbc $d_id $w_id $CUST_PER_DIST
        }
    }
    odbc commit 
    return
}

proc LoadOrd { odbc ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
    Orders odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST
        }
    }
    odbc commit 
    return
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
    }
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
    } else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
    }
}
return $connection
}

proc do_tpcc { server port odbc_driver authentication uid pwd count_ware db schema num_threads db_data_path db_log_path } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
CreateDatabase odbc $db $db_data_path $db_log_path
odbc "use $db"
CreateTables odbc $schema
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems odbc $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems odbc $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {database connect odbc $connection} message ] {
puts stderr "error, the database connection to $connection could not be established"
error $message
return
 } else {
odbc "use $db"
odbc set autocommit off 
} 
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare odbc $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust odbc $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd odbc $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
odbc commit 
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes odbc $schema
CreateStoredProcs odbc $schema
UpdateStatistics odbc $db
puts "[ string toupper $db ] SCHEMA COMPLETE"
odbc disconnect
return
    }
}

if { $argc != 8 } {
    puts "The tcl script requires 6 numbers to be inputed."
    puts "Please try again."
} else {
	
    set mssql_server [lindex $argv 0]
    set mssql_username [lindex $argv 1]
    set mssql_password [lindex $argv 2]
    set mssql_warehouse_num [lindex $argv 3]
    set mssql_db_name [lindex $argv 4]
    set mssql_threads [lindex $argv 5]
    set db_data_path [lindex $argv 6]
    set db_log_path [lindex $argv 7]
    do_tpcc $mssql_server 1433 {SQL Server Native Client 11.0} sql $mssql_username $mssql_password $mssql_warehouse_num $mssql_db_name original $mssql_threads $db_data_path $db_log_path
}


#server port odbc_driver authentication uid pwd count_ware db schema num_threads
    
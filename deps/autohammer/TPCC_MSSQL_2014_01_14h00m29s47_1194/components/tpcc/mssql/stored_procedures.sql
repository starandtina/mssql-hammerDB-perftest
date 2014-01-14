CREATE PROCEDURE NEWORD  
	@no_w_id int, @no_max_w_id int, @no_d_id int, @no_c_id int, @no_o_ol_cnt int, @timestamp datetime2(0)
	AS 
	BEGIN
	DECLARE @no_c_discount smallmoney, @no_c_last char(16), @no_c_credit char(2),
	        @no_d_tax smallmoney, @no_w_tax smallmoney, @no_d_next_o_id int, @no_ol_supply_w_id int, 
		@no_ol_i_id int, @no_ol_quantity int, @no_o_all_local int, @o_id int, @no_i_name char(24), 
		@no_i_price smallmoney, @no_i_data char(50), @no_s_quantity int, @no_ol_amount int, 
		@no_s_dist_01 char(24), @no_s_dist_02 char(24), @no_s_dist_03 char(24), @no_s_dist_04 char(24), 
		@no_s_dist_05 char(24), @no_s_dist_06 char(24), @no_s_dist_07 char(24), @no_s_dist_08 char(24), 
		@no_s_dist_09 char(24), @no_s_dist_10 char(24), @no_ol_dist_info char(24), @no_s_data char(50), 
		@x int, @rbk int
	BEGIN TRANSACTION
	BEGIN TRY
		SET @no_o_all_local = 0
		SELECT @no_c_discount = customer.c_discount, 
		       @no_c_last = customer.c_last, 
		       @no_c_credit = customer.c_credit, 
		       @no_w_tax = warehouse.w_tax 
		FROM customer, warehouse 
		WHERE warehouse.w_id = @no_w_id 
		AND customer.c_w_id = @no_w_id 
		AND customer.c_d_id = @no_d_id 
		AND customer.c_id = @no_c_id
		UPDATE district 

		SET @no_d_tax = d_tax, @o_id = d_next_o_id,  d_next_o_id = district.d_next_o_id + 1 

		WHERE district.d_id = @no_d_id 
		AND district.d_w_id = @no_w_id
		INSERT orders( o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
		VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @timestamp, @no_o_ol_cnt, @no_o_all_local)

		INSERT new_order(no_o_id, no_d_id, no_w_id) VALUES (@o_id, @no_d_id, @no_w_id)

		SET @rbk = CAST(100 * RAND() + 1 AS INT)
		DECLARE @loop_counter int
		SET @loop_counter = 1
		DECLARE @loop$bound int
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
					DECLARE @db_null_statement$2 int
				END
			END
			SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)
			SELECT @no_i_price = item.i_price, @no_i_name = item.i_name, @no_i_data = item.i_data 
			FROM item WHERE item.i_id = @no_ol_i_id
			SELECT @no_s_quantity = stock.s_quantity, 
			       @no_s_data = stock.s_data, 
			       @no_s_dist_01 = stock.s_dist_01, 
			       @no_s_dist_02 = stock.s_dist_02, 
			       @no_s_dist_03 = stock.s_dist_03, 
			       @no_s_dist_04 = stock.s_dist_04, 
			       @no_s_dist_05 = stock.s_dist_05, 
			       @no_s_dist_06 = stock.s_dist_06, 
			       @no_s_dist_07 = stock.s_dist_07, 
			       @no_s_dist_08 = stock.s_dist_08, 
			       @no_s_dist_09 = stock.s_dist_09, 
			       @no_s_dist_10 = stock.s_dist_10 
			FROM stock WHERE stock.s_i_id = @no_ol_i_id 
			AND stock.s_w_id = @no_ol_supply_w_id
			IF (@no_s_quantity > @no_ol_quantity)
				SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
			ELSE 
				SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)
			UPDATE stock SET s_quantity = @no_s_quantity 
			WHERE stock.s_i_id = @no_ol_i_id 
			AND stock.s_w_id = @no_ol_supply_w_id
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
			INSERT order_line( ol_o_id, ol_d_id, ol_w_id, ol_number, 
			                       ol_i_id, ol_supply_w_id, ol_quantity, 
					       ol_amount, ol_dist_info) 
		        VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, 
			         @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
			SET @loop_counter = @loop_counter + 1
		END
		SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last 
		as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) 
		as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'
	END TRY
	BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber
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
END;
-- HAMMERORA GO
CREATE PROCEDURE DELIVERY  @d_w_id int, @d_o_carrier_id int, @timestamp datetime2(0)
       AS 
       BEGIN 
       DECLARE @d_no_o_id int, @d_d_id int, @d_c_id int, @d_ol_total int
       BEGIN TRANSACTION
       BEGIN TRY
       DECLARE @loop_counter int
       SET @loop_counter = 1
       WHILE @loop_counter <= 10
       BEGIN
       SET @d_d_id = @loop_counter
       SELECT TOP (1) @d_no_o_id = new_order.no_o_id 
       FROM new_order WITH (serializable updlock) 
                      WHERE  new_order.no_w_id = @d_w_id AND new_order.no_d_id = @d_d_id
       DELETE new_order WHERE new_order.no_w_id = @d_w_id 
                        AND new_order.no_d_id = @d_d_id 
			AND new_order.no_o_id =  @d_no_o_id
       SELECT @d_c_id = orders.o_c_id FROM orders 
                                      WHERE orders.o_id = @d_no_o_id 
				      AND orders.o_d_id = @d_d_id 
				      AND orders.o_w_id = @d_w_id
       UPDATE orders SET o_carrier_id = @d_o_carrier_id WHERE orders.o_id = @d_no_o_id AND orders.o_d_id = @d_d_id AND orders.o_w_id = @d_w_id
       UPDATE order_line SET ol_delivery_d = @timestamp WHERE order_line.ol_o_id = @d_no_o_id AND order_line.ol_d_id = @d_d_id AND order_line.ol_w_id = @d_w_id
       SELECT @d_ol_total = sum(order_line.ol_amount) FROM order_line WHERE order_line.ol_o_id = @d_no_o_id AND order_line.ol_d_id = @d_d_id AND order_line.ol_w_id = @d_w_id
       UPDATE customer SET c_balance = customer.c_balance + @d_ol_total WHERE customer.c_id = @d_c_id AND customer.c_d_id = @d_d_id AND customer.c_w_id = @d_w_id
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
       ISNULL(CAST(@timestamp AS nvarchar(max)), '')
       SET @loop_counter = @loop_counter + 1
       END
       SELECT	@d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @timestamp as N'@timestamp'
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
       END
-- HAMMERORA GO
CREATE PROCEDURE PAYMENT  @p_w_id int, @p_d_id int, @p_c_w_id int, @p_c_d_id int, @p_c_id int, 
                              @byname int, @p_h_amount numeric(6,2), @p_c_last char(16), @timestamp datetime2(0)
       AS 
       BEGIN
       DECLARE @p_w_street_1 char(20), @p_w_street_2 char(20), @p_w_city char(20), @p_w_state char(2), @p_w_zip char(10),
               @p_d_street_1 char(20), @p_d_street_2 char(20), @p_d_city char(20), @p_d_state char(20), @p_d_zip char(10),
               @p_c_first char(16), @p_c_middle char(2), @p_c_street_1 char(20), @p_c_street_2 char(20), @p_c_city char(20),
               @p_c_state char(20), @p_c_zip char(9), @p_c_phone char(16), @p_c_since datetime2(0), @p_c_credit char(32),
               @p_c_credit_lim  numeric(12,2), @p_c_discount  numeric(4,4), @p_c_balance numeric(12,2), @p_c_data varchar(500),
               @namecnt int, @p_d_name char(11), @p_w_name char(11), @p_c_new_data varchar(500), @h_data varchar(30)
       BEGIN TRANSACTION
       BEGIN TRY
       UPDATE warehouse SET w_ytd = warehouse.w_ytd + @p_h_amount WHERE warehouse.w_id = @p_w_id
       SELECT @p_w_street_1 = warehouse.w_street_1, @p_w_street_2 = warehouse.w_street_2, @p_w_city = warehouse.w_city, @p_w_state = warehouse.w_state, @p_w_zip = warehouse.w_zip, @p_w_name = warehouse.w_name FROM warehouse WHERE warehouse.w_id = @p_w_id
       UPDATE district SET d_ytd = district.d_ytd + @p_h_amount WHERE district.d_w_id = @p_w_id AND district.d_id = @p_d_id
       SELECT @p_d_street_1 = district.d_street_1, @p_d_street_2 = district.d_street_2, @p_d_city = district.d_city, @p_d_state = district.d_state, @p_d_zip = district.d_zip, @p_d_name = district.d_name FROM district WHERE district.d_w_id = @p_w_id AND district.d_id = @p_d_id
       IF (@byname = 1)
       BEGIN
       SELECT @namecnt = count(customer.c_id) FROM customer WITH (repeatableread) WHERE customer.c_last = @p_c_last AND customer.c_d_id = @p_c_d_id AND customer.c_w_id = @p_c_w_id
       DECLARE c_byname CURSOR LOCAL FOR 
       SELECT customer.c_first, customer.c_middle, customer.c_id, customer.c_street_1, customer.c_street_2, customer.c_city, customer.c_state, customer.c_zip, customer.c_phone, customer.c_credit, customer.c_credit_lim, customer.c_discount, customer.c_balance, customer.c_since FROM customer WITH (repeatableread) WHERE customer.c_w_id = @p_c_w_id AND customer.c_d_id = @p_c_d_id AND customer.c_last = @p_c_last ORDER BY customer.c_first
       OPEN c_byname
       IF ((@namecnt % 2) = 1)
       SET @namecnt = (@namecnt + 1)
       BEGIN
       DECLARE @loop_counter int
       SET @loop_counter = 0
       DECLARE @loop$bound int
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
       SELECT @p_c_first = customer.c_first, 
              @p_c_middle = customer.c_middle, 
	      @p_c_last = customer.c_last, 
	      @p_c_street_1 = customer.c_street_1, 
	      @p_c_street_2 = customer.c_street_2, 
	      @p_c_city = customer.c_city, 
	      @p_c_state = customer.c_state, 
	      @p_c_zip = customer.c_zip, 
	      @p_c_phone = customer.c_phone, 
	      @p_c_credit = customer.c_credit, 
	      @p_c_credit_lim = customer.c_credit_lim, 
	      @p_c_discount = customer.c_discount, 
	      @p_c_balance = customer.c_balance, 
	      @p_c_since = customer.c_since 
	FROM customer 
	WHERE customer.c_w_id = @p_c_w_id 
	AND customer.c_d_id = @p_c_d_id 
	AND customer.c_id = @p_c_id 
       END
       SET @p_c_balance = (@p_c_balance + @p_h_amount)
       IF @p_c_credit = 'BC'
       BEGIN
       SELECT @p_c_data = customer.c_data 
       FROM customer 
       WHERE customer.c_w_id = @p_c_w_id 
       AND customer.c_d_id = @p_c_d_id 
       AND customer.c_id = @p_c_id
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
       ISNULL(CAST(@timestamp AS char), '')
        + 
       ISNULL(@h_data, ''))
       SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
       UPDATE customer 
       SET c_balance = @p_c_balance, 
       c_data = @p_c_new_data 
       WHERE customer.c_w_id = @p_c_w_id 
       AND customer.c_d_id = @p_c_d_id 
       AND customer.c_id = @p_c_id
       END
       ELSE 
       UPDATE customer SET c_balance = @p_c_balance 
       WHERE customer.c_w_id = @p_c_w_id 
       AND customer.c_d_id = @p_c_d_id 
       AND customer.c_id = @p_c_id
       SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
       INSERT history( h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @timestamp, @p_h_amount, @h_data)
       SELECT	@p_c_id as N'@p_c_id', 
                @p_c_last as N'@p_c_last', 
		@p_w_street_1 as N'@p_w_street_1', 
		@p_w_street_2 as N'@p_w_street_2', 
		@p_w_city as N'@p_w_city', 
		@p_w_state as N'@p_w_state', 
		@p_w_zip as N'@p_w_zip', 
		@p_d_street_1 as N'@p_d_street_1', 
		@p_d_street_2 as N'@p_d_street_2', 
		@p_d_city as N'@p_d_city', 
		@p_d_state as N'@p_d_state', 
		@p_d_zip as N'@p_d_zip', 
		@p_c_first as N'@p_c_first', 
		@p_c_middle as N'@p_c_middle', 
		@p_c_street_1 as N'@p_c_street_1', 
		@p_c_street_2 as N'@p_c_street_2', 
		@p_c_city as N'@p_c_city', 
		@p_c_state as N'@p_c_state', 
		@p_c_zip as N'@p_c_zip', 
		@p_c_phone as N'@p_c_phone', 
		@p_c_since as N'@p_c_since', 
		@p_c_credit as N'@p_c_credit', 
		@p_c_credit_lim as N'@p_c_credit_lim', 
		@p_c_discount as N'@p_c_discount', 
		@p_c_balance as N'@p_c_balance', 
		@p_c_data as N'@p_c_data'
       END TRY
       BEGIN CATCH
       SELECT ERROR_NUMBER() AS ErrorNumber ,
              ERROR_SEVERITY() AS ErrorSeverity ,
	      ERROR_STATE() AS ErrorState ,
	      ERROR_PROCEDURE() AS ErrorProcedure ,
	      ERROR_LINE() AS ErrorLine,
              ERROR_MESSAGE() AS ErrorMessage;
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	END CATCH;
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
END;
-- HAMMERORA GO
CREATE 	PROCEDURE OSTAT @os_w_id int, @os_d_id int, @os_c_id int, @byname int, @os_c_last char(20)
       	AS 
	BEGIN
	DECLARE @os_c_first char(16), @os_c_middle char(2), @os_c_balance money, @os_o_id int, @os_entdate datetime2(0),
		@os_o_carrier_id int, @os_ol_i_id INT, @os_ol_supply_w_id INT, @os_ol_quantity INT, @os_ol_amount INT,
		@os_ol_delivery_d DATE, @namecnt int, @i int, @os_ol_i_id_array VARCHAR(200), @os_ol_supply_w_id_array VARCHAR(200),
		@os_ol_quantity_array VARCHAR(200), @os_ol_amount_array VARCHAR(200), @os_ol_delivery_d_array VARCHAR(210)
	BEGIN TRANSACTION
	BEGIN TRY
		SET @os_ol_i_id_array = 'CSV,'
		SET @os_ol_supply_w_id_array = 'CSV,'
		SET @os_ol_quantity_array = 'CSV,'
		SET @os_ol_amount_array = 'CSV,'
		SET @os_ol_delivery_d_array = 'CSV,'
		IF (@byname = 1)
		BEGIN
			SELECT @namecnt = count_big(customer.c_id) 
			FROM customer 
			WHERE customer.c_last = @os_c_last 
			AND customer.c_d_id = @os_d_id 
			AND customer.c_w_id = @os_w_id

			IF ((@namecnt % 2) = 1)
			SET @namecnt = (@namecnt + 1)
			DECLARE c_name CURSOR LOCAL FOR 
			SELECT customer.c_balance, customer.c_first, customer.c_middle, customer.c_id 
			FROM customer 
			WHERE customer.c_last = @os_c_last 
			AND customer.c_d_id = @os_d_id 
			AND customer.c_w_id = @os_w_id 
			ORDER BY customer.c_first
			OPEN c_name
			BEGIN
				DECLARE @loop_counter int
				SET @loop_counter = 0
				DECLARE @loop$bound int
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
			SELECT @os_c_balance = customer.c_balance, 
			       @os_c_first = customer.c_first, 
			       @os_c_middle = customer.c_middle, 
			       @os_c_last = customer.c_last 
			FROM customer 
			WITH (repeatableread) 
			WHERE customer.c_id = @os_c_id 
			AND customer.c_d_id = @os_d_id 
			AND customer.c_w_id = @os_w_id
		END
	BEGIN
		SELECT TOP (1) @os_o_id = fci.o_id, @os_o_carrier_id = fci.o_carrier_id, @os_entdate = fci.o_entry_d
		FROM (SELECT TOP 9223372036854775807 orders.o_id, orders.o_carrier_id, orders.o_entry_d 
		FROM orders WITH (serializable) 
		WHERE orders.o_d_id = @os_d_id 
		AND orders.o_w_id = @os_w_id 
		AND orders.o_c_id = @os_c_id 
		ORDER BY orders.o_id DESC)  AS fci
		IF @@ROWCOUNT = 0
		PRINT 'No orders for customer';
	END
	SET @i = 0
	DECLARE c_line CURSOR LOCAL FORWARD_ONLY FOR 
		SELECT order_line.ol_i_id, 
		       order_line.ol_supply_w_id, 
		       order_line.ol_quantity, 
		       order_line.ol_amount, 
		       order_line.ol_delivery_d 
		FROM order_line 
		WITH (repeatableread) 
		WHERE order_line.ol_o_id = @os_o_id 
		AND order_line.ol_d_id = @os_d_id 
		AND order_line.ol_w_id = @os_w_id
	OPEN c_line
	WHILE 1 = 1
	BEGIN
		FETCH c_line
		INTO @os_ol_i_id, @os_ol_supply_w_id, @os_ol_quantity, @os_ol_amount, @os_ol_delivery_d
		IF @@FETCH_STATUS = -1 BREAK
		set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
		set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
		set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
		set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
		set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
		SET @i = @i + 1
	END
	CLOSE c_line
	DEALLOCATE c_line
	SELECT	@os_c_id as N'@os_c_id', 
	        @os_c_last as N'@os_c_last', 
		@os_c_first as N'@os_c_first', 
		@os_c_middle as N'@os_c_middle', 
		@os_c_balance as N'@os_c_balance', 
		@os_o_id as N'@os_o_id', 
		@os_entdate as N'@os_entdate', 
		@os_o_carrier_id as N'@os_o_carrier_id'
	END TRY
	BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber,
	       ERROR_SEVERITY() AS ErrorSeverity,
	       ERROR_STATE() AS ErrorState,
	       ERROR_PROCEDURE() AS ErrorProcedure,
	       ERROR_LINE() AS ErrorLine,
	       ERROR_MESSAGE() AS ErrorMessage;
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION;
	END CATCH;
	IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
END;
-- HAMMERORA GO
CREATE 	PROCEDURE SLEV  @st_w_id int, @st_d_id int, @threshold int
	AS 
	BEGIN
	DECLARE @st_o_id int, @stock_count int 
	BEGIN TRANSACTION
	BEGIN TRY
		SELECT @st_o_id = district.d_next_o_id 
		FROM district 
		WHERE district.d_w_id = @st_w_id 
		AND district.d_id = @st_d_id

		SELECT @stock_count = count_big(DISTINCT stock.s_i_id) 
		FROM order_line, stock 
		WHERE order_line.ol_w_id = @st_w_id 
		AND order_line.ol_d_id = @st_d_id 
		AND (order_line.ol_o_id < @st_o_id) 
		AND order_line.ol_o_id >= (@st_o_id - 20) 
		AND stock.s_w_id = @st_w_id 
		AND stock.s_i_id = order_line.ol_i_id 
		AND stock.s_quantity < @threshold

		SELECT	@st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
	END TRY
	BEGIN CATCH
		SELECT 	ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() AS ErrorState,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	END CATCH;
	IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
END;
-- HAMMERORA GO

CREATE OR REPLACE PROCEDURE NEWORD (no_w_id        INTEGER,
	                                no_max_w_id    INTEGER,
	                                no_d_id        INTEGER,
	                                no_c_id        INTEGER,
	                                no_o_ol_cnt    INTEGER,
	                                no_c_discount  OUT NUMBER,
	                                no_c_last      OUT VARCHAR2,
	                                no_c_credit    OUT VARCHAR2,
	                                no_d_tax       OUT NUMBER,
	                                no_w_tax       OUT NUMBER,
                                    no_d_next_o_id IN OUT INTEGER,
                                    timestamp      IN DATE )
                  IS
	                    no_ol_supply_w_id INTEGER;
	                    no_ol_i_id        NUMBER;
	                    no_ol_quantity    NUMBER;
	                    no_o_all_local    INTEGER;
	                    o_id              INTEGER;
	                    no_i_name         VARCHAR2(24);
	                    no_i_price        NUMBER(5,2);
	                    no_i_data         VARCHAR2(50);
	                    no_s_quantity     NUMBER(6);
	                    no_ol_amount      NUMBER(6,2);
	                    no_s_dist_01      CHAR(24);
	                    no_s_dist_02      CHAR(24);
	                    no_s_dist_03      CHAR(24);
	                    no_s_dist_04      CHAR(24);
	                    no_s_dist_05      CHAR(24);
	                    no_s_dist_06      CHAR(24);
	                    no_s_dist_07      CHAR(24);
	                    no_s_dist_08      CHAR(24);
	                    no_s_dist_09      CHAR(24);
	                    no_s_dist_10      CHAR(24);
	                    no_ol_dist_info   CHAR(24);
	                    no_s_data         VARCHAR2(50);
	                    x                 NUMBER;
	                    rbk               NUMBER;
	                    not_serializable  EXCEPTION;
	                    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
	                    deadlock          EXCEPTION;
	                    PRAGMA EXCEPTION_INIT(deadlock,-60);
	                    snapshot_too_old  EXCEPTION;
	                    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
	                    integrity_viol    EXCEPTION;
	                    PRAGMA EXCEPTION_INIT(integrity_viol,-1);
                BEGIN
--assignment below added due to error in appendix code
                    no_o_all_local := 0;
                    SELECT c_discount, c_last, c_credit, w_tax
                    INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
                    FROM customer, warehouse
                    WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id 
                    AND customer.c_d_id = no_d_id AND customer.c_id = no_c_id;

                    UPDATE district SET d_next_o_id = d_next_o_id + 1 
                    WHERE d_id = no_d_id 
                    AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax 
                    INTO no_d_next_o_id, no_d_tax;


                    o_id := no_d_next_o_id;

                    INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
                    VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);

                    INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) 
                    VALUES (o_id, no_d_id, no_w_id);

--#2.4.1.4
                    rbk := round(DBMS_RANDOM.value(low => 1, high => 100));
--#2.4.1.5
                    FOR loop_counter IN 1 .. no_o_ol_cnt LOOP
                        IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1)) THEN
                            no_ol_i_id := 100001;
                        ELSE
                            no_ol_i_id := round(DBMS_RANDOM.value(low => 1, high => 100000));
                        END IF;
--#2.4.1.5.2
                        x := round(DBMS_RANDOM.value(low => 1, high => 100));
                        IF ( x > 1 ) THEN
                            no_ol_supply_w_id := no_w_id;
                        ELSE
                            no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
                            no_o_all_local := 0;
                            WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1)) LOOP
                                no_ol_supply_w_id := round(DBMS_RANDOM.value(low => 1, high => no_max_w_id));
                            END LOOP;
                        END IF;
--#2.4.1.5.3
                        no_ol_quantity := round(DBMS_RANDOM.value(low => 1, high => 10));
                        SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
                        FROM item WHERE i_id = no_ol_i_id;

                        SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
                        INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 
                        FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;

                        IF ( no_s_quantity > no_ol_quantity ) THEN
                            no_s_quantity := ( no_s_quantity - no_ol_quantity );
                        ELSE
                            no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
                        END IF;
                        UPDATE stock SET s_quantity = no_s_quantity
                        WHERE s_i_id = no_ol_i_id
                        AND s_w_id = no_ol_supply_w_id;

                        no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

                        IF no_d_id = 1 THEN 
                            no_ol_dist_info := no_s_dist_01; 
                            ELSIF no_d_id = 2 THEN
                                no_ol_dist_info := no_s_dist_02;
                            ELSIF no_d_id = 3 THEN
                                no_ol_dist_info := no_s_dist_03;
                            ELSIF no_d_id = 4 THEN
                                no_ol_dist_info := no_s_dist_04;
                            ELSIF no_d_id = 5 THEN
                                no_ol_dist_info := no_s_dist_05;
                            ELSIF no_d_id = 6 THEN
                                no_ol_dist_info := no_s_dist_06;
                            ELSIF no_d_id = 7 THEN
                                no_ol_dist_info := no_s_dist_07;
                            ELSIF no_d_id = 8 THEN
                                no_ol_dist_info := no_s_dist_08;
                            ELSIF no_d_id = 9 THEN
                                no_ol_dist_info := no_s_dist_09;
                            ELSIF no_d_id = 10 THEN
                                no_ol_dist_info := no_s_dist_10;
                        END IF;

                        INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
                        VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

                    END LOOP;
                    
                    COMMIT;

                    EXCEPTION
                        WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol OR no_data_found THEN ROLLBACK;
                END;
-- HAMMERORA GO
CREATE OR REPLACE PROCEDURE DELIVERY (d_w_id         INTEGER,
                                      d_o_carrier_id INTEGER,
                                      timestamp      IN DATE )
IS
    d_no_o_id     INTEGER;
    d_d_id	      INTEGER;
    d_c_id        NUMBER;
    d_ol_total    NUMBER;
    current_ROWID UROWID;
--WHERE CURRENT OF CLAUSE IN SPECIFICATION GAVE VERY POOR PERFORMANCE
--USED ROWID AS GIVEN IN DOC CDOUG Tricks and Treats by Shahs Upadhye
    CURSOR c_no IS
        SELECT no_o_id,ROWID
        FROM new_order
        WHERE no_d_id = d_d_id AND no_w_id = d_w_id
        ORDER BY no_o_id ASC;

    not_serializable EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock         EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
    FOR loop_counter IN 1 .. 10 LOOP
        d_d_id := loop_counter;
        open c_no;
        FETCH c_no INTO d_no_o_id,current_ROWID;
        EXIT WHEN c_no%NOTFOUND;
        DELETE FROM new_order WHERE rowid = current_ROWID;
        close c_no;

        SELECT o_c_id INTO d_c_id FROM orders
        WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND o_w_id = d_w_id;

        UPDATE orders SET o_carrier_id = d_o_carrier_id
        WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND o_w_id = d_w_id;

        UPDATE order_line SET ol_delivery_d = timestamp
        WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND ol_w_id = d_w_id;

        SELECT SUM(ol_amount) INTO d_ol_total FROM order_line
        WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
        AND ol_w_id = d_w_id;

        UPDATE customer SET c_balance = c_balance + d_ol_total
        WHERE c_id = d_c_id AND c_d_id = d_d_id AND c_w_id = d_w_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
    END LOOP;
    EXCEPTION
        WHEN not_serializable OR deadlock OR snapshot_too_old THEN ROLLBACK;
END; 
-- HAMMERORA GO
CREATE OR REPLACE PROCEDURE PAYMENT (p_w_id         INTEGER,
                                     p_d_id         INTEGER,
                                     p_c_w_id       INTEGER,
                                     p_c_d_id       INTEGER,
                                     p_c_id         IN OUT INTEGER,
                                     byname         INTEGER,
                                     p_h_amount     NUMBER,
                                     p_c_last       IN OUT VARCHAR2,
                                     p_w_street_1   OUT VARCHAR2,
                                     p_w_street_2   OUT VARCHAR2,
                                     p_w_city       OUT VARCHAR2,
                                     p_w_state      OUT VARCHAR2,
                                     p_w_zip        OUT VARCHAR2,
                                     p_d_street_1   OUT VARCHAR2,
                                     p_d_street_2   OUT VARCHAR2,
                                     p_d_city       OUT VARCHAR2,
                                     p_d_state      OUT VARCHAR2,
                                     p_d_zip        OUT VARCHAR2,
                                     p_c_first      OUT VARCHAR2,
                                     p_c_middle     OUT VARCHAR2,
                                     p_c_street_1   OUT VARCHAR2,
                                     p_c_street_2   OUT VARCHAR2,
                                     p_c_city       OUT VARCHAR2,
                                     p_c_state      OUT VARCHAR2,
                                     p_c_zip        OUT VARCHAR2,
                                     p_c_phone      OUT VARCHAR2,
                                     p_c_since      OUT DATE,
                                     p_c_credit     IN OUT VARCHAR2,
                                     p_c_credit_lim OUT NUMBER,
                                     p_c_discount   OUT NUMBER,
                                     p_c_balance    IN OUT NUMBER,
                                     p_c_data       OUT VARCHAR2,
                                     timestamp      IN DATE )
IS
    namecnt      INTEGER;
    p_d_name     VARCHAR2(11);
    p_w_name     VARCHAR2(11);
    p_c_new_data VARCHAR2(500);
    h_data       VARCHAR2(30);
    CURSOR c_byname IS
        SELECT c_first, c_middle, c_id, c_street_1, c_street_2, 
               c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, 
               c_discount, c_balance, c_since
        FROM customer
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
        ORDER BY c_first;

    not_serializable EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock         EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
    UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
    WHERE w_id = p_w_id;

    SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
    INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
    FROM warehouse
    WHERE w_id = p_w_id;

    UPDATE district SET d_ytd = d_ytd + p_h_amount
    WHERE d_w_id = p_w_id AND d_id = p_d_id;

    SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
    INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
    FROM district
    WHERE d_w_id = p_w_id AND d_id = p_d_id;

    IF ( byname = 1 ) THEN
        SELECT count(c_id) INTO namecnt
        FROM customer
        WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
        OPEN c_byname;
        IF ( MOD (namecnt, 2) = 1 ) THEN
            namecnt := (namecnt + 1);
        END IF;
        FOR loop_counter IN 0 .. (namecnt/2) LOOP
            FETCH c_byname
            INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
                 p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
        END LOOP;
        CLOSE c_byname;
    ELSE
        SELECT c_first, c_middle, c_last,
               c_street_1, c_street_2, c_city, c_state, c_zip,
               c_phone, c_credit, c_credit_lim,
               c_discount, c_balance, c_since
        INTO p_c_first, p_c_middle, p_c_last,
             p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
             p_c_phone, p_c_credit, p_c_credit_lim,
             p_c_discount, p_c_balance, p_c_since
        FROM customer
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
    END IF;
    p_c_balance := ( p_c_balance + p_h_amount );
    IF p_c_credit = 'BC' THEN
        SELECT c_data INTO p_c_data
        FROM customer
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
-- The following statement in the TPC-C specification appendix is incorrect
-- copied setting of h_data from later on in the procedure to here as well
        h_data := ( p_w_name || ' ' || p_d_name );
        p_c_new_data := (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' ||
        TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || TO_CHAR(p_h_amount,'9999.99') || TO_CHAR(timestamp) || h_data);
        p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));

        UPDATE customer
        SET c_balance = p_c_balance, c_data = p_c_new_data
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
    ELSE
        UPDATE customer SET c_balance = p_c_balance
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
    END IF;
--setting of h_data is here in the TPC-C appendix
    h_data := ( p_w_name|| ' ' || p_d_name );

    INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data)
    VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, timestamp, p_h_amount, h_data);
    COMMIT;

    EXCEPTION
        WHEN not_serializable OR deadlock OR snapshot_too_old THEN ROLLBACK;
END; 
-- HAMMERORA GO
CREATE OR REPLACE PROCEDURE OSTAT (os_w_id         INTEGER,
                                   os_d_id         INTEGER,
                                   os_c_id         IN OUT INTEGER,
                                   byname          INTEGER,
                                   os_c_last       IN OUT VARCHAR2,
                                   os_c_first      OUT VARCHAR2,
                                   os_c_middle     OUT VARCHAR2,
                                   os_c_balance    OUT NUMBER,
                                   os_o_id         OUT INTEGER,
                                   os_entdate      OUT DATE,
                                   os_o_carrier_id OUT INTEGER )
IS
    TYPE numbertable IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    os_ol_i_id numbertable;	
    os_ol_supply_w_id numbertable;	
    os_ol_quantity numbertable;	

    TYPE amounttable IS TABLE OF NUMBER(6,2) INDEX BY BINARY_INTEGER;
    os_ol_amount amounttable;
    TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
    os_ol_delivery_d datetable;
    namecnt  INTEGER;
    i        BINARY_INTEGER;

    CURSOR c_name IS
        SELECT c_balance, c_first, c_middle, c_id
        FROM customer
        WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
        ORDER BY c_first;

    CURSOR c_line IS
        SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d
        FROM order_line
        WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;

    os_c_line c_line%ROWTYPE;
    not_serializable EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock         EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
    IF ( byname = 1 ) THEN
        SELECT count(c_id) INTO namecnt
        FROM customer
        WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;

        IF ( MOD (namecnt, 2) = 1 ) THEN
            namecnt := (namecnt + 1);
        END IF;
        OPEN c_name;
        FOR loop_counter IN 0 .. (namecnt/2) LOOP
            FETCH c_name INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
        END LOOP;
        close c_name;
    ELSE
        SELECT c_balance, c_first, c_middle, c_last
        INTO os_c_balance, os_c_first, os_c_middle, os_c_last
        FROM customer
        WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
    END IF;
-- The following statement in the TPC-C specification appendix is incorrect
-- as it does not include the where clause and does not restrict the 
-- results set giving an ORA-01422.
-- The statement has been modified in accordance with the
-- descriptive specification as follows:
-- The row in the ORDER table with matching O_W_ID (equals C_W_ID),
-- O_D_ID (equals C_D_ID), O_C_ID (equals C_ID), and with the largest
-- existing O_ID, is selected. This is the most recent order placed by that
-- customer. O_ID, O_ENTRY_D, and O_CARRIER_ID are retrieved.
    BEGIN
        SELECT o_id, o_carrier_id, o_entry_d 
        INTO os_o_id, os_o_carrier_id, os_entdate
        FROM
            (SELECT o_id, o_carrier_id, o_entry_d
             FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
             ORDER BY o_id DESC) WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN dbms_output.put_line('No orders for customer');
    END;
    i := 0;
    FOR os_c_line IN c_line LOOP
        os_ol_i_id(i) := os_c_line.ol_i_id;
        os_ol_supply_w_id(i) := os_c_line.ol_supply_w_id;
        os_ol_quantity(i) := os_c_line.ol_quantity;
        os_ol_amount(i) := os_c_line.ol_amount;
        os_ol_delivery_d(i) := os_c_line.ol_delivery_d;
        i := i+1;
    END LOOP;
    EXCEPTION WHEN not_serializable OR deadlock OR snapshot_too_old THEN ROLLBACK;
END;
-- HAMMERORA GO
CREATE OR REPLACE PROCEDURE SLEV (st_w_id   INTEGER,
                                  st_d_id   INTEGER,
                                  threshold INTEGER )
IS 
    st_o_id           NUMBER; 
    stock_count       INTEGER;
    not_serializable  EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock          EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old  EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
    SELECT d_next_o_id INTO st_o_id
    FROM district
    WHERE d_w_id=st_w_id AND d_id=st_d_id;

    SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
    FROM order_line, stock
    WHERE ol_w_id = st_w_id AND ol_d_id = st_d_id 
    AND (ol_o_id < st_o_id) AND ol_o_id >= (st_o_id - 20) 
    AND s_w_id = st_w_id AND s_i_id = ol_i_id 
    AND s_quantity < threshold;
    COMMIT;

    EXCEPTION WHEN not_serializable OR deadlock OR snapshot_too_old THEN ROLLBACK;

END;
-- HAMMERORA GO

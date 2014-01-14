  CREATE TABLE ORDERS (O_ORDERDATE TIMESTAMP, 
                       O_ORDERKEY NUMERIC NOT NULL, 
                       O_CUSTKEY NUMERIC NOT NULL, 
                       O_ORDERPRIORITY CHAR(15), 
                       O_SHIPPRIORITY NUMERIC, 
                       O_CLERK CHAR(15), 
                       O_ORDERSTATUS CHAR(1), 
                       O_TOTALPRICE NUMERIC, 
                       O_COMMENT VARCHAR(79))
-- HAMMERORA GO
  CREATE TABLE PARTSUPP (PS_PARTKEY NUMERIC NOT NULL, 
                         PS_SUPPKEY NUMERIC NOT NULL, 
                         PS_SUPPLYCOST NUMERIC NOT NULL, 
                         PS_AVAILQTY NUMERIC, 
                         PS_COMMENT VARCHAR(199))
-- HAMMERORA GO
  CREATE TABLE CUSTOMER(C_CUSTKEY NUMERIC NOT NULL, 
                        C_MKTSEGMENT CHAR(10), 
                        C_NATIONKEY NUMERIC, 
                        C_NAME VARCHAR(25), 
                        C_ADDRESS VARCHAR(40), 
                        C_PHONE CHAR(15), 
                        C_ACCTBAL NUMERIC, 
                        C_COMMENT VARCHAR(118))
-- HAMMERORA GO
  CREATE TABLE PART(P_PARTKEY NUMERIC NOT NULL, 
                    P_TYPE VARCHAR(25), 
                    P_SIZE NUMERIC, 
                    P_BRAND CHAR(10), 
                    P_NAME VARCHAR(55), 
                    P_CONTAINER CHAR(10), 
                    P_MFGR CHAR(25), 
                    P_RETAILPRICE NUMERIC, 
                    P_COMMENT VARCHAR(23))
-- HAMMERORA GO
  CREATE TABLE SUPPLIER(S_SUPPKEY NUMERIC NOT NULL, 
                        S_NATIONKEY NUMERIC, 
                        S_COMMENT VARCHAR(102), 
                        S_NAME CHAR(25), 
                        S_ADDRESS VARCHAR(40), 
                        S_PHONE CHAR(15), 
                        S_ACCTBAL NUMERIC)
-- HAMMERORA GO
  CREATE TABLE NATION(N_NATIONKEY NUMERIC NOT NULL, 
                      N_NAME CHAR(25), 
                      N_REGIONKEY NUMERIC, 
                      N_COMMENT VARCHAR(152))
-- HAMMERORA GO
  CREATE TABLE REGION(R_REGIONKEY NUMERIC, 
                      R_NAME CHAR(25), 
                      R_COMMENT VARCHAR(152))
-- HAMMERORA GO
  CREATE TABLE LINEITEM(L_SHIPDATE TIMESTAMP, 
                        L_ORDERKEY NUMERIC NOT NULL, 
                        L_DISCOUNT NUMERIC NOT NULL, 
                        L_EXTENDEDPRICE NUMERIC NOT NULL, 
                        L_SUPPKEY NUMERIC NOT NULL, 
                        L_QUANTITY NUMERIC NOT NULL, 
                        L_RETURNFLAG CHAR(1), 
                        L_PARTKEY NUMERIC NOT NULL, 
                        L_LINESTATUS CHAR(1), 
                        L_TAX NUMERIC NOT NULL, 
                        L_COMMITDATE TIMESTAMP, 
                        L_RECEIPTDATE TIMESTAMP, 
                        L_SHIPMODE CHAR(10), 
                        L_LINENUMBER NUMERIC NOT NULL, 
                        L_SHIPINSTRUCT CHAR(25), 
                        L_COMMENT VARCHAR(44))
-- HAMMERORA GO

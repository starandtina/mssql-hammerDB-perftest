CREATE TABLE ORDERS (O_ORDERDATE DATE, 
                     O_ORDERKEY NUMBER NOT NULL, 
                     O_CUSTKEY NUMBER NOT NULL, 
                     O_ORDERPRIORITY CHAR(15),
                     O_SHIPPRIORITY NUMBER, 
                     O_CLERK CHAR(15), 
                     O_ORDERSTATUS CHAR(1), 
                     O_TOTALPRICE NUMBER, 
                     O_COMMENT VARCHAR(79)) 
       PCTFREE 2 PCTUSED 98  INITRANS 8  PARALLEL
-- HAMMERORA GO
CREATE TABLE PARTSUPP (PS_PARTKEY NUMBER NOT NULL, 
                       PS_SUPPKEY NUMBER NOT NULL, 
                       PS_SUPPLYCOST NUMBER NOT NULL, 
                       PS_AVAILQTY NUMBER, 
                       PS_COMMENT VARCHAR(199)) PARALLEL
-- HAMMERORA GO
CREATE TABLE CUSTOMER(C_CUSTKEY NUMBER NOT NULL, 
                      C_MKTSEGMENT CHAR(10), 
                      C_NATIONKEY NUMBER, 
                      C_NAME VARCHAR(25), 
                      C_ADDRESS VARCHAR(40), 
                      C_PHONE CHAR(15), 
                      C_ACCTBAL NUMBER, 
                      C_COMMENT VARCHAR(118)) 
        PCTFREE 0 PCTUSED 99 PARALLEL
-- HAMMERORA GO
CREATE TABLE PART(P_PARTKEY NUMBER NOT NULL, 
                  P_TYPE VARCHAR(25), 
                  P_SIZE NUMBER, 
                  P_BRAND CHAR(10), 
                  P_NAME VARCHAR(55), 
                  P_CONTAINER CHAR(10), 
                  P_MFGR CHAR(25), 
                  P_RETAILPRICE NUMBER, 
                  P_COMMENT VARCHAR(23)) 
       PARALLEL
-- HAMMERORA GO
CREATE TABLE SUPPLIER(S_SUPPKEY NUMBER NOT NULL, 
                      S_NATIONKEY NUMBER, 
                      S_COMMENT VARCHAR(102), 
                      S_NAME CHAR(25), 
                      S_ADDRESS VARCHAR(40), 
                      S_PHONE CHAR(15), 
                      S_ACCTBAL NUMBER) 
       PCTFREE 0 PCTUSED 99 PARALLEL
-- HAMMERORA GO
CREATE TABLE NATION(N_NATIONKEY NUMBER NOT NULL, 
                    N_NAME CHAR(25), 
                    N_REGIONKEY NUMBER, 
                    N_COMMENT VARCHAR(152))
-- HAMMERORA GO
CREATE TABLE REGION(R_REGIONKEY NUMBER, 
                    R_NAME CHAR(25), 
                    R_COMMENT VARCHAR(152))
-- HAMMERORA GO
CREATE TABLE LINEITEM(L_SHIPDATE DATE, 
                      L_ORDERKEY NUMBER NOT NULL, 
                      L_DISCOUNT NUMBER NOT NULL, 
                      L_EXTENDEDPRICE NUMBER NOT NULL,      
                      L_SUPPKEY NUMBER NOT NULL, 
                      L_QUANTITY NUMBER NOT NULL, 
                      L_RETURNFLAG CHAR(1), 
                      L_PARTKEY NUMBER NOT NULL, 
                      L_LINESTATUS CHAR(1), 
                      L_TAX NUMBER NOT NULL, 
                      L_COMMITDATE DATE, 
                      L_RECEIPTDATE DATE, 
                      L_SHIPMODE CHAR(10), 
                      L_LINENUMBER NUMBER NOT NULL, 
                      L_SHIPINSTRUCT CHAR(25), 
                      L_COMMENT VARCHAR(44)) 
       PCTFREE 2 PCTUSED 98 INITRANS 8 PARALLEL
-- HAMMERORA GO

# 
# Distributed under GPL 2.2
# Copyright Steve Shaw 2003-2012
# Copyright Tim Witham 2012,2013
#
# set tabstop=4 for readability

package require Thread
package require platform
global tcl_platform
global rdbms_info f_info xml_info 


proc Dbl_zero {sin} {
    if {[string length $sin] < 1 } { return "0.0" }
    return $sin
}

proc Int_zero {sin} {
    if {[string length $sin] < 1 } { return "0" }
    return $sin
}

proc Double_single {sin} {
    set split_sin [split $sin {\'}]
    if { [llength $split_sin] < 2 } {
        return $sin
    } else {
        return [join $split_sin "\'\'"]
    }
}

proc Gen_tpcds_data { sec_name log_id rdbms parallel db_scale template log_dir } {
global tcl_platform

    set current_dir [pwd]
    set subdir_template $template
    set xlevel 2
    set dsgen_dir "./DSGen" 

    Enter_log_tag $log_id "S" $sec_name 1 xlevel 
    set tlog_file "tpcds_gen.xml"
    set tlog_file [file join $log_dir $tlog_file]
    if [catch {open $tlog_file w} tlog_id] {
        Enter_log_item $log_id "unable_to_open_log_file" $tlog_file $xlevel
        Error_out $log_id $sec_name
    }

    set gen_out_dir [file join $log_dir "LoadData"]
    
    if {[catch [file mkdir $gen_out_dir] file_err ] } {
        Enter_log_item $log_id "unable_to_generate_data_directory" $gen_out_dir $xlevel
        Error_out $log_id $sec_name
    }
    
    Put_thread_header $tlog_id $sec_name
    set txlevel 2

#
# If you only have one stream
#

    Enter_log_item $tlog_id "parallel" $parallel $xlevel
    if {$parallel == 1 } {
        set pass_out_dir [file join ".." $gen_out_dir]
        cd $dsgen_dir
        puts [pwd]
        puts "scale is $db_scale and out_dir is $pass_out_dir"
        switch $tcl_platform(os) {
                "Windows NT" {
                    if {[catch {exec "dsdgen.exe" "/SCALE" $db_scale \
                                     "/DELIMITER" "\=" "/DIR" $pass_out_dir } msg] } {
                         set ex_err 1
                     } else {
                         set ex_err 0
                     }
                } 
                "Linux" {
                    if {[catch {exec "./dsdgen" "-SCALE" $db_scale \
                                     "-DELIMITER" "\=" "-DIR" $gen_out_dir } msg] } {
                        set ex_err 1
                    } else {
                        set ex_err 0
                    }
                } 
                default {
                        puts "What the heck man! OS isn't known ==$tcl_platform(os)"
                        exit
                }
        }
        if { $ex_err } {
            if { [string first "ERROR" $::errorInfo] > 0 } { 
                puts "ERROR returned from dsdgen"
                puts "ERROR info: $::errorInfo"
                puts "Message is <<<<$msg>>>>"
                puts "In directory [pwd]"
                exit
            }
        }

        cd $current_dir
        Put_thread_footer $tlog_id $sec_name
        Enter_log_tag $log_id "E" $sec_name 1 xlevel 
        return
    }

#
# And if you are going parallel
#

    for {set l_thread 1 } { $l_thread <= $parallel } {incr l_thread} {
        set gen_out_dir [file join $log_dir "LoadData" [format $subdir_template $parallel $l_thread] ]
        if {[catch [file mkdir $gen_out_dir] file_err ] } {
            puts "ERROR: Unable to make data generation output directory"
            exit
        }
        set pass_out_dir($l_thread) [file join ".." $gen_out_dir]
    }

    cd $dsgen_dir
    for {set l_thread 1 } { $l_thread <= $parallel } {incr l_thread} {
        Enter_log_item $tlog_id "child" $l_thread $xlevel
        set t_list($l_thread) [thread::create -joinable {thread::wait}]
        Load_source_directory $t_list($l_thread) $rdbms $current_dir "auto_tpcds.tcl"
        eval [subst {thread::send -async $t_list($l_thread) {\
                Exec_dsdgen $db_scale $parallel $l_thread $pass_out_dir($l_thread)} r_id } ]

    }
    while {[llength [thread::names]] > 1} {
        after 500
    }
    cd $current_dir
    Put_thread_footer $tlog_id $sec_name
    return
}

proc Gen_tpcds_update_data { sec_name log_id rdbms parallel db_scale template rngseed log_dir } {
global tcl_platform

    set current_dir [pwd]
    set subdir_template $template
    set xlevel 2
    set dsgen_dir "./DSGen" 

    #Enter_log_tag $log_id "S" $sec_name 1 xlevel 
    set tlog_file "tpcds_gen_update.xml"
    set tlog_file [file join $log_dir $tlog_file]
    if [catch {open $tlog_file w} tlog_id] {
        Enter_log_item $log_id "unable_to_open_log_file" $tlog_file $xlevel
        Error_out $log_id $sec_name
    }

    set gen_out_dir [file join $log_dir "UpdateData"]
    
    if {[catch [file mkdir $gen_out_dir] file_err ] } {
        Enter_log_item $log_id "unable_to_generate_update_data_directory" $gen_out_dir $xlevel
        Error_out $log_id $sec_name
    }
    
    Put_thread_header $tlog_id $sec_name
    set txlevel 2

    Enter_log_item $tlog_id "parallel" $parallel $xlevel

    set pass_out_dir [file join ".." $gen_out_dir]

    cd $dsgen_dir
    for {set l_thread 1 } { $l_thread <= $parallel } {incr l_thread} {
        Enter_log_item $tlog_id "child" $l_thread $xlevel
        set t_list($l_thread) [thread::create -joinable {thread::wait}]
        Load_source_directory $t_list($l_thread) $rdbms $current_dir "auto_tpcds.tcl"
        eval [subst {thread::send -async $t_list($l_thread) {\
                Exec_dsdgen_update $db_scale $parallel $l_thread $rngseed $pass_out_dir} r_id } ]

    }
    while {[llength [thread::names]] > 1} {
        after 500
    }
    cd $current_dir
    Put_thread_footer $tlog_id $sec_name
    return
}

proc Exec_dsdgen {db_scale parallel child out_dir } {
global tcl_platform
        switch $tcl_platform(os) {
            "Windows NT" {
                if {[catch {exec "dsdgen.exe" "/SCALE" $db_scale \
                                 "/DELIMITER" "\=" "/PARALLEL" $parallel \
                                 "/CHILD" $child "/DIR" $out_dir } msg] } {
                    set ex_err 1
                } else {
                    set ex_err 0
                }
            } 
            "Linux" {
                if {[catch {exec "./dsdgen" "-SCALE" $db_scale \
                                 "-DELIMITER" "\=" "-PARALLEL" $parallel \
                                 "-CHILD" $child "-DIR" $out_dir } msg] } {
                    set ex_err 1
                } else {
                    set ex_err 0
                }
            } 
            default {
                puts "What the heck man! OS isn't known ==$tcl_platform(os)"
                exit
            }
        }

        if { $ex_err } {
            if { [string first "ERROR" $::errorInfo] > 0 } { 
                puts "ERROR returned from dsdgen"
                puts "ERROR info: $::errorInfo"
                puts "Message is <<<<$msg>>>>"
                puts "In directory [pwd]"
                exit
            }
        }
        set r_id [thread::id]
        thread::release

}

proc Exec_dsdgen_update { db_scale parallel child rngseed out_dir } {
global tcl_platform     
    switch $tcl_platform(os) {
        "Windows NT" {
            if { [catch {exec "./dsdgen.exe" "/SCALE" $db_scale "/RNGSEED" $rngseed \
                              "/DELIMITER" "\=" "/UPDATE" $child "/DIR" $out_dir} msg ] } {
                set ex_err 1
            } else {
                set ex_err 0
            }
        }
        "Linux"      {
            if { [catch {exec "./dsdgen" "-SCALE" $db_scale "-RNGSEED" $rngseed \
                              "-DELIMITER" "\=" "-UPDATE" $child "-DIR" $out_dir} msg ] } {
                set ex_err 1
            } else {
                set ex_err 0
            }
            
        }
        default {
            puts "What the heck man! OS isn't known ==$tcl_platform(os)"
            exit
        }
    }
    if { $ex_err } {
        if { [string first "ERROR" $::errorInfo] > 0 } { 
            puts "ERROR returned from dsqgen"
            puts "ERROR info: $::errorInfo"
            puts "Message is <<<<$msg>>>>"
            puts "In directory [pwd]"
        }
        set r_id [thread::id]
        thread::release
    }

    set r_id [thread::id]
    thread::release

}

proc Get_table_size { sec_name log_id table_name db_scale } {
    array set catalog_page { 1 11718 100 20400 300 25000 1000 30000 3000 36000 10000 40000 30000 46000 100000 50000 }
    array set catalog_returns { 1 144067 100 14404374 300 43193472 1000 143996756 3000 432018033 \
                                10000 1440033112 30000 4319925093 100000 14400509482 }
    array set catalog_sales { 1 1441548 100 143997065 300 431969836 1000 1431980416 3000 4320078880 \
                              10000 14399964710 30000 43200404822 100000 144001292896 }
    array set customer { 1 100000 100 2000000 300 5000000 1000 12000000 3000 30000000 10000 65000000 \
                         30000 80000000 100000 100000000 }
    array set customer_address { 1 50000 100 1000000 300 2500000 1000 6000000 3000 15000000 \
                                 10000 32500000 30000 40000000 100000 50000000 }
    array set customer_demographics { 1 1920800 100 1920800 300 1920800 1000 1920800 3000 1920800 \
                                      10000 1920800 30000 1920800 100000 1920800 }
    array set date_dim { 1 73049 100 73049 300 73049 1000 73049 3000 73049 10000 73049 30000 73049 100000 73049 }
    array set dsdgen_version { 1 1 100 1 300 1 1000 1 3000 1 10000 1 30000 1 100000 1 }
    array set household_demographics { 1 7200 100 7200 300 7200 1000 7200 3000 7200 10000 7200 30000 7200 100000 7200 }
    array set income_band { 1 20 100 20 300 20 1000 20 3000 20 10000 20 30000 20 100000 20 }
    array set item { 1 18000 100 204000 300 264000 1000 300000 3000 360000 10000 402000 30000 462000 100000 502000 }
    array set promotion { 1  300 100 1000 300 1300 1000 1500 3000 1800 10000 2000 30000 2300 100000 2500 }
    array set reason {   1 35 100 55 300 60 1000 65 3000 67 10000 70 30000 72 100000 75 }
    array set ship_mode { 1 20 100 20 300 20 1000 20 3000 20 10000 20 30000 20 100000 20 }
    array set store { 1 12 100 402 300 804 1000 1002 3000 1350 10000 1500 30000 1704 100000 1902 }
    array set store_returns { 1 287514 100 28795080 300 86393244 1000 287999754 3000 863989652 \
                            10000 2879970104 30000 8639952111 100000 28799941468 }
    array set store_sales { 1 2880404 100 287997024 300 864001869 1000 2879987999 3000 8639936081 \
                            10000 28799983563 30000 86399341874 100000 287998696432 }
    array set time_dim { 1 86400 100 86400 300 86400 1000 86400 3000 86400 10000 86400 30000 86400 100000 86400 }
    array set warehouse { 1  5 100 15 300 17 1000 20 3000 22 10000 25 30000 27 100000 30 }
    array set web_page { 1 60 100 2040 300 2604 1000 3000 3000 3600 10000 4002 30000 4602 100000 5004 }
    array set web_returns { 1 71736 100 7197670 300 21599377 1000 71997522 3000 216003761 \
                            10000 720020485 30000 2160007345 100000 7200085924 }
    array set web_sales { 1 719384 100 72001237 300 216009853 1000 720000376 3000 2159968881 \
                          10000 7199963324 30000 21600036511 100000 71999537298 }
    array set web_site { 1 30
                          100 24
                          300 1
                         1000 1
                         3000 1
                        10000 1
                        30000 1
                       100000 1 
    }
    upvar 0 $table_name use_array
    return $use_array($db_scale)
    flush stdout
}

proc Gen_tpcds_queries { sec_name log_id rdbms parallel db_scale rngseed log_dir} {
global tcl_platform
# ./dsqgen  -directory query_templates 
#           -input QueryList.txt 
#           -dialect sqlserver 
#           -streams 20 
#           -scale 1 
#           -rngseed 0 
#           -log dsqgen_log.txt

    set query_streams [expr {($parallel*2)+1}]
    set query_dir  [file join $log_dir "Queries"]
    set current_dir [pwd]
    set dsgen_dir "./DSGen" 
    if {[catch [file mkdir $query_dir] file_err] } {
        Enter_log_item $log_id "ERROR" "unable to create query directory  =Queries=" $xlevel
        Error_out      $log_id $sec_name
    }
    set qt_dir [format "%s_templates" [string tolower $rdbms]]

    cd $dsgen_dir
    switch $tcl_platform(os) {
        "Windows NT" {
            if {[catch {exec "dsqgen.exe" "/INPUT" "QueryList.txt" \
                             "/RNGSEED" $rngseed "/SCALE" $db_scale \
                             "/STREAMS" $query_streams "/DIRECTORY" $qt_dir \
                             "/OUTPUT_DIR" [file join ".."  $query_dir] } msg] } {
                set ex_err 1
            } else {
                set ex_err 0
            }
        } 
        "Linux" {
            if {[catch {exec "dsqgen" "-INPUT" "QueryList.txt" \
                             "-RNGSEED" $rngseed "-SCALE" $db_scale \
                             "-STREAMS" $query_streams "-DIRECTORY" "query_templates" \
                             "-OUTPUT_DIR" [file join ".."  $query_dir] } msg] } {
                set ex_err 1
            } else {
                set ex_err 0
            }
        } 
        default {
            puts "What the heck man! OS isn't known ==$tcl_platform(os)"
            exit
        }
    }
    if { $ex_err } {
        if { [string first "ERROR" $::errorInfo] > 0 } { 
            puts "ERROR returned from dsqgen"
            puts "ERROR info: $::errorInfo"
            puts "Message is <<<<$msg>>>>"
            puts "In directory [pwd]"
            exit
        }
    }
    cd $current_dir
    
}

proc Check_load { sec_name log_id rdbms database_name connect db_scale log_dir } {

    set query_them { catalog_page catalog_sales catalog_returns customer customer_address \
                     customer_demographics date_dim dsdgen_version household_demographics  \
                     income_band item promotion reason ship_mode store store_returns      \
                     store_sales time_dim warehouse web_page web_returns web_sales web_site }

    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    "db_ds"
    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
    set query_log_name [file join $log_dir "check_load.xml"]
    if {[catch {open $query_log_name w} query_log_id] } {
        Enter_log_item $log_id "ERROR" "unable to create $query_log_name" $xelvel
        Error_out      $log_id $sec_name
    }
    Put_thread_header $query_log_id "check_load"
    set xlevel 2
    set good 1
    foreach f $query_them {
        set use_sql "select count(*) from $f"
        set expected [ Get_table_size $sec_name $log_id $f $db_scale ]
        set q_cnt [RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 1]
        Enter_log_tag $query_log_id "S" $f 0 xlevel
        Enter_log_item $query_log_id "expected" $expected $xlevel
        Enter_log_item $query_log_id "returned" $q_cnt    $xlevel
        if {$q_cnt < [expr {$expected*0.9}] } {
            set good 0
            Enter_log_item $query_log_id "FAIL" "not enough entries"    $xlevel
        }
        if {$q_cnt > [expr {$expected*1.1}] } {
            set good 0
            Enter_log_item $query_log_id "FAIL" "to many entries"    $xlevel
        }
        Enter_log_tag $query_log_id "E" $f 0 xlevel
    }

    Put_thread_footer $query_log_id "check_load"
    close $query_log_id

    if {$good} {
        Enter_log_item $log_id "load_check" "passed" $xlevel
    } else {
        Enter_log_item $log_id "load_check" "FAILED" $xlevel
    }
    return
}


proc Load_tpcds { sec_name log_id rdbms database_name load_type connect db_scale parallel log_dir data_location template} {
global rdbms_info f_info xml_info 


    set xlevel 2
    set load_log_dir [file join $log_dir "load_tpcds"]
    if {[catch [file mkdir $load_log_dir] file_err] } {
        Enter_log_item $log_id "ERROR" "unable to create log directory =load_tpcds=" $xlevel
        Error_out      $log_id $sec_name
    }
    
    if {[string tolower data_location] == "local" } {
        set base_data_dir [file join $log_dir "DSDGEN"]
    } else {
        set base_data_dir $data_location
    }
    set f_connect [Quote_slash $connect]

    if {$parallel == 1 } {
        set load_log_name [file join $load_log_dir "tpcds_load.xml"]
        if {[catch {open $load_log_name w} load_log_id] } {
            Enter_log_item $log_id "ERROR" "unable to create $load_log_name" $xelvel
            Error_out      $log_id $sec_name
        }
        Enter_log_item $log_id "load_log" $load_log_name" $xlevel

        Load_files_tpcds $sec_name $load_log_id $rdbms $database_name $f_connect $base_data_dir 1 $parallel $xlevel

        return
    }
    for {set wthread 1} {$wthread <= $parallel} {incr wthread } {
    
        set load_log_name  [file join $log_dir "load_tpcds" [format "tpcds_load_%04d.xml" $wthread]]
        if {[catch {open $load_log_name w} load_log_id] } {
            Enter_log_item $log_id "ERROR" "unable to create $load_log_name" $xlevel
            Error_out      $log_id $sec_name
        }

        if {$load_type == "batch"} {

            set f_char [string tolower [string range $data_location 0 0 ]]
            set s_char [string tolower [string range $data_location 1 1 ]]
            if {$f_char == "/" || $s_char == ":"} {
                set base_data_dir [file join $data_location [format $template $parallel $wthread]]
            } else {
                set base_data_dir [file join [pwd] [file tail $data_location] [format $template $parallel $wthread]]
            }
        } else {
            set base_data_dir [file join $data_location [format $template $parallel $wthread]]
        }
        set t_list($wthread) [thread::create -joinable {thread::wait}]
        #
        # The load up the source code do this sync so that they happen one after another
        #   
        thread::transfer $t_list($wthread) $load_log_id
        Load_sources $t_list($wthread) $rdbms "auto_tpcds.tcl"
        #
        # And run the database thread -async so they happen together
        #                                                                                    
    

        eval [subst {thread::send -async $t_list($wthread) {   \
            Load_files_tpcds $sec_name $load_log_id $rdbms $database_name $load_type $f_connect \
                             $base_data_dir $wthread $parallel $xlevel } r_id } ]

    
    }
#
# Wait for everybody (threads) before ending
#
    while {1} {
        if {[llength [thread::names]] <= 1} { break }
        after 50
    }
    return


}

proc Gen_rngseed { log_id }  {
global rdbms_info f_info xml_info 

    set xlevel 2
    set rngseed_tics [clock milliseconds]
    set rngseed [MS_rngseed $rngseed_tics]
    Enter_log_item $log_id "RNGSEED" $rngseed $xlevel
    set rdbms_info(rngseed) $rngseed
    return 
}

proc Do_batch { log_id rdbms database_name dbhandle hodbc dbcur table file_in xlevel} {
    Enter_log_tag $log_id "S" $table 1 xlevel
    switch $rdbms {
        oracle { puts "Dude batch not implemented for Oracle as of yet!"
                 return
        }
        mssql {
            set use_sql "bulk insert $database_name.dbo.$table
                         from '$file_in'
                         WITH (
                            ROWS_PER_BATCH = 10000,
                            TABLOCK,
                            KEEPNULLS,
                            FIELDTERMINATOR = '=',
                            ROWTERMINATOR ='=\\n');"
        }
    }
    RDBMS_sql $rdbms $log_id $table 0 $hodbc $dbcur $use_sql "" 0 0 0
    Commit_sql $log_id $rdbms $hodbc $dbhandle $table 1 $xlevel
    Enter_log_tag $log_id "E" $table 1 xlevel
}

proc Load_files_tpcds { sec_name log_id rdbms database_name load_type connect data_dir thread parallel xlevel} {

    Put_thread_header $log_id $sec_name
    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    [format "ds_%d" $thread]
    set file_bases {"call_center" "customer" "dbgen_version" "item" "store" "warehouse" "web_site" \
                    "catalog_page" "customer_address" "household_demographics" "promotion" \
                    "store_returns" "web_page" "catalog_returns" "customer_demographics" \
                    "income_band" "reason" "store_sales" "web_returns" "catalog_sales" \
                    "date_dim" "inventory" "ship_mode" "time_dim" "web_sales" }
            

    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
    Auto_on_off $rdbms $hodbc $dbhandle "off"

    if {![file exists $data_dir] } {
        Enter_log_item $log_id "ERROR" "unable to locate directory $data_dir" $xlevel
        Error_out $log_id $sec_name
    }

    set rdbms [string tolower $rdbms]
    set load_type [string tolower $load_type]

    foreach fb $file_bases {

        if {$parallel == 1 } {
            set f "$fb.dat"
        } else {
            set f [format "%s_%d_%d.dat" $fb $thread $parallel]
        }

        set f [file join $data_dir $f]

        if {![file exists $f]} {continue}

        if {$load_type == "batch"} {
            #puts "f is >>>$f<<<"
            if {$fb == "dbgen_version"} { set fb "dsdgen_version"}
            Do_batch $log_id $rdbms $database_name $dbhandle $hodbc $dbcur $fb $f $xlevel
            continue
        }
            
        switch $fb {
            reason { 
                Load_reason       $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            dbgen_version { 
                Load_dbgen         $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            call_center { 
                Load_call_center  $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            promotion { 
                Load_promotion    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            catalog_page { 
                Load_catalog_page $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            web_returns { 
                Load_w_returns    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            warehouse { 
                    Load_warehouse    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            time_dim { 
                    Load_time_dim     $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            household_demographics { 
                    Load_house_demo   $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            store_returns { 
                    Load_s_returns    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            inventory { 
                    Load_inventory    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            store { 
                    Load_store        $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            catalog_sales { 
                    Load_c_sales      $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            web_sales { 
                    Load_w_sales      $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            web_page { 
                    Load_w_page       $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            item { 
                    Load_item         $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            catalog_returns { 
                    Load_c_returns    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            store_sales { 
                    Load_s_sales      $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            customer_demographics { 
                    Load_c_demo       $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            date_dim { 
                    Load_date_dim     $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            web_site { 
                    Load_web_site     $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            customer_address { 
                    Load_c_address    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            ship_mode { 
                    Load_ship_mode    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            customer { 
                    Load_customer    $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            income_band { 
                    Load_income_band $log_id $rdbms $dbhandle $hodbc $dbcur $f $xlevel
            }
            default { 
                    Enter_log_item $log_id "unknown_file_name" $f $xlevel
            }
        }
    }
    Put_thread_footer $log_id $sec_name
    if {$parallel != 1} {
        set r_id [thread::id]
        thread::release
    } else {
        return
    }
}

proc Load_update_tpcds { sec_name log_id rdbms database_name connect data_dir update_cnt parallel xlevel} {

    Put_thread_header $log_id $sec_name
    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    [format "ds_%d" $thread]
    set file_bases { "s_inventory" "s_purchase_lineitem" "s_catalog_order_lineitem" \
                    "s_web_order_lineitem" "s_store_returns" "s_zip_to_gmt" \
                    "s_purchase" "s_catalog_order" "s_catalog_returns" \
                    "s_web_returns" "s_web_order" "s_customer" "s_item"  \
                    "s_catalog_page" "s_customer_address" "s_web_page" \
                    "s_promotion" "s_store" "s_call_center" "s_warehouse" \
                    "s_web_site" }
            

    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
    Auto_on_off $rdbms $hodbc $dbhandle "off"

    if {![file exists $data_dir] } {
        Enter_log_item $log_id "ERROR" "unable to locate directory $data_dir" $xlevel
        Error_out $log_id $sec_name
    }

    set rdbms [string tolower $rdbms]
    set load_type [string tolower $load_type]

    foreach fb $file_bases {

        set f [format "%s_%d.dat" $fb $update_cnt]

        set f [file join $data_dir $f]

        if {![file exists $f]} {continue}

        Do_batch $log_id $rdbms $database_name $dbhandle $hodbc $dbcur $fb $f $xlevel
            
    }

    Put_thread_footer $log_id $sec_name
    if {$parallel != 1} {
        set r_id [thread::id]
        thread::release
    } else {
        return
    }
}

proc Open_data_file {log_id sec_name file_in} {
    if [catch {open $file_in r} data_id] {
        Enter_log_item $log_id "ERROR" "Unable to open data file $file_in" $xlevel
        Error_out $log_id $sec_name
    }
    return $data_id
}

proc Set_mssql_load_sql {log_id table } {
    puts "Nothing in Set_mssql_load_sql yet fix and rerun"
    exit
}

proc Set_mysql_load_sql {log_id table } {
    puts "Nothing in Set_mysql_load_sql yet fix and rerun"
    exit
}

proc Set_oracle_load_sql {log_id table } {
    puts "Nothing in Set_oracle_load_sql yet fix and rerun"
    exit
}

proc Set_pgsql_load_sql {log_id table } {
    puts "Nothing in Set_pgsql_load_sql yet fix and rerun"
    exit
}


proc Load_reason {log_id rdbms dbhandle hodbc dbcur file_in xlevel } {

    set sec_name "reason"
    set cmt_cnt  10


    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]
    
    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into reason (r_reason_sk, r_reason_id, r_reason_desc) values (
                     '[lindex $in_items 0]', '[lindex $in_items 1]', '[lindex $in_items 2]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_dbgen {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {


    set sec_name "dbgen_version"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    while {[gets $data_id line_in] >= 0 } {
        set token [string first "=" $line_in]
        set version_in [string range $line_in 0 [expr {$token-1}]]
        set line_in   [string range $line_in [expr {$token + 1} ] end ]
        set token [string first "=" $line_in]
        set date_in [string range $line_in 0 [expr {$token-1}]]
        set line_in   [string range $line_in [expr {$token + 1} ] end ]
        set token [string first "=" $line_in]
        set time_in [string range $line_in 0 [expr {$token-1}]]
        set line_in   [string range $line_in [expr {$token + 1} ] end ]
        set cmdline_in [string range $line_in 0 [expr {[string length $line_in]-2}]]
        switch $rdbms {
            oracle {
                set use_date_time  [format "%s %s" $date_in $time_in]
                set use_sql "insert into dsdgen_version (dv_version, dv_create_date, dv_create_time, dv_cmdline_args)
                    values (
                    '$version_in', 
                    TO_DATE('$use_date_time','YYYY-MM-dd HH24:MI:SS'), 
                    TO_DATE('$use_date_time','YYYY-MM-dd HH24:MI:SS'), 
                    '$cmdline_in')"
            }
            mssql  {
                set use_sql "insert into dsdgen_version (dv_version, dv_create_date, dv_create_time, dv_cmdline_args)
                    values (
                    '$version_in', '$date_in', 
                    '$time_in',    '$cmdline_in')"
            }
        }
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_call_center  {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "call_center"
    set cmt_cnt  100
    set i 1
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    # skip for now
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    return
    set data_id [Open_data_file $log_id $sec_name $file_in]

    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { 
                    set date_2 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" 
                    set date_3 "TO_DATE('[lindex $in_items 3]','YYYY-MM-dd')" 
                   }
            mssql  { 
                    set date_2 "'[lindex $in_items 2]'" 
                    set date_3 "'[lindex $in_items 3]'" 
                   }
        }
        set use_sql "insert into call_center ( cc_call_center_sk, cc_call_center_id,
                                               cc_rec_start_date, cc_rec_end_date,
                                               cc_closed_date_sk, cc_open_date_sk,
                                               cc_name,           cc_class,
                                               cc_employees,      cc_sq_ft,
                                               cc_hours,          cc_manager,
                                               cc_mkt_id,         cc_mkt_class,
                                               cc_mkt_desc,       cc_market_manager,
                                               cc_division,       cc_division_name, 
                                               cc_company,        cc_company_name,
                                               cc_street_number,  cc_street_name,
                                               cc_street_type,    cc_suite_number,
                                               cc_city,           cc_county,
                                               cc_state,          cc_zip,
                                               cc_country,        cc_gmt_offset,
                                               cc_tax_percentage) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     $date_2,
                     $date_3,
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '[lindex $in_items 18]', '[lindex $in_items 19]',
                     '[lindex $in_items 20]', '[lindex $in_items 21]',
                     '[lindex $in_items 22]', '[lindex $in_items 23]',
                     '[lindex $in_items 24]', '[lindex $in_items 25]',
                     '[lindex $in_items 26]', '[lindex $in_items 27]',
                     '[lindex $in_items 28]', '[lindex $in_items 29]',
                     '[lindex $in_items 30]')"
            
        if {$i == 1} {puts $use_sql}
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_promotion    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "promotion"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set dis_act  [string range [lindex $in_items 18] 0 0]
        switch $rdbms {
            oracle {
                set use_sql "insert into promotion ( p_promo_sk,        p_promo_id,
                                             p_start_date_sk,   p_end_date_sk,
                                             p_item_sk,         p_cost,
                                             p_response_target, p_promo_name,
                                             p_channel_dmail,   p_channel_email,
                                             p_channel_catalog, p_channel_tv,
                                             p_channel_radio,   p_channel_press,
                                             p_channel_event,   p_channel_demo,
                                             p_channel_details, p_purpose,
                                             p_discount_active) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '[lindex $in_items 18]')"
            }
            mssql  {
                set use_sql "insert into promotion ( p_promo_sk,        p_promo_id,
                                             p_start_date_sk,   p_end_date_sk,
                                             p_item_sk,         p_cost,
                                             p_response_target, p_promo_name,
                                             p_channel_dmail,   p_channel_email,
                                             p_channel_catalog, p_channel_tv,
                                             p_channel_radio,   p_channel_press,
                                             p_channel_event,   p_channel_demo,
                                             p_channel_details, p_purpose,
                                             p_discount_active) values (
                     '[Int_zero [lindex $in_items 0]]',  '[lindex $in_items 1]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Dbl_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '$dis_act')"
            }
        }

        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_catalog_page {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "catalog_page"
    set cmt_cnt  1000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle {
                set use_sql "insert into  catalog_page ( cp_catalog_page_sk,     cp_catalog_page_id,
                                                 cp_start_date_sk,       cp_end_date_sk,
                                                 cp_department,          cp_catalog_number,
                                                 cp_catalog_page_number, cp_description,
                                                 cp_type) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]')"
            }
            mssql  {
                set use_sql "insert into  catalog_page ( cp_catalog_page_sk,     cp_catalog_page_id,
                                                 cp_start_date_sk,       cp_end_date_sk,
                                                 cp_department,          cp_catalog_number,
                                                 cp_catalog_page_number, cp_description,
                                                 cp_type) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]')"
            }
        }
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_w_returns    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "web_returns"
    set cmt_cnt  2000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  web_returns ( wr_returned_date_sk,   wr_returned_time_sk,
                                                wr_item_sk,            wr_refunded_customer_sk,
                                                wr_refunded_cdemo_sk,  wr_refunded_hdemo_sk,
                                                wr_refunded_addr_sk,   wr_returning_customer_sk,
                                                wr_returning_cdemo_sk, wr_returning_hdemo_sk,
                                                wr_returning_addr_sk,  wr_web_page_sk,
                                                wr_reason_sk,          wr_order_number,
                                                wr_return_quantity,    wr_return_amt,
                                                wr_return_tax,         wr_return_amt_inc_tax,
                                                wr_fee,                wr_return_ship_cost,
                                                wr_refunded_cash,      wr_reversed_charge,
                                                wr_amount_credit,      wr_net_loss) values (
                     '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                     '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                     '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                     '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                     '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                     '[Int_zero [lindex $in_items 18]]', '[Int_zero [lindex $in_items 19]]',
                     '[Int_zero [lindex $in_items 20]]', '[Int_zero [lindex $in_items 21]]',
                     '[Int_zero [lindex $in_items 22]]', '[Int_zero [lindex $in_items 23]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }



    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_warehouse    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "warehouse"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  warehouse ( w_warehouse_sk,   w_warehouse_id,
                                              w_warehouse_name, w_warehouse_sq_ft,
                                              w_street_number,  w_street_name,
                                              w_street_type,    w_suite_number,
                                              w_city,           w_county,
                                              w_state,          w_zip,            
                                              w_country,        w_gmt_offset) values (
                     '[Int_zero [lindex $in_items 0]]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',             '[Int_zero [lindex $in_items 3]]',
                     '[lindex $in_items 4]',             '[lindex $in_items 5]',
                     '[lindex $in_items 6]',             '[lindex $in_items 7]',
                     '[lindex $in_items 8]',             '[lindex $in_items 9]',
                     '[lindex $in_items 10]',            '[lindex $in_items 11]',
                     '[lindex $in_items 12]',            '[Int_zero [lindex $in_items 13]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }



    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_time_dim     {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "time_dim"
    set cmt_cnt  2000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  time_dim ( t_time_sk,   t_time_id,
                                             t_time,      t_hour,
                                             t_minute,    t_second,
                                             t_am_pm,     t_shift,
                                             t_sub_shift, t_meal_time) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_house_demo   {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "household_demographics"
    set cmt_cnt  250
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  household_demographics ( hd_demo_sk,       hd_income_band_sk,
                                                           hd_buy_potential, hd_dep_count,
                                                           hd_vehicle_count) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_s_returns    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "store_returns"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  store_returns ( sr_returned_date_sk, sr_return_time_sk,
                                                  sr_item_sk,          sr_customer_sk,
                                                  sr_cdemo_sk,         sr_hdemo_sk,
                                                  sr_addr_sk,          sr_store_sk,
                                                  sr_reason_sk,        sr_ticket_number,
                                                  sr_return_quantity,  sr_return_amt,
                                                  sr_return_tax,       sr_return_amt_inc_tax,
                                                  sr_fee,              sr_return_ship_cost,
                                                  sr_refunded_cash,    sr_reversed_charge,
                                                  sr_store_credit,     sr_net_loss) values (
                     '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                     '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                     '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                     '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                     '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                     '[Int_zero [lindex $in_items 18]]', '[Int_zero [lindex $in_items 19]]')"

        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }


    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_inventory    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "inventory"
    set cmt_cnt  5000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    return
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  inv ( inv_date_sk,      inv_item_sk,
                                        inv_warehouse_sk, inv_quanitity_on_hand) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_store        {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "store"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { 
                    set date_2 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" 
                    set date_3 "TO_DATE('[lindex $in_items 3]','YYYY-MM-dd')" 
                   }
            mssql  { 
                    set date_2 "'[lindex $in_items 2]'" 
                    set date_3 "'[lindex $in_items 3]'" 
                   }
        }
        set use_sql "insert into  store ( s_store_sk,         s_store_id,
                                          s_rec_start_date,   s_rec_end_date,
                                          s_closed_date_sk,   s_store_name,
                                          s_number_employees, s_floor_space,
                                          s_hours,            s_manager,
                                          s_market_id,        s_geography_class,
                                          s_market_desc,      s_market_manager,
                                          s_division_id,      s_division_name,
                                          s_company_id,       s_company_name,
                                          s_street_number,    s_street_name,
                                          s_street_type,      s_suite_number,
                                          s_city,             s_county,
                                          s_state,            s_zip,
                                          s_country,          s_gmt_offset,
                                          s_tax_percentage) values ( 
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     $date_2,
                     $date_3,
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '[lindex $in_items 18]', '[lindex $in_items 19]',
                     '[lindex $in_items 20]', '[lindex $in_items 21]',
                     '[lindex $in_items 22]', '[lindex $in_items 23]',
                     '[lindex $in_items 24]', '[lindex $in_items 25]',
                     '[lindex $in_items 26]', '[Int_zero [lindex $in_items 27]]',
                     '[Int_zero [lindex $in_items 28]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_c_sales      {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "catalog_sales"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  catalog_sales ( cs_sold_date_sk,          cs_sold_time_sk,
                                                  cs_ship_date_sk,          cs_bill_customer_sk,
                                                  cs_bill_cdemo_sk,         cs_bill_hdemo_sk,
                                                  cs_bill_addr_sk,          cs_ship_customer_sk,
                                                  cs_ship_cdemo_sk,         cs_ship_hdemo_sk,
                                                  cs_ship_addr_sk,          cs_call_center_sk,
                                                  cs_catalog_page_sk,       cs_ship_mode_sk,
                                                  cs_warehouse_sk,          cs_item_sk,
                                                  cs_promo_sk,              cs_order_number,
                                                  cs_quantity,              cs_wholesale_cost,
                                                  cs_list_price,            cs_sales_price,
                                                  cs_ext_discount_amt,      cs_ext_sales_price,
                                                  cs_ext_wholesale_cost,    cs_ext_list_price,
                                                  cs_ext_tax,               cs_coupon_amt,
                                                  cs_ext_ship_cost,         cs_net_paid,
                                                  cs_net_paid_inc_tax,      cs_net_paid_inc_ship,
                                                  cs_net_paid_inc_ship_tax, cs_net_profit) values (
                     '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                     '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                     '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                     '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                     '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                     '[Int_zero [lindex $in_items 18]]', '[Dbl_zero [lindex $in_items 19]]',
                     '[Dbl_zero [lindex $in_items 20]]', '[Dbl_zero [lindex $in_items 21]]',
                     '[Dbl_zero [lindex $in_items 22]]', '[Dbl_zero [lindex $in_items 23]]',
                     '[Dbl_zero [lindex $in_items 24]]', '[Dbl_zero [lindex $in_items 25]]',
                     '[Dbl_zero [lindex $in_items 26]]', '[Dbl_zero [lindex $in_items 27]]',
                     '[Dbl_zero [lindex $in_items 28]]', '[Dbl_zero [lindex $in_items 29]]',
                     '[Dbl_zero [lindex $in_items 30]]', '[Dbl_zero [lindex $in_items 31]]',
                     '[Dbl_zero [lindex $in_items 32]]', '[Dbl_zero [lindex $in_items 33]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_w_sales      {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "web_sales"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        incr line_in_cnt
        set in_items [split $line_in "\="]
        set use_sql "insert into  web_sales ( ws_sold_date_sk,          ws_sold_time_sk,
                                              ws_ship_date_sk,          ws_item_sk,
                                              ws_bill_customer_sk,      ws_bill_cdemo_sk,
                                              ws_bill_hdemo_sk,         ws_bill_addr_sk,
                                              ws_ship_customer_sk,      ws_ship_cdemo_sk,
                                              ws_ship_hdemo_sk,         ws_ship_addr_sk,
                                              ws_web_page_sk,           ws_web_site_sk,
                                              ws_ship_mode_sk,          ws_warehouse_sk,      
                                              ws_promo_sk,              ws_order_number,      
                                              ws_quantity,              ws_wholesale_cost,    
                                              ws_list_price,            ws_sales_price,       
                                              ws_ext_discount_amt,      ws_ext_sales_price,   
                                              ws_ext_wholesale_cost,    ws_ext_list_price,    
                                              ws_ext_tax,               ws_coupon_amt,        
                                              ws_ext_ship_cost,         ws_net_paid,          
                                              ws_net_paid_inc_tax,      ws_net_paid_inc_ship, 
                                              ws_net_paid_inc_ship_tax, ws_net_profit) values (
                     '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                     '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                     '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                     '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                     '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                     '[Int_zero [lindex $in_items 18]]', '[Int_zero [lindex $in_items 19]]',
                     '[Int_zero [lindex $in_items 20]]', '[Int_zero [lindex $in_items 21]]',
                     '[Int_zero [lindex $in_items 22]]', '[Int_zero [lindex $in_items 23]]',
                     '[Int_zero [lindex $in_items 24]]', '[Int_zero [lindex $in_items 25]]',
                     '[Int_zero [lindex $in_items 26]]', '[Int_zero [lindex $in_items 27]]',
                     '[Int_zero [lindex $in_items 28]]', '[Int_zero [lindex $in_items 29]]',
                     '[Int_zero [lindex $in_items 30]]', '[Int_zero [lindex $in_items 31]]',
                     '[Int_zero [lindex $in_items 32]]', '[Int_zero [lindex $in_items 33]]')"

        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_w_page       {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "web_page"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { 
                    set date_2 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" 
                    set date_3 "TO_DATE('[lindex $in_items 3]','YYYY-MM-dd')" 
                   }
            mssql  { 
                    set date_2 "'[lindex $in_items 2]'" 
                    set date_3 "'[lindex $in_items 3]'" 
                   }
        }
        set use_sql "insert into  web_page ( wp_web_page_sk,      wp_web_page_id,
                                             wp_rec_start_date,   wp_rec_end_date,
                                             wp_creation_date_sk, wp_access_date_sk,
                                             wp_autogen_flag,     wp_customer_sk,
                                             wp_url,              wp_type,
                                             wp_char_count,       wp_link_count,
                                             wp_image_count,      wp_max_ad_count) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     $date_2,
                     $date_3,
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_item {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "item"
    set cmt_cnt  1000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { 
                    set date_2 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" 
                    set date_3 "TO_DATE('[lindex $in_items 3]','YYYY-MM-dd')" 
                   }
            mssql  { 
                    set date_2 "'[lindex $in_items 2]'" 
                    set date_3 "'[lindex $in_items 3]'" 
                   }
        }
        set use_sql "insert into  item ( i_item_sk,        i_item_id,
                                         i_rec_start_date, i_rec_end_date,
                                         i_item_desc,      i_current_price,
                                         i_wholesale_cost, i_brand_id,
                                         i_brand,          i_class_id,
                                         i_class,          i_category_id,
                                         i_category,       i_manufact_id,
                                         i_manufact,       i_size,
                                         i_formulation,    i_color,
                                         i_units,          i_container,
                                         i_manager_id,     i_product_name) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     $date_2,
                     $date_3,
                     '[lindex $in_items 4]',             '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[lindex $in_items 8]',             '[Int_zero [lindex $in_items 9]]',
                     '[lindex $in_items 10]',            '[Int_zero [lindex $in_items 11]]',
                     '[lindex $in_items 12]',            '[Int_zero [lindex $in_items 13]]',
                     '[lindex $in_items 14]',            '[lindex $in_items 15]',
                     '[lindex $in_items 16]',            '[lindex $in_items 17]',
                     '[lindex $in_items 18]',            '[lindex $in_items 19]',
                     '[Int_zero [lindex $in_items 20]]', '[lindex $in_items 21]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
        
proc Load_c_returns    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "catalog_returns"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into catalog_returns ( cr_returned_date_sk,   cr_return_time_sk,
                                                   cr_item_sk,            cr_refunded_customer_sk,
                                                   cr_refunded_cdemo_sk,  cr_refunded_hdemo_sk,
                                                   cr_refunded_addr_sk,   cr_returning_customer_sk,
                                                   cr_returning_cdemo_sk, cr_returning_hdemo_sk,
                                                   cr_returning_addr_sk,  cr_call_center_sk,
                                                   cr_catalog_page_sk,    cr_ship_mode_sk,
                                                   cr_warehouse_sk,       cr_reason_sk,
                                                   cr_order_number,       cr_return_quantity,
                                                   cr_return_amount,      cr_return_tax,
                                                   cr_return_amt_inc_tax, cr_fee,
                                                   cr_return_ship_cost,   cr_refunded_cash,
                                                   cr_reversed_charge,    cr_store_credit,
                                                   cr_net_loss) values (
                                                   '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                                                   '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                                                   '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                                                   '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                                                   '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                                                   '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                                                   '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                                                   '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                                                   '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                                                   '[Dbl_zero [lindex $in_items 18]]', '[Dbl_zero [lindex $in_items 19]]',
                                                   '[Dbl_zero [lindex $in_items 20]]', '[Dbl_zero [lindex $in_items 21]]',
                                                   '[Dbl_zero [lindex $in_items 22]]', '[Dbl_zero [lindex $in_items 23]]',
                                                   '[Dbl_zero [lindex $in_items 24]]', '[Dbl_zero [lindex $in_items 25]]',
                                                   '[Dbl_zero [lindex $in_items 26]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_s_sales      {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "store_sales"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  store_sales ( ss_sold_date_sk,       ss_sold_time_sk,
                                                ss_item_sk,            ss_customer_sk,
                                                ss_cdemo_sk,           ss_hdemo_sk,
                                                ss_addr_sk,            ss_store_sk,
                                                ss_promo_sk,           ss_ticket_number,
                                                ss_quantity,           ss_wholesale_cost,
                                                ss_list_price,         ss_sales_price,
                                                ss_ext_discount_amt,   ss_ext_sales_price,
                                                ss_ext_wholesale_cost, ss_ext_list_price,
                                                ss_ext_tax,            ss_coupon_amt,
                                                ss_net_paid,           ss_net_paid_inc_tax,
                                                ss_net_profit) values (
                     '[Int_zero [lindex $in_items 0]]',  '[Int_zero [lindex $in_items 1]]', 
                     '[Int_zero [lindex $in_items 2]]',  '[Int_zero [lindex $in_items 3]]',
                     '[Int_zero [lindex $in_items 4]]',  '[Int_zero [lindex $in_items 5]]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]',  '[Int_zero [lindex $in_items 9]]',
                     '[Int_zero [lindex $in_items 10]]', '[Int_zero [lindex $in_items 11]]',
                     '[Int_zero [lindex $in_items 12]]', '[Int_zero [lindex $in_items 13]]',
                     '[Int_zero [lindex $in_items 14]]', '[Int_zero [lindex $in_items 15]]',
                     '[Int_zero [lindex $in_items 16]]', '[Int_zero [lindex $in_items 17]]',
                     '[Int_zero [lindex $in_items 18]]', '[Int_zero [lindex $in_items 19]]',
                     '[Int_zero [lindex $in_items 20]]', '[Int_zero [lindex $in_items 21]]',
                     '[Int_zero [lindex $in_items 22]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_c_demo       {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "customer_demographics"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  customer_demographics ( cd_demo_sk,           cd_gender,
                                                          cd_marital_status,    cd_education_status,
                                                          cd_purchase_estimate, cd_credit_rating,
                                                          cd_dep_count,         cd_dep_employed_count,
                                                          cd_dep_college_count) values (
                     '[Int_zero [lindex $in_items 0]]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',              '[lindex $in_items 3]',
                     '[Int_zero [lindex $in_items 4]]',  '[lindex $in_items 5]',
                     '[Int_zero [lindex $in_items 6]]',  '[Int_zero [lindex $in_items 7]]',
                     '[Int_zero [lindex $in_items 8]]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_date_dim     {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "date_dim"
    set cmt_cnt  1000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { set date_1 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" }
            mssql  { set date_1 "'[lindex $in_items 2]'" }
        }
        set date_1 
        set use_sql "insert into  date_dim ( d_date_sk,           d_date_id,
                                             d_date,              d_month_seq,
                                             d_week_seq,          d_quarter_seg,
                                             d_year,              d_dow,
                                             d_moy,               d_dom,
                                             d_qoy,               d_fy_year,
                                             d_fy_quarter_seq,    d_fy_week_seq,
                                             d_day_name,          d_quarter_name,
                                             d_holiday,           d_weekend,
                                             d_following_holiday, d_first_dom,
                                             d_last_dom,          d_same_day_1y,
                                             d_same_day_1q,       d_current_day,
                                             d_current_week,      d_current_month,
                                             d_current_quarter,   d_current_year) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                      $date_1,                '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '[lindex $in_items 18]', '[lindex $in_items 19]',
                     '[lindex $in_items 20]', '[lindex $in_items 21]',
                     '[lindex $in_items 22]', '[lindex $in_items 23]',
                     '[lindex $in_items 24]', '[lindex $in_items 25]',
                     '[lindex $in_items 26]', '[lindex $in_items 27]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_web_site     {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "web_site"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        switch $rdbms {
            oracle { 
                    set date_2 "TO_DATE('[lindex $in_items 2]','YYYY-MM-dd')" 
                    set date_3 "TO_DATE('[lindex $in_items 3]','YYYY-MM-dd')" 
                   }
            mssql  { 
                    set date_2 "'[lindex $in_items 2]'" 
                    set date_3 "'[lindex $in_items 3]'" 
                   }
        }
        set use_sql "insert into  web_site ( web_site_sk,        web_site_id,
                                             web_rec_start_date, web_rec_end_date,
                                             web_name,           web_open_date_sk,
                                             web_close_date_sk,  web_class,
                                             web_manager,        web_mkt_id,
                                             web_mkt_class,      web_mkt_desc,
                                             web_market_manager, web_company_id,
                                             web_company_name,   web_street_number,
                                             web_street_name,    web_street_type,
                                             web_suite_number,   web_city,
                                             web_county,         web_state,
                                             web_zip,            web_country,
                                             web_gmt_offset,     web_tax_percentage) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     $date_2,
                     $date_3,
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[lindex $in_items 14]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]',
                     '[lindex $in_items 18]', '[lindex $in_items 19]',
                     '[lindex $in_items 20]', '[lindex $in_items 21]',
                     '[lindex $in_items 22]', '[lindex $in_items 23]',
                     '[lindex $in_items 24]', '[lindex $in_items 25]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_c_address    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "customer_address"
    set cmt_cnt  1000
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  customer_address ( ca_address_sk,    ca_address_id,
                                                     ca_street_number, ca_street_name,
                                                     ca_street_type,   ca_suite_number,
                                                     ca_city,          ca_county,
                                                     ca_state,         ca_zip,
                                                     ca_country,       ca_gmt_offset,
                                                     ca_location_type) values (
                     '[Int_zero [lindex $in_items 0]]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[Dbl_zero [lindex $in_items 11]]',
                     '[lindex $in_items 12]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_ship_mode    {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "ship_mode"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  ship_mode ( sm_ship_mode_sk, sm_ship_mode_id,
                                              sm_type, sm_code,
                                              sm_carrier, sm_contract) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_customer     {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "customer"
    set cmt_cnt  2500
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  customer ( c_customer_sk,         c_customer_id,
                                             c_current_cdemo_sk,    c_current_hdemo_sk,
                                             c_current_addr_sk,     c_first_shipto_date_sk,
                                             c_first_sales_date_sk, c_salutation,
                                             c_first_name,          c_last_name,
                                             c_preferred_cust_flag, c_birth_day,
                                             c_birth_month,         c_birth_year,
                                             c_birth_country,       c_login,
                                             c_email_address,       c_last_review_date) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]',  '[lindex $in_items 3]',
                     '[lindex $in_items 4]',  '[lindex $in_items 5]',
                     '[lindex $in_items 6]',  '[lindex $in_items 7]',
                     '[lindex $in_items 8]',  '[lindex $in_items 9]',
                     '[lindex $in_items 10]', '[lindex $in_items 11]',
                     '[lindex $in_items 12]', '[lindex $in_items 13]',
                     '[Double_single [lindex $in_items 14]]', '[lindex $in_items 15]',
                     '[lindex $in_items 16]', '[lindex $in_items 17]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
proc Load_income_band  {log_id rdbms dbhandle hodbc dbcur file_in xlevel} {

    set sec_name "income_band"
    set cmt_cnt  100
    Enter_log_tag $log_id "S" $sec_name 1 xlevel
    set data_id [Open_data_file $log_id $sec_name $file_in]

    set i 1
    while {[gets $data_id line_in] >= 0 } {
        set in_items [split $line_in "\="]
        set use_sql "insert into  income_band ( ib_income_band_sk, ib_lower_bound,
                                                ib_upper_bound) values (
                     '[lindex $in_items 0]',  '[lindex $in_items 1]', 
                     '[lindex $in_items 2]')"
        RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
        if { ![expr {$i % $cmt_cnt} ]} {
            Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
            Enter_log_item $log_id "loaded" $i  $xlevel
        }
        incr i

    }

    Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
    Enter_log_tag $log_id "E" $sec_name 1 xlevel
    close $data_id
    return

}
#  tools/dsdgen -scale 1 -parallel 16 -delimiter \= -dir 1G_DEL_P16 -child 16 &
#  #  tools/dsdgen -scale 1 -parallel 16 -delimiter \= -dir 1G_DEL_P1 -child 1 &
#  #  tools/dsdgen -scale 1 -delimiter \= -dir 1G &
#  #  tools/dsdgen -scale 1 -parallel 16 -delimiter \= -dir 1G_16P5 -child 5 &
#  #  history | grep dsd
#

# -- start query 1 in stream 0 using template query36.tpl
# -- end query 1 in stream 0 using template query36.tpl

proc Run_power_stream {rdbms database_name connect query_id log_id } {

    set sec_name "query_stream" 
    set verbose 0
    set q_time 0.00
    set t_time 0.00
    set qsnum 0
    set xlevel 2

    Put_thread_header $log_id $sec_name

    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    "db_ds"

    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

    Auto_on_off $rdbms $hodbc $dbhandle "off"

    Enter_log_item $log_id "stream_number" $qsnum $xlevel
    set start_total_ms [clock milliseconds]
    while {[gets $query_id line_in] >= 0 } {
        if {[string first "-- start query " $line_in] >= 0 } {
            set in_items [split $line_in " "]
            Enter_log_tag $log_id "S" "query" 0 xlevel
            Enter_log_item $log_id "count" [lindex $in_items 3] $xlevel
            scan [lindex $in_items 9]] "query%d.tpl" temp_num
            Enter_log_item $log_id "template" $temp_num $xlevel
            set query_in ""
            continue
        }
        if {[string first "-- end query " $line_in] >= 0 } {
            if {$verbose} {Enter_log_item $log_id "query_string" $query_in $xlevel}
            set start_query_ms [clock milliseconds]
            Enter_log_item $log_id "time_start" [MS_tppc_stamp $start_query_ms] $xlevel
            while {[string first ";" $query_in] != [string last ";" $query_in] } {
                set f_semi [string first ";" $query_in]
                set query_todo [string range $query_in 0 $f_semi]
                set query_in [string range $query_in [ expr {$f_semi+1}] end]
                set query_todo [string map {{;} { }} $query_todo]
                DS_sql $rdbms $log_id $sec_name $hodbc $dbcur $query_todo $xlevel
            }

            set query_in [string map {{;} { }} $query_in]
            DS_sql $rdbms $log_id $sec_name $hodbc $dbcur $query_in $xlevel
            set end_query_ms [clock milliseconds]
            Enter_log_item $log_id "time_end" [MS_tppc_stamp $end_query_ms] $xlevel
            set q_time [expr { $end_query_ms - $start_query_ms}]
            Enter_log_item $log_id "msec" $q_time $xlevel
            Enter_log_tag $log_id "E" "query" 0 xlevel
            continue
        }

        append query_in "\n" $line_in

    }
    set end_total_ms [clock milliseconds]
    set t_time [expr { $end_total_ms - $start_total_ms}]
    Enter_log_item $log_id "total_msec" $t_time $xlevel

    Disconnect_from_DB $log_id $rdbms $hodbc $dbhandle $xlevel
    
    Put_thread_footer $log_id $sec_name
    return
}

proc Run_query_stream {qsnum rdbms database_name connect query_id parallel log_id } {

    set max_update_set [expr {$parallel/2} ]
    
    set sec_name "query_stream" 
    set verbose 0
    set verbose2 0
    set q_time 0.00
    set t_time 0.00
    Put_thread_header $log_id $sec_name
    set xlevel 2

    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    "db_ds"

    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

    Auto_on_off $rdbms $hodbc $dbhandle "off"
    
    Enter_log_item $log_id "stream_number" $qsnum $xlevel
    set start_total_ms [clock milliseconds]
    while {[gets $query_id line_in] >= 0 } {
        if {[string first "-- start query " $line_in] >= 0 } {
            set in_items [split $line_in " "]
            Enter_log_tag $log_id "S" "query" 0 xlevel
            Enter_log_item $log_id "count" [lindex $in_items 3] $xlevel
            scan [lindex $in_items 9]] "query%d.tpl" temp_num
            Enter_log_item $log_id "template" $temp_num $xlevel
            set query_in ""
            continue
        }
        if {[string first "-- end query " $line_in] >= 0 } {

            if {[tsv::get tasks c_up_set] < [expr {$parallel/2}]} {
                set waiting_cnt  [expr {(3*$parallel)+([tsv::get tasks c_up_set]*192)+1}] 
            } else {
                set waiting_cnt 999999
            }
            if {$verbose2} {
                    Enter_log_item $log_id "query_cnt" [tsv::get tasks query_cnt] $xlevel
                    Enter_log_item $log_id "current_update_set" [tsv::get tasks c_up_set] $xlevel
                    Enter_log_item $log_id "waiting_for" $waiting_cnt $xlevel
            }

            while { [tsv::get tasks query_cnt] > $waiting_cnt } {
                after 10
                if {[tsv::get tasks c_up_set] < [expr {$parallel/2}]} {
                    set waiting_cnt  [expr {(3*$parallel)+([tsv::get tasks c_up_set]*192)+1}] 
                } else {
                    set waiting_cnt 999999
                }
            }

            tsv::incr tasks query_cnt 

            set start_query_ms [clock milliseconds]
            Enter_log_item $log_id "time_start" [MS_tppc_stamp $start_query_ms] $xlevel
            while {[string first ";" $query_in] != [string last ";" $query_in] } {
                set f_semi [string first ";" $query_in]
                set query_todo [string range $query_in 0 $f_semi]
                set query_in [string range $query_in [ expr {$f_semi+1}] end]
                set query_todo [string map {{;} { }} $query_todo]
                DS_sql $rdbms $log_id $sec_name $hodbc $dbcur $query_todo $xlevel
            }

            set query_in [string map {{;} { }} $query_in]
            DS_sql $rdbms $log_id $sec_name $hodbc $dbcur $query_todo $xlevel
            set end_query_ms [clock milliseconds]
            Enter_log_item $log_id "time_end" [MS_tppc_stamp $end_query_ms] $xlevel
            set q_time [expr { $end_query_ms - $start_query_ms}]
            Enter_log_item $log_id "msec" $q_time $xlevel
            Enter_log_tag $log_id "E" "query" 0 xlevel
            continue
        }


        append query_todo "\n" $line_in

    }
    set end_total_ms [clock milliseconds]
    set t_time [expr { $end_total_ms - $start_total_ms}]
    Enter_log_item $log_id "total_msec" $t_time $xlevel
    Put_thread_footer $log_id $sec_name
    set r_id [thread::id]
    thread::release
}

proc xRun_query_stream {qsnum rdbms database_name connect query_id parallel log_id } {

    set max_update_set [expr {$parallel/2} ]
    
    set sec_name "query_stream" 
    set verbose 0
    set verbose2 0
    set q_time 0.00
    set t_time 0.00
    Put_thread_header $log_id $sec_name
    set xlevel 2

    set dbhandle "NOT USED"
    set dbcur    "NOT USED"
    set hodbc    "db_ds"

    DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

    Auto_on_off $rdbms $hodbc $dbhandle "off"
    
    Enter_log_item $log_id "stream_number" $qsnum $xlevel
    set start_total_ms [clock milliseconds]
    while {[gets $query_id line_in] >= 0 } {
        if {[string first "-- start query " $line_in] >= 0 } {
            set in_items [split $line_in " "]
            Enter_log_tag $log_id "S" "query" 0 xlevel
            Enter_log_item $log_id "count" [lindex $in_items 3] $xlevel
            scan [lindex $in_items 9]] "query%d.tpl" temp_num
            Enter_log_item $log_id "template" $temp_num $xlevel
            set query_in ""
            continue
        }
        if {[string first "-- end query " $line_in] >= 0 } {
            
            if {[tsv::get tasks c_up_set] < [expr {$parallel/2}]} {
                set waiting_cnt  [expr {(3*$parallel)+([tsv::get tasks c_up_set]*192)+1}] 
            } else {
                set waiting_cnt 999999
            }
            if {$verbose2} {
                    Enter_log_item $log_id "query_cnt" [tsv::get tasks query_cnt] $xlevel
                    Enter_log_item $log_id "current_update_set" [tsv::get tasks c_up_set] $xlevel
                    Enter_log_item $log_id "waiting_for" $waiting_cnt $xlevel
            }

            while { [tsv::get tasks query_cnt] > $waiting_cnt } {
                after 10
                if {[tsv::get tasks c_up_set] < [expr {$parallel/2}]} {
                    set waiting_cnt  [expr {(3*$parallel)+([tsv::get tasks c_up_set]*192)+1}] 
                } else {
                    set waiting_cnt 999999
                }
            }

            tsv::incr tasks query_cnt 

            if {$verbose} {Enter_log_item $log_id "query_string" $query_in $xlevel}
            set start_query_ms [clock milliseconds]
            after [expr {int(rand() * 100)}]
            DS_sql $rdbms $log_id $sec_name $hodbc $dbcur $query_in $xlevel
            set end_query_ms [clock milliseconds]
            set q_time [expr { $end_query_ms - $start_query_ms}]
            Enter_log_item $log_id "msec" $q_time $xlevel
            Enter_log_tag $log_id "E" "query" 0 xlevel
            continue
        }

        append query_todo $line_in

    }
    set end_total_ms [clock milliseconds]
    set t_time [expr { $end_total_ms - $start_total_ms}]
    Enter_log_item $log_id "total_msec" $t_time $xlevel
    Put_thread_footer $log_id $sec_name
    set r_id [thread::id]
    thread::release
}

proc Run_tpcds_updates {log_id database_name f_connect update_dir} {
    set update_list {delete inventory_delete s_call_center s_catalog_order \
                     s_catalog_order_lineitem  s_catalog_page s_catalog_returns s_customer \
                     s_customer_address s_inventory s_item s_promotion s_purchase \
                     s_purchase_lineitem s_store s_store_returns s_warehouse s_web_order \
                     s_web_order_lineitem  s_web_page s_web_returns s_web_site s_zip_to_gmt }

    set sec_name "updates"
    Put_thread_header $log_id $sec_name
    set xlevel 2
    Enter_log_item $log_id "update_directory" $update_dir $xlevel

    set db_scale [tsv::get tasks db_scale ]
    set parallel [tsv::get tasks parallel]
    set run_id   [tsv::get tasks run_id ]

    if {[string tolower $update_dir] == "local" } {
        set query_dir [file join $log_dir "UpdateData"]
    }

    set last_up_cnt [expr {$parallel/2}]

    for {set i 0 } { $i < $last_up_cnt } { incr i } {
        if {$run_id == 1} {
            set update_set [expr {$i+1}]
        } else {
            set update_set [expr {$i+1} + $last_up_cnt]
        }

        set launch [expr {($parallel*3)  + ($i*192)} ]

        Enter_log_item $log_id "wait_for_launch" $launch $xlevel

        while { [tsv::get tasks query_cnt] <= $launch } {
            after 10
        }

        Enter_log_tag  $log_id "S" "update_set" 1 xlevel
        Enter_log_item $log_id "query_cnt" [tsv::get tasks query_cnt] $xlevel
        Enter_log_item $log_id "launch" $launch $xlevel
        Enter_log_item $log_id "set_number" $update_set $xlevel
        Enter_log_tag  $log_id "E" "update_set" 1 xlevel
        tsv::incr tasks c_up_set 
        # Add incr to current update

    }
    Put_thread_footer $log_id $sec_name
    set r_id [thread::id]
    thread::release
}

#
# To run a tpcds throughput test
#
proc Run_tpcds_throughput {sec_name log_id rdbms database_name connect parallel db_scale maxdop log_dir query_dir update_dir run_id } {

    set xlevel 2
    set throughput_dir [file join $log_dir [format "Throughput_%d" $run_id]]
    if {[catch [file mkdir $throughput_dir] file_err ] } {
        Enter_log_item $log_id "ERROR" "Unable to make throughput run output directory" $xlevel
        Error_out $log_id $sec_name
    }
    if {$run_id > 2 || $run_id < 1} {
        Enter_log_item $log_id "ERROR" "Throughput can only be 1 or 2" $xlevel
        Error_out $log_id $sec_name
    }


#
# Set mutex so that nobody starts before they are all ready
#
    set run_cond  [tsv::set tasks run_cond  [thread::cond create]]
    set run_mutex [tsv::set tasks run_mutex [thread::mutex create]]
    tsv::set tasks query_cnt 0
    tsv::set tasks db_scale $db_scale
    tsv::set tasks parallel $parallel
    tsv::set tasks run_id $run_id
    tsv::set tasks c_up_set 0
    thread::mutex lock $run_mutex

    set f_connect [Quote_slash $connect]

#
# create thread for updates
#
    set log_file  [file join $throughput_dir "update.xml" ]
    if [catch {open $log_file w} tlog_id] {
        Enter_log_item $log_id "ERROR" "Unable to open logfile $log_file" $xlevel
        Error_out $log_id $sec_name
    }
    set t_list(0) [thread::create -joinable {thread::wait}]
    thread::transfer $t_list(0) $tlog_id
    Load_sources $t_list(0) $rdbms "auto_tpcds.tcl"
    eval [subst {thread::send -async $t_list(0) {   \
        Run_tpcds_updates $tlog_id $database_name $f_connect $update_dir } r_id } ]
#
# Now create the query threads
#
    for {set qsnum 1} {$qsnum <= $parallel} {incr qsnum } {
    
        set log_file  [file join $throughput_dir [format "stream_%04d.xml" $qsnum]]
        if [catch {open $log_file w} tlog_id] {
            Enter_log_item $log_id "ERROR" "Unable to open logfile $log_file" $xlevel
            Error_out $log_id $sec_name
        }
    
        set query_file [file join $query_dir [format "query_%d.sql" $qsnum]]
        if [catch {open $query_file r} query_id] {
            Enter_log_item $log_id "ERROR" "Unable to open query file $query_file" $xlevel
            Error_out $log_id $sec_name
        }
        set t_list($qsnum) [thread::create -joinable {thread::wait}]
        #
        # The load up the source code do this sync so that they happen one after another
        #   
        thread::transfer $t_list($qsnum) $tlog_id
        thread::transfer $t_list($qsnum) $query_id
        Load_sources $t_list($qsnum) $rdbms "auto_tpcds.tcl"
        #
        # And run the database thread -async so they happen together
        #                                                                                    #
    
        eval [subst {thread::send -async $t_list($qsnum) {   \
            Run_query_stream $qsnum $rdbms $database_name $f_connect $query_id $parallel $tlog_id } r_id } ]
    
    }
#
# OK, now send for everybody to start at the same time
#
    tsv::set tasks predicate 1
    thread::cond notify $run_cond
    thread::mutex unlock $run_mutex

#
# Setup to launch the query updates at the correct times.
#
    
#
# Wait for everybody (threads) before repeating
#
    while {1} {
        if {[llength [thread::names]] <= 1} { break }
        after 50
    }
    thread::cond destroy  $run_cond
    thread::mutex destroy $run_mutex
    return
}

proc Run_tpcds_power {sec_name log_id rdbms database_name connect maxdop log_dir query_dir } {

    set xlevel 2
    set power_dir [file join $log_dir "Power" ]
    if {[catch [file mkdir $power_dir] file_err ] } {
        Enter_log_item $log_id "ERROR" "Unable to make power run output directory" $xlevel
        Error_out $log_id $sec_name
    }

    set log_file  [file join $power_dir "power_log.xml" ]
    if {[catch {open $log_file w} log_id]} {
        Enter_log_item $log_id "ERROR" "Unable to open logfile $log_file" $xlevel
        Error_out $log_id $sec_name
    }

    if {$query_dir == "test" } {
        set query_file [file join $log_dir "Queries" "query_0.sql"]
    } else {
        puts "Using >>>$query_dir<<<"
        set query_file [file join $query_dir "query_0.sql" ]
    }
    if [catch {open $query_file r} query_id] {
        Enter_log_item $log_id "ERROR" "Unable to open query file $query_file" $xlevel
        Error_out $log_id $sec_name
    }


    Run_power_stream $rdbms $database_name $connect $query_id $log_id 

    return
}

#
# Distributed under GPL 2.2
# Copyright Steve Shaw 2003-2012
# Copyright Tim Witham 2012
# 
proc Get_time {} {
	set ts_ms [clock milliseconds]
	set ts_sec [expr {$ts_ms/1000}]
	set ts_ts [expr {($ts_ms % 1000)/100}]
	set tstamp [format "[clock format $ts_sec -format "%Y-%m-%dT%H:%M:%S"].%1d" $ts_ts]
	return $tstamp
}

proc Do_batch { log_id rdbms database_name dbhandle hodbc dbcur table file_in xlevel} {
	Enter_log_tag $log_id "S" $table 1 xlevel
	set rdbms [string tolower $rdbms]
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

proc File_loader {sec_name log_id rdbms load_threads database_name connect base_log_dir data_location } {
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set hodbc    "db_main"
	set xlevel 1
	if {$load_threads == 1 } {
		Enter_log_item $log_id "ERROR" "Batch load only supported in parallel mode" $xlevel
		Error_out $log_id $sec_name
	}

	if {[string tolower $data_location] == "local" } {
		set base_data_dir [file join [pwd] $base_log_dir "load_data"]
    } else {
		set f_char [string tolower [string range $data_location 0 0 ]]
		set s_char [string tolower [string range $data_location 1 1 ]]
		if {$f_char == "/" || $s_char == ":"} {
			set base_data_dir $data_location
		} else {
			set base_data_dir [file join [pwd] [file tail $data_location] ]
		}
	}
	
	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"
	Enter_log_item $log_id "tpcc_table_batch_load" "start" $xlevel
	Enter_log_tag  $log_id "S" "loading_item" 1 xlevel
	set data_file_is [file join $base_data_dir "item.dat"]
	Do_batch  $log_id $rdbms $database_name $dbhandle $hodbc $dbcur "item" $data_file_is $xlevel
	Enter_log_tag  $log_id "E" "loading_item" 1 xlevel

	Enter_log_tag $log_id "S" "running_threads" 1 xlevel
	set f_connect [Quote_slash $connect]
	set base_sec_dir [file join $base_log_dir $sec_name]
	file mkdir $base_sec_dir

	set l_thread 1
	while {$l_thread <= $load_threads } { 
		set tlog_id [Create_thread_log  $log_id $sec_name $l_thread $base_sec_dir "tlog_%05d.xml" $xlevel ]
		set t_list($l_thread) [thread::create -joinable {thread::wait}]
		thread::transfer $t_list($l_thread) $tlog_id
		Load_sources $t_list($l_thread) $rdbms "auto_tpcc.tcl"
		eval [subst {thread::send -async $t_list($l_thread) { \
			Batch_thread $tlog_id $l_thread $sec_name $rdbms $database_name $f_connect $base_data_dir } r_id } ]
		Enter_log_item $log_id "running_thread" $l_thread $xlevel

		incr l_thread 
	}
	set tfin 0

	while {[llength [thread::names]] > 1} {
		after 500
	}

	Auto_on_off $rdbms $hodbc $dbhandle "on"
	Enter_log_tag $log_id "E" "running_threads" 1 xlevel
	return
	
}

proc Batch_thread {tlog_id l_thread sec_name rdbms database_name f_connect base_data_dir } {
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set hodbc    [format "db_%d" $l_thread]
	set xlevel 1
	DB_use $tlog_id $sec_name "test" $rdbms $database_name $f_connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"

	set table_list [list "warehouse" "district" "customer" "stock" "orders" "order_line" "new_order" "history"]
	foreach l_table $table_list {
		Enter_log_tag  $tlog_id "S" [format "loading_%s" $l_table] 1 xlevel
		set data_file_is [file join $base_data_dir [format "%s_%04d.dat" $l_table $l_thread]]
		Do_batch  $tlog_id $rdbms $database_name $dbhandle $hodbc $dbcur $l_table $data_file_is $xlevel
		Enter_log_tag  $tlog_id "E" [format "loading_%s" $l_table] 1 xlevel
	}
	set r_id [thread::id]
	thread::release

}
	


proc Load_tpcc {sec_name log_id load_type rdbms threads warehouses database_name base_log_dir connect cmd_dir} {
# Set the parameters for a build
#	Smaller value for testing
#	set MAXITEMS 10000
#
	set MAXITEMS 100000
	set CUST_PER_DIST 3000
	set DIST_PER_WARE 10
	set ORD_PER_DIST 3000
	set ex_ware 0
	set ware_step 0
	set xlevel 1

# Put in the log entries
	Enter_log_item $log_id "tpcc_table_load" "start" $xlevel
	Enter_log_item $log_id "creating" [format "%d warehouses" $warehouses] $xlevel
	set load_type [string tolower $load_type]
	set gen_files 0
	set base_sec_dir [file join $base_log_dir $sec_name]
	switch $load_type {
		"generate" { 
				Enter_log_item $log_id "generating" "Will create data files for bulk loader" $xlevel 
				set gen_files 1
				set base_sec_dir [file join $base_log_dir "load_data"]
        }
		"inline"   { Enter_log_item $log_id "inserting" "Will generate and insert in one operation" $xlevel }
		default { Enter_log_item $log_id "WARNING" "You didn't specify either generate or inline so inline is being used" $xlevel}
	}
# make the log or data directory for the threads
	file mkdir $base_sec_dir

# connect to the database and set some options
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set hodbc    "db_main"
	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"
# Load the item single stream
	Enter_log_tag  $log_id "S" "loading_item" 1 xlevel
	if {$gen_files == 1 } {
		Enter_log_tag  $log_id "S" "generating_item" 1 xlevel
		set data_file [file join $base_sec_dir "item.dat"]
		set data_id [open $data_file w]
		LoadItems $data_id $gen_files $rdbms "loading_item" $hodbc $dbhandle $dbcur $MAXITEMS $xlevel
		Enter_log_tag  $log_id "E" "generating_item" 1 xlevel
	} else  {
		Enter_log_tag  $log_id "S" "loading_item" 1 xlevel
		LoadItems $log_id $gen_files $rdbms "loading_item" $hodbc $dbhandle $dbcur $MAXITEMS $xlevel
		Enter_log_tag $log_id "E" "loading_item" 1 xlevel
	}
	
# Make sure that the threads will be well ballanced
	Align_thread_count $log_id 
# Setup the needed parameters for the threads
	set c_ware 1
	set l_thread 1
	#
	# make sure any \ are turned into \\
	#
	set f_connect [Quote_slash $connect]

	Enter_log_tag $log_id "S" "running_threads" 1 xlevel
	while {$l_thread <= $threads } { 
		#
		# Create and start the log for the new thread
		#
		set tlog_id [Create_thread_log  $log_id $sec_name $l_thread $base_sec_dir "tlog_%05d.xml" $xlevel ]
		#
		# set the warehouse thread start and stop using up the "extras" first
		#
		#
		set ware_start [expr {(($l_thread-1)*$ware_step)+1}]
		set ware_end   [expr {($l_thread*$ware_step)}]
		#Create a new thread that waits for the needed routines
		#
		set t_list($l_thread) [thread::create -joinable {thread::wait}]
		#
		# The load up the source code do this sync so that they happen one after another
		#	
		thread::transfer $t_list($l_thread) $tlog_id
		Load_sources $t_list($l_thread) $rdbms "auto_tpcc.tcl"
		#
		# And run the database build thread -async so they happen together
		#
		eval [subst {thread::send -async $t_list($l_thread) { \
			Build_thread $tlog_id $gen_files $l_thread $sec_name $rdbms $database_name $f_connect \
			             $base_sec_dir $ware_start $ware_end $MAXITEMS $CUST_PER_DIST \
				     	 $DIST_PER_WARE $ORD_PER_DIST } r_id } ]
		# 
		# Record that it got started
		#
		Enter_log_item $log_id "running_thread" [format "%d start ware >>%d<< end ware >>%d<<" $l_thread $ware_start $ware_end ] $xlevel

		incr l_thread 1
		incr c_ware $ware_step
	}

	flush stdout
	set tfin 0

	while {[llength [thread::names]] > 1} {
		after 500
	}

	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 3
	Enter_log_tag $log_id "E" "running_threads" 1 xlevel
	Auto_on_off $rdbms $hodbc $dbhandle "off"
	return
}

proc Build_thread {tlog_id gen_files thread sec_name rdbms database_name connect base_sec_dir ware_start ware_end MAXITEMS CUST_PER_DIST DIST_PER_WARE ORD_PER_DIST } {
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set xlevel 2

	set hodbc [format "dbh_%d" $thread]

	DB_use $tlog_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"
		
	Enter_log_tag  $tlog_id "S" "loading_warehouses" 1 xlevel
	Enter_log_item $tlog_id "start_warehouse" $ware_start $xlevel
	Enter_log_item $tlog_id "end_warehouse" $ware_end $xlevel
	LoadWare $tlog_id $gen_files $thread $rdbms $hodbc $dbhandle $dbcur $sec_name $base_sec_dir $ware_start $ware_end $MAXITEMS $DIST_PER_WARE $xlevel
	Enter_log_tag  $tlog_id "E" "loading_warehouses" 1 xlevel
	Enter_log_tag  $tlog_id "S" "loading_customers"  1 xlevel
	LoadCust $tlog_id $gen_files $thread $rdbms $hodbc $dbhandle $dbcur $sec_name $base_sec_dir $ware_start $ware_end $CUST_PER_DIST $DIST_PER_WARE $xlevel
	Enter_log_tag  $tlog_id "E" "loading_customers"  1 xlevel
	Enter_log_tag  $tlog_id "S" "loading_orders"     1 xlevel
	LoadOrd $tlog_id $gen_files $thread $rdbms $hodbc $dbhandle $dbcur $sec_name $base_sec_dir $ware_start $ware_end $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $xlevel
	Enter_log_tag  $tlog_id "E" "loading_orders"     1 xlevel
	# end of the routine
	Put_thread_footer $tlog_id $sec_name
	flush $tlog_id
	close $tlog_id
	set r_id [thread::id]
	thread::release
	return
}


proc Align_thread_count {log_id} {
	upvar threads lthreads
	upvar warehouses lwarehouses
	upvar ex_ware lex_ware
	upvar ware_step lware_step
	set xlevel 1
	if {$lthreads > $lwarehouses}  {
		set ltheads $lwarehouses
		Enter_log_item $log_id "changing" [format "No more theads than warehouses, threads now %d" $lthreads] $xlevel
	}
	set lex_ware [expr {$lwarehouses % $lthreads}]
	if {$lex_ware != 0 } {
		Enter_log_item $log_id "extra_warehouses" \
		[format "ERROR: Number of threads does not divide evenly into number of warehouses - please try again"
		[expr {$xlevel + 1}]
		exit
	}
	set lware_step [expr {($lwarehouses-$lex_ware) / $lthreads }]
}
proc xAlign_thread_count {log_id} {
	upvar threads lthreads
	upvar warehouses lwarehouses
	upvar ex_ware lex_ware
	upvar ware_step lware_step
	set xlevel 1
	if {$lthreads > $lwarehouses}  {
		set ltheads $lwarehouses
		Enter_log_item $log_id "changing" [format "No more theads than warehouses, threads now %d" $lthreads] $xlevel
	}
	set lex_ware [expr {$lwarehouses % $lthreads}]
	if {$lex_ware != 0 } {
		Enter_log_item $log_id "extra_warehouses" \
		[format "Number of threads does not divide evenly into number of warehouses, %d theads with one extra" $lex_ware] \
		[expr {$xlevel + 1}]
	}
	set lware_step [expr {($lwarehouses-$lex_ware) / $lthreads }]
}

proc Lastname { num namearr } {
	set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ] \
	                  [ lindex $namearr [ expr {( $num / 10 ) % 10 }] ]  \
			  [ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
	# Fix to ensure that the last name is never longer than 16 characters
	if {[string length $name] <= 16} {
		return $name
	} else {
		return [string range $name 0 15]
	}
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
	return [ list [ MakeAlphaString 10 20 $chArray $chalen ] \
	              [ MakeAlphaString 10 20 $chArray $chalen ] \
		      [ MakeAlphaString 10 20 $chArray $chalen ] \
		      [ MakeAlphaString 2 2 $chArray $chalen ]   \
		      [ Makezip ] ]
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
	

proc LoadItems { log_id gen_files rdbms sec_name hodbc dbhandle dbcur MAXITEMS xlevel} {
	set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T \
			     U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
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
		if { $gen_files == 1  } {
				puts $log_id "$i_id=$i_name=$i_price=$i_data=$i_im_id="
		} else  {
			set use_sql "insert into item (i_id, i_im_id, i_name, i_price, i_data) \
		     	VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')" 
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0

      		if { ![ expr {$i_id % 50000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
				Enter_log_item $log_id "loaded"  $i_id $xlevel
			}
		}
	}
	if { $gen_files == 1 }  {
		close $log_id
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
	}
	return
}

proc LoadWare { log_id gen_files thread rdbms hodbc dbhandle dbcur sec_name base_sec_dir ware_start count_ware MAXITEMS DIST_PER_WARE xlevel} {
	set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
	set w_ytd 3000000.0

	if {$gen_files == 1 } {
		set n_file [file join $base_sec_dir [format "warehouse_%04d.dat" $thread]]
		set w_fid [open $n_file w]
		set n_file [file join $base_sec_dir [format "stock_%04d.dat" $thread]]
		set s_fid [open $n_file w]
		set n_file [file join $base_sec_dir [format "district_%04d.dat" $thread]]
		set d_fid [open $n_file w]
	} else {
		set w_fid "NOT_USED"
		set s_fid "NOT_USED"
		set d_fid "NOT_USED"
	}

	for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
		set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
		set add [ MakeAddress $globArray $chalen ]
		set w_tax_ran [ RandomNumber 10 20 ]
		set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
		if {$gen_files == 1 } {
			puts $w_fid "$w_id=$w_ytd=$w_tax=$w_name=[lindex $add 0]=[lindex $add 1]=[lindex $add 2]=[lindex $add 3]=[lindex $add 4]="
			Enter_log_item $log_id "generating_district_stock" $w_id $xlevel
	 	} else {
			set use_sql "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values \
		                ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , \
					    '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
			Enter_log_item $log_id "loading_district_stock" $w_id $xlevel
		}
		Stock $log_id $gen_files $s_fid $rdbms $hodbc $dbhandle $dbcur $sec_name $w_id $MAXITEMS $xlevel
		District $log_id $gen_files $d_fid $rdbms $hodbc $dbhandle $dbcur $sec_name $w_id $DIST_PER_WARE $xlevel
		Enter_log_item  $log_id "district_done" $w_id $xlevel
		if {$gen_files == 0} { Commit_sql $log_id $rdbms $hodbc $dbhandle "Commit_SQL" 1 $xlevel }
	}
	if {$gen_files == 1  } {
		close $w_fid
		close $s_fid
		close $d_fid
	}
	return
}

proc Stock { log_id gen_files s_fid rdbms hodbc dbhandle dbcur sec_name w_id MAXITEMS xlevel} {
	set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
	set bld_cnt 1
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
		append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', \
		                 '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', \
				 '$s_dist_10', '$s_data', '0', '0', '0')
		incr bld_cnt
		if {$gen_files == 1} {
			puts $s_fid "$s_i_id=$s_w_id=$s_quantity=0=0=0=$s_data=$s_dist_01=$s_dist_02=$s_dist_03=$s_dist_04=$s_dist_05=$s_dist_06=$s_dist_07=$s_dist_08=$s_dist_09=$s_dist_10="
	   		if { ![ expr {$s_i_id % 20000} ] } {
				Enter_log_item $log_id "generating_stock" $s_i_id $xlevel
			}
		} else {
			set use_sql "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, \
		                s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, \
			            s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
	   		if { ![ expr {$s_i_id % 20000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
				Enter_log_item $log_id "loading_stock" $s_i_id $xlevel
			}
		}
		set bld_cnt 1
		unset val_list
	}
	if {$gen_files == 1} {
		Enter_log_item $log_id "generating_stock" $MAXITEMS $xlevel
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
		Enter_log_item $log_id "loading_stock" $MAXITEMS $xlevel
	}
	return
}


proc District { log_id gen_files d_fid rdbms hodbc dbhandle dbcur sec_name w_id DIST_PER_WARE xlevel} {
	set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
	set d_w_id $w_id
	set d_ytd 30000.0
	set d_next_o_id 3001
	for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
		set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
		set d_add [ MakeAddress $globArray $chalen ]
		set d_tax_ran [ RandomNumber 10 20 ]
		set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
		if {$gen_files == 1} {
			puts $d_fid "$d_id=$d_w_id=$d_ytd=$d_next_o_id=$d_tax=$d_name=[ lindex $d_add 0 ]=[ lindex $d_add 1 ]=[ lindex $d_add 2 ]=[ lindex $d_add 3 ]=[ lindex $d_add 4 ]="
		} else {
			set use_sql "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, \
		             	d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', \
			     		'$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', \
			     		'[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', \
			     		'$d_tax', '$d_ytd', '$d_next_o_id')"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
		}
	}
	if {$gen_files == 0 } {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
	}
	return
}



proc LoadCust { log_id gen_files thread rdbms hodbc dbhandle dbcur sec_name base_sec_dir ware_start count_ware CUST_PER_DIST DIST_PER_WARE xlevel} {
	if {$gen_files == 1  } {
		set n_file [file join $base_sec_dir [format "customer_%04d.dat" $thread]]
		set c_fid [open $n_file w]
		set n_file [file join $base_sec_dir [format "history_%04d.dat" $thread]]
		set h_fid [open $n_file w]
	} else {
		set c_fid "NOT_USED"
		set h_fid "NOT_USED"
	}

	for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
		for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
			set ld_cust_string [format "DID=%d WID=%d" $d_id $w_id]
			Enter_log_item $log_id "loading_customer" $ld_cust_string $xlevel
			Customer $log_id $gen_files $c_fid $h_fid $rdbms $hodbc $dbhandle $dbcur $sec_name $d_id $w_id $CUST_PER_DIST $xlevel
			Enter_log_item $log_id "done_loading_customer" $ld_cust_string $xlevel
		}
	}
	if {$gen_files == 1 } {
		close $c_fid
		close $h_fid
	}
	return
}

proc Customer { log_id gen_files c_fid h_fid rdbms hodbc dbhandle dbcur sec_name d_id w_id CUST_PER_DIST xlevel} {
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
	set db_date [Set_db_date_fun $rdbms]
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
		append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last',    \
		                   '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $$c_add 2 ]', \
				   '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', $db_date,   \
				   '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
		set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
		append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', $db_date, '$h_amount', '$h_data')
		incr bld_cnt
		if {$gen_files == 1 } {
			set db_date [clock format [clock seconds] -format "%Y%m%d"]
			puts $c_fid "$c_id=$c_d_id=$c_w_id=$c_discount=$c_credit_lim=$c_first=$c_middle=$c_last=$c_credit=$c_balance=$c_balance=1=0=[ lindex $c_add 0 ]=[ lindex $c_add 1 ]=[ lindex $$c_add 2 ]=[ lindex $c_add 3 ]=[ lindex $c_add 4 ]=$c_phone=$db_date=$c_data="
			puts $h_fid "$c_id=$c_d_id=$c_w_id=$c_d_id=$c_w_id=$db_date=$h_amount=$h_data="
		} else {
			set use_sql "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, \
		             	c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, \
			     		c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, \
			     		c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
			set use_sql  "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, \
		             	h_date, h_amount, h_data) values $h_val_list"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
		}
		set bld_cnt 1
		unset c_val_list
		unset h_val_list
	}
	if {$gen_files == 1 } {
		Enter_log_item $log_id "generating_customer" $CUST_PER_DIST $xlevel
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
		Enter_log_item $log_id "loading_customer" $CUST_PER_DIST $xlevel
	}
	unset -nocomplain 
	return
}

proc LoadOrd { log_id gen_files thread rdbms hodbc dbhandle dbcur sec_name base_sec_dir ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE xlevel} {
	if {$gen_files == 1  } {
		set n_file [file join $base_sec_dir [format "orders_%04d.dat" $thread]]
		set o_fid [open $n_file w]
		set n_file [file join $base_sec_dir [format "order_line_%04d.dat" $thread]]
		set ol_fid [open $n_file w]
		set n_file [file join $base_sec_dir [format "new_order_%04d.dat" $thread]]
		set no_fid [open $n_file w]
	} else {
		set o_fid  "NOT_USED"
		set ol_fid "NOT_USED"
		set no_fid "NOT_USED"
	}
	Enter_log_item $log_id "dist_per_ware" $DIST_PER_WARE $xlevel
	for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
		for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
			set ld_cust_string [format "DID=%d WID=%d" $d_id $w_id]
			Enter_log_item $log_id "loading_orders" $ld_cust_string $xlevel
			Orders $log_id $gen_files $o_fid $ol_fid $no_fid $rdbms $hodbc $dbhandle $dbcur $sec_name $d_id $w_id $MAXITEMS $ORD_PER_DIST $xlevel
			Enter_log_item $log_id "done_loading_orders" $ld_cust_string $xlevel
		}
	}
	return
}

proc Orders { log_id gen_files o_fid ol_fid no_fid rdbms hodbc dbhandle dbcur sec_name d_id w_id MAXITEMS ORD_PER_DIST xlevel} {
	set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
	set bld_cnt 1
	set o_d_id $d_id
	set o_w_id $w_id
	for {set i 0} {$i <= $ORD_PER_DIST } {incr i } {
		set cust($i) 1
	}
	for {set i 0} {$i <= $ORD_PER_DIST } {incr i } {
		set r [ RandomNumber $i $ORD_PER_DIST ]
		set t $cust($i)
		set cust($i) $cust($r)
		set $cust($r) $t
	}
	set e ""
	set db_date [Set_db_date_fun $rdbms]
	set odb_date [clock format [clock seconds] -format "%Y%m%d"]
	for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
		set o_c_id $cust($o_id)
		set o_carrier_id [ RandomNumber 1 10 ]
		set o_ol_cnt [ RandomNumber 5 15 ]
		if { $o_id > 2100 } {
			set e "o1"
			append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', $db_date, null, '$o_ol_cnt', '1')
			append o_val_out "$o_id=$o_d_id=$o_w_id=$o_c_id==$o_ol_cnt=1=$odb_date="
			set e "no1"
			append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
			append no_val_out "$o_id=$o_d_id=$o_w_id="
  		} else {
  			set e "o3"
			append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', $db_date, '$o_carrier_id', '$o_ol_cnt', '1')
			append o_val_out "$o_id=$o_d_id=$o_w_id=$o_c_id=$o_carrier_id=$o_ol_cnt=1=$odb_date="
		}
		for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
			set ol_i_id [ RandomNumber 1 $MAXITEMS ]
			set ol_supply_w_id $o_w_id
			set ol_quantity 5
			set ol_amount 0.0
			set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
			if { $o_id > 2100 } {
				set e "ol1"
				append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', \
				                    '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', \
						    '$ol_amount', '$ol_dist_info', null)
				append ol_val_out "$o_id=$o_d_id=$o_w_id=$ol=$ol_i_id==$ol_amount=$ol_supply_w_id=$ol_quantity=$ol_dist_info="
			} else {
				set amt_ran [ RandomNumber 10 10000 ]
				set ol_amount [ expr {$amt_ran / 100.0} ]
				set e "ol2"
				append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', \
				                    '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', \
						            '$ol_amount', '$ol_dist_info', $db_date)
				append ol_val_out "$o_id=$o_d_id=$o_w_id=$ol=$ol_i_id=$odb_date=$ol_amount=$ol_supply_w_id=$ol_quantity=$ol_dist_info="
			}
			if {$gen_files == 1} {
				puts $ol_fid $ol_val_out
			} else {
				set use_sql "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, \
			    	     	ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, \
			    	     	ol_delivery_d) values $ol_val_list"
				RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
			}
			unset ol_val_list
			unset ol_val_out
		}
		incr bld_cnt
		if {$gen_files == 1} {
			puts $o_fid $o_val_out
			if {$o_id >  2100 } {
				puts $no_fid $no_val_out
			}
		} else {
			set use_sql "insert into orders (o_id, o_c_id, o_d_id, o_w_id, \
		            	o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
			RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
			if { $o_id > 2100 } {
				set use_sql "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
				RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 0
			}
		}
		set bld_cnt 1
		unset o_val_list
		unset o_val_out
		unset -nocomplain no_val_list
		unset -nocomplain no_val_out
		#unset ol_val_list
	}
	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 $xlevel
	Enter_log_item $log_id "inserted_x_orders" $ORD_PER_DIST $xlevel
	return
}

proc Trans_results {rdbms log_id sec_name threads syscur start_nopm end_nopm firstsnap endsnap } {
set ora_sql "select round((sum(tps)*60)) as TPM 
             from (select e.stat_name, (e.value - b.value) / 
	     (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ 
	     extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ 
	     extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ 
	     extract( second from (e1.end_interval_time-b1.end_interval_time)) ) 
	     from dba_hist_snapshot b1, dba_hist_snapshot e1 
	     where b1.snap_id = [ lindex $firstsnap 4 ] 
	     and e1.snap_id = [ lindex $endsnap 4 ] 
	     and b1.dbid = [lindex $firstsnap 3] 
	     and e1.dbid = [lindex $endsnap 3] 
	     and b1.instance_number = [lindex $firstsnap 0] 
	     and e1.instance_number = [lindex $endsnap 0] 
	     and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) 
	     as tps from dba_hist_sysstat b, dba_hist_sysstat e 
	     where b.snap_id = [ lindex $firstsnap 4 ] 
	     and e.snap_id = [ lindex $endsnap 4 ] 
	     and b.dbid = [lindex $firstsnap 3] 
	     and e.dbid = [lindex $endsnap 3] 
	     and b.instance_number = [lindex $firstsnap 0] 
	     and e.instance_number = [lindex $endsnap 0] 
	     and b.stat_id = e.stat_id and b.stat_name 
	     in ('user commits','user rollbacks') 
	     and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"

	orasql $syscur $ora_sql
	orafetch $syscur -datavariable tpm
	return $tpm 
}

proc District_sum { rdbms log_id sec_name hodbc dbcur} {
	set use_sql "select sum(d_next_o_id) from district" 
	RDBMS_sql  $rdbms $log_id $sec_name 0 $hodbc $dbcur $use_sql "" 0 0 1
}

proc All_queries { rdbms log_id sec_name hodbc dbcur syscur dbhandle syshandle xlevel} {
	
	set ora_sql "SELECT INSTANCE_NUMBER, INSTANCE_NAME, DB_NAME, DBID, 
	             SNAP_ID, TO_CHAR(END_INTERVAL_TIME,'DD MON YYYY HH24:MI') 
		     FROM (SELECT DI.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.DB_NAME, 
		     DI.DBID, DS.SNAP_ID, DS.END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT DS, 
		     DBA_HIST_DATABASE_INSTANCE DI 
		     WHERE DS.DBID=DI.DBID AND DS.INSTANCE_NUMBER=DI.INSTANCE_NUMBER 
		     AND DS.STARTUP_TIME=DI.STARTUP_TIME ORDER BY DS.SNAP_ID DESC) WHERE ROWNUM=1"
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { if {[catch {set trans_snap [ $hodbc  "select sum(execution_count) from sys.dm_exec_query_stats" ]}]} {
				Query_error_performance $log_id "Failed to query transaction statistics" $xlevel
			 }
		         return $trans_snap
		       }
		oracle { 
			Set_snap $log_id $sec_name $rdbms $syscur $syshandle
			Commit_sql $log_id $rdbms $hodbc $syshandle $sec_name 1 $xlevel
			if {[catch {orasql $syscur $ora_sql} mymsg]} {
				if { [oramsg $syshandle] != 0 } {
					Enter_log_item $log_id "ORA_ERROR" [oramsg $syshandle] $xlevel
					Error_out $log_id $sec_name 
				}
			}
			orafetch $syscur -datavariable snap_value
			split $snap_value " "
			return $snap_value
			#return [lindex $snap_value 4]
		       }
		pgsql  { if {[catch {set start_trans [ db "select sum(execution_count) from sys.dm_exec_query_stats" ]}]} {
				Query_error_performance $log_id "Failed to query transaction statistics" $xlevel
			 }
		       }
		mysql  { if {[catch {set start_trans [ db "select sum(execution_count) from sys.dm_exec_query_stats" ]}]} {
				Query_error_performance $log_id "Failed to query transaction statistics" $xlevel
			 }
		       }
	} 
}

proc Set_snap {log_id sec_name rdbms syscur syshandle} {
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { return }
		oracle { 
			set sql_snap "BEGIN dbms_workload_repository.create_snapshot(); END;"
			if {[catch {orasql $syscur $sql_snap} mymsg]} {
					Enter_log_item $log_id "ORA_ERROR" [oramsg $syshandle] 3
					Error_out $log_id $sec_name 
				}

		       }
		pgsql  { return }
		mysql  { return }
	}
}




proc Run_tpcc { log_id base_log_dir connect sysconnect rdbms database_name threads ramp_min test_min KEYANDTHINK RAISEERROR} {
	set dbhandle  "NOT USED"
	set dbcur     "NOT USED"
	set syshandle "NOT USED"
	set syscur    "NOT USED"
	set hodbc     "db_main"
	set sec_name  "run_tpcc"
	set ONE_MIN   60000
	set xlevel 2

puts "starting run_tpcc"

	set thread_dir [file join $base_log_dir $sec_name]
	file mkdir $thread_dir

	set f_connect [Quote_slash $connect]
	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { }
		oracle { DB_use $log_id $sec_name "test" $rdbms $database_name $sysconnect syshandle syscur }
		pgsql  { }
		mysql  { } 
	}
	Enter_log_tag $log_id "S" "running_threads" 1 xlevel
	Enter_log_tag $log_id "S" "creating_users"  1 xlevel

	#2.4.1.1 set warehouse_id stays constant for a given terminal
	set w_id_input [ RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur "select max(w_id) from warehouse" "" 0 0 1]
	set d_id_input [ RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur "select max(d_id) from district"  "" 0 0 1]

	#
	# flag to signal when the timeout occurs
	#
	tsv::set auto_ctl_var exit_trans 0
	tsv::set auto_ctl_var new_order_count 0

	for {set c_thread 1 } { $c_thread <= $threads} {incr c_thread } {
		#
		# Create and start the thread's log
		set tlog_id [Create_thread_log  $log_id $sec_name $c_thread $thread_dir "tlog_%05d.xml" $xlevel]
		#
		set w_id  [ RandomNumber 1 $w_id_input ]  
		set stock_level_d_id  [ RandomNumber 1 $d_id_input ] 

		set t_list($c_thread) [thread::create -joinable {thread::wait}]

		
		thread::transfer $t_list($c_thread) $tlog_id
		Load_sources $t_list($c_thread) $rdbms "auto_tpcc.tcl"

		# Is there any difference for this part between MSSQL, MySQL, Oracle and PGSQL?
		# might need to pass rdbms and maybe a version (which version of the database)  
		eval [subst {thread::send -async $t_list($c_thread) { \
			Run_thread $rdbms $sec_name $c_thread $tlog_id $database_name $f_connect $w_id $stock_level_d_id $KEYANDTHINK $RAISEERROR} r_id } ]

		Enter_log_item $log_id "user"  [format "Using warehouse %d and stock level %d" $w_id $stock_level_d_id] $xlevel
	}
	Enter_log_tag $log_id "E" "creating_users" 1 xlevel

	
	set ramptime 1
	Enter_log_item $log_id "begin_rampup" [format "For %d minutes starting at [Get_time]" $ramp_min] $xlevel
	incr xlevel
	while {$ramptime <= $ramp_min} {
		after $ONE_MIN  
		Enter_log_item $log_id "rampup_tc" [format "%d minutes complete ..." $ramptime] $xlevel
		incr ramptime 
	}
	incr xlevel -1

	Enter_log_item $log_id "rampup_complete" [Get_time] $xlevel

	set start_trans [All_queries $rdbms $log_id $sec_name $hodbc $dbcur $syscur $dbhandle $syshandle $xlevel]
	set start_nopm [District_sum  $rdbms $log_id $sec_name $hodbc $dbcur]
	set start_total_ms [ clock milliseconds ]

	Enter_log_item $log_id "test_running" [format "Run for %d minutes" $test_min] $xlevel
	set smin_nopm [tsv::get auto_ctl_var new_order_count ]
	set smin_ms [ clock milliseconds ]
	incr xlevel
	set testtime 1
	set durmin $test_min
	#
	while {$testtime <= $test_min} {
		after $ONE_MIN
		set emin_nopm [tsv::get auto_ctl_var new_order_count ]
		set emin_ms [ clock milliseconds ]
		set m_notpm [ expr {($emin_nopm - $smin_nopm)/(($emin_ms-$smin_ms)/60000.0)} ]
		Enter_log_item $log_id "test_time" [format "%d minutes complete notmp %12.3f ..." $testtime $m_notpm] $xlevel
		set smin_nopm $emin_nopm
		set smin_ms $emin_ms
		incr testtime 
	}
	incr xlevel -1


	tsv::incr auto_ctl_var exit_trans 
	

	after 500
	while {[llength [thread::names]] > 1} {
		puts "while loop..."
		after 500
	}

	set end_total_ms [ clock milliseconds ]
	set end_trans [All_queries $rdbms  $log_id $sec_name $hodbc $dbcur $syscur $dbhandle $syshandle $xlevel]
	set end_nopm [District_sum  $rdbms $log_id $sec_name $hodbc $dbcur]

	Enter_log_tag $log_id "E" "running_threads" 1 xlevel

	if { $sk == "mssql" } {
		if { [ string is integer -strict $end_trans ] && [ string is integer -strict $start_trans ] } {
			if { $start_trans < $end_trans }  {
				set tpm [ expr {($end_trans - $start_trans)/(($end_total_ms-$start_total_ms)/$ONE_MIN)} ]
			} else {
				set p_trans [expr {9223372036854775807 - $start_trans}]
				set total_trans [expr {($end_trans - 0) + $p_trans}]
				set tpm [ expr {$total_trans/(($end_total_ms-$start_total_ms)/$ONE_MIN)} ]
			} 
		} else {
			puts "Error: SQL Server returned non-numeric transaction start count data >>>$start_trans<<<"
			puts "Error: SQL Server returned non-numeric transaction end count data >>>$end_trans<<<"
			set tpm 0
		}
	}
	
	if {$sk == "oracle" } {
		set tpm [Trans_results $rdbms $log_id $sec_name $threads $syscur $start_nopm $end_nopm "$start_trans" "$end_trans" ]
	}
	set nopm [ expr {($end_nopm - $start_nopm)/(($end_total_ms-$start_total_ms)/60000.0)} ]


	Enter_log_tag  $log_id "S" "tpcc_results" 1 xlevel
	Enter_log_item $log_id "user_count" $threads  $xlevel
	Enter_log_item $log_id "server_tpm" $tpm  $xlevel
	Enter_log_item $log_id "NOTPM"      [format "%12.3f" $nopm] $xlevel
	Enter_log_tag  $log_id "E" "tpcc_results" 1 xlevel

	Disconnect_from_DB $log_id $rdbms $hodbc $dbhandle $xlevel

	Enter_log_tag $log_id "E" "run_tpcc"   1 xlevel
	Enter_log_tag $log_id "E" "autohammer" 1 xlevel
	exit 

}

proc Query_error_performace {log_id error_string xlevel} {
	Enter_log_item $log_id "ERROR" $error_string $xlevel
	Enter_log_tag  $log_id "E" "running_threads" $xlevel
	Error_out      $log_id "run_tpcc"
	exit
}

proc Run_thread { rdbms sec_name thread log_id database_name f_connect w_id stock_level_d_id KEYANDTHINK RAISEERROR} {

	set dbhandle "NOT_USED"
	set dbcur    "NOT_USED"
	set xlevel 1
#
# Make sure every thread is randomized differently 
# And has a different database attachement
#
	set not_used [expr {srand($w_id*$stock_level_d_id)}]
	set hodbc [format "db_%d" $thread]
	DB_use $log_id $sec_name "test" $rdbms $database_name $f_connect $hodbc dbhandle dbcur

	set sk [string tolower $rdbms]
	foreach st {neword_st payment_st ostat_st delivery_st slev_st} { 
		switch $sk {
			mssql  { set $st [ MSSQL_prep_statement $rdbms $hodbc $dbcur $st ] }
			oracle { set $st [ Oracle_prep_statement $dbhandle $st ] }
			pgsql  { puts "Still need Pgsql_prep_statement" }
			mysql  { puts "Still need Mysql_prep_statement" }
		}
	}

	#move the max and random to the main creation routine - and make it a mutex to start and stop
	set w_id_input [ RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur "select max(w_id) from warehouse" "" 0 0 1]
	#2.4.1.1 set warehouse_id stays constant for a given terminal
	set w_id  [ RandomNumber 1 $w_id_input ]  
	set d_id_input [ RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur "select max(d_id) from district" "" 0 0 1]
	set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
	if {[string compare $sk "oracle"] == 0 } {
		set sql1 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * 
			  (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;" 
		oraparse $dbcur $sql1
		if {[catch {oraplexec $dbcur $sql1} message]} {
 			Enter_log_item $log_id "ERROR" "Failed to initialise DBMS_RANDOM" $xlevel
		        Enter_log_item $log_id "ERROR"	$message  $xlevel
			Enter_log_item $log_id "ERROR" "Have you run catoctk.sql as sys?" $xlevel
			Put_thread_footer  $log_id $sec_name
			thread::release
 		}
		unset sql1
	}

	#Auto_on_off $rdbms $hodbc $dbhandle "on"

	while { 1 } {

		set local_exit [tsv::get auto_ctl_var exit_trans ]
		if {$local_exit > 0 } {
			Enter_log_item $log_id "thread_done"  [thread::id] $xlevel
			break 
		}


		set choice [ RandomNumber 1 23 ]
		if {$choice <= 10} {
			if { $KEYANDTHINK } { keytime 18 }
			neword neword_st $log_id $sec_name $rdbms $hodbc $dbhandle $neword_st $w_id $w_id_input $RAISEERROR
			tsv::incr auto_ctl_var new_order_count
			if { $KEYANDTHINK } { thinktime 12 }
			continue
		}
		if {$choice <= 20} {
			if { $KEYANDTHINK } { keytime 3 }
			payment payment_st $log_id $sec_name $rdbms $hodbc $dbhandle $payment_st $w_id $w_id_input $RAISEERROR
			if { $KEYANDTHINK } { thinktime 12 }
			continue
		}
		if {$choice <= 21} {
			if { $KEYANDTHINK } { keytime 2 }
			delivery delivery_st $log_id $sec_name $rdbms $hodbc $dbhandle $delivery_st $w_id $RAISEERROR
			if { $KEYANDTHINK } { thinktime 10 }
			continue
		}
		if {$choice <= 22} {
			if { $KEYANDTHINK } { keytime 2 }
			slev slev_st $log_id $sec_name $rdbms $hodbc $dbhandle $slev_st $w_id $stock_level_d_id $RAISEERROR
			if { $KEYANDTHINK } { thinktime 5 }
			continue
		}
		if { $KEYANDTHINK } { keytime 2 }
		ostat ostat_st $log_id $sec_name $rdbms $hodbc $dbhandle $ostat_st $w_id $RAISEERROR
		if { $KEYANDTHINK } { thinktime 5 }

	}
	#Auto_on_off $rdbms $hodbc $dbhandle "off"
	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 1 2
	if {$sk == "mysql" } {
		neword_st drop 
		payment_st drop
		delivery_st drop
		slev_st drop
		ostat_st drop
	}
	Disconnect_from_DB $log_id $rdbms $hodbc $dbhandle $xlevel
	Put_thread_footer  $log_id $sec_name
	thread::release
	return
	
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
		return "TRUE"
	} else {
	    	return "FALSE"
	}
}
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
	array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
	set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
	return $name
}
#TIMESTAMP
proc gettimestamp { } {
	set ts_ms [clock milliseconds]
	set ts_sec [expr {$ts_ms/1000}]
	set ts_ts [expr {($ts_ms % 1000)/100}]
	set tstamp [format "[clock format $ts_sec -format "%Y-%m-%dT%H:%M:%S"].%1d" $ts_ts]
	return $tstamp
}
#KEYING TIME
proc keytime { keying } {
	after [ expr {$keying * 1000} ]
	return
}
#THINK TIME
proc thinktime { thinking } {
	set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
	after [ expr {$thinkingtime * 1000} ]
	return
}
#NEW ORDER
proc neword { neword_st log_id sec_name rdbms hodbc dbhandle dbcur no_w_id w_id_input RAISEERROR } {
	#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
	set no_d_id [ RandomNumber 1 10 ]
	#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
	set no_c_id [ RandomNumber 1 3000 ]
	#2.4.1.3 Items in the order randomly selected from 5 to 15
	set ol_cnt [ RandomNumber 5 15 ]
	#2.4.1.6 order entry date O_ENTRY_D generated by SUT
	set h_date [string map {{T} { }} [ gettimestamp ] ]
	set eh_date [string first $h_date "." ]
	set h_date [string range $h_date 0 [expr {$eh_date - 1} ]]
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  {
			if {[ catch {neword_st execute [ list $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $h_date ]} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_New_Order" $message 4
					#error "New Order : $message"
				} else {
					Enter_log_item $log_id "Warning" \
						[format "New Order no_w_id =%s w_id_input=%s no_d_id=%s no_c_id=%s ol_cnt=%s date=%s" \
						 $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $h_date ] 4
					Enter_log_item $log_id "Warning" "New Order Message:  $message" 4
				} 
			} else {
				neword_st fetch op_params
					foreach or [array names op_params] {
				}
		
			}
		       }
		oracle {
			orabind $dbcur :no_w_id $no_w_id :no_max_w_id $w_id_input :no_d_id \
			        $no_d_id :no_c_id $no_c_id :no_o_ol_cnt $ol_cnt :no_c_discount \
				{} :no_c_last {} :no_c_credit {} :no_d_tax {} :no_w_tax {} \
				:no_d_next_o_id {0} :timestamp $h_date
			if {[catch {oraexec $dbcur} message]} {
				puts "neword error date is ===$date==="
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_New_Order" $message 4
					Enter_log_item $log_id "TX_ERROR_New_Order" [oramsg $curn_no all] 4
					#error "New Order : $message [ oramsg $curn_no all ]"
				} else {
					puts $message
				} 
			} else {
				orafetch  $dbcur -datavariable output
			}
		       }
	       }
	       Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 2
}
#PAYMENT
proc payment { payment_st log_id sec_name rdbms hodbc dbhandle dbcur p_w_id w_id_input RAISEERROR } {
	#2.5.1.1 The home warehouse id remains the same for each terminal
	#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
	set p_d_id [ RandomNumber 1 10 ]
	#2.5.1.2 customer selected 60% of time by name and 40% of time by number
	set x [ RandomNumber 1 100 ]
	set y [ RandomNumber 1 100 ]
	if { $x <= 85 } {
		set p_c_d_id $p_d_id
		set p_c_w_id $p_w_id
	} else {
		#use a remote warehouse
		set p_c_d_id [ RandomNumber 1 10 ]
		set p_c_w_id [ RandomNumber 1 $w_id_input ]
		while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
			set p_c_w_id [ RandomNumber 1  $w_id_input ]
		}
	}
	set nrnd [ NURand 255 0 999 123 ]
	set name [ randname $nrnd ]
	set p_c_id [ RandomNumber 1 3000 ]
	if { $y <= 60 } {
		#use customer name
		#C_LAST is generated
		set byname 1
 	} else {
		#use customer number
		set byname 0
		set name {}
 	}
	#2.5.1.3 random amount from 1 to 5000
	set p_h_amount [ RandomNumber 1 5000 ]
	#2.5.1.4 date selected from SUT
	set h_date [string map {{T} { }} [ gettimestamp ] ]
	set eh_date [string first $h_date "." ]
	set h_date [string range $h_date 0 [expr {$eh_date - 1} ]]
	#2.5.2.1 Payment Transaction
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  {
			if {[ catch {payment_st execute [ list $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date ]} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Payment" $message 4
					#error "Payment : $message"
				} else {
					Enter_log_item $log_id "Warning" \
							[format "Payment p_w_id=%s p_d_id=%s p_c_w_id=%s p_c_d_id=%s p_c_id=%s byname=%s p_h_amount=%s name=%s h_date=%s" \
							$p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date] 4
					Enter_log_item $log_id "Warning" "Payment Message: $message" 4
					puts "eh_date is ==$eh_date"
				} 
			} else {
				payment_st fetch op_params
				foreach or [array names op_params] {
					lappend oput $op_params($or)
				}
			}
		       }
		oracle {
			orabind $dbcur :p_w_id $p_w_id :p_d_id $p_d_id :p_c_w_id $p_c_w_id :p_c_d_id \
			        $p_c_d_id :p_c_id $p_c_id :byname $byname :p_h_amount $p_h_amount :p_c_last \
				$name :p_w_street_1 {} :p_w_street_2 {} :p_w_city {} :p_w_state {} \
				:p_w_zip {} :p_d_street_1 {} :p_d_street_2 {} :p_d_city {} :p_d_state {} \
				:p_d_zip {} :p_c_first {} :p_c_middle {} :p_c_street_1 {} :p_c_street_2 {} \
				:p_c_city {} :p_c_state {} :p_c_zip {} :p_c_phone {} :p_c_since {} \
				:p_c_credit {0} :p_c_credit_lim {} :p_c_discount {} :p_c_balance {0} \
				:p_c_data {} :timestamp $h_date
			if {[ catch {oraexec $dbcur} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Payment_date" $h_date 4
					Enter_log_item $log_id "TX_ERROR_Payment" $message 4
					Enter_log_item $log_id "TX_ERROR_Payment" [oramsg $payment_st all] 4
					#error "Payment : $message [ oramsg $payment_st all ]"
				} else {
					puts $message
				} 
			} else {
				orafetch  $dbcur -datavariable output
			#	puts $output
			}
		       }
	       }
	       Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 2
}
#ORDER_STATUS
proc ostat { ostat_st log_id sec_name rdbms hodbc dbhandle dbcur w_id RAISEERROR } {
	#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
	set d_id [ RandomNumber 1 10 ]
	set nrnd [ NURand 255 0 999 123 ]
	set name [ randname $nrnd ]
	set c_id [ RandomNumber 1 3000 ]
	set y [ RandomNumber 1 100 ]
	if { $y <= 60 } {
		set byname 1
 	} else {
		set byname 0
		set name {}
	}
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  {
			if {[ catch {ostat_st execute [ list $w_id $d_id $c_id $byname $name ]} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Order_Status" $message 4
					#error "Order Status : $message"
				} else {
					Enter_log_item $log_id "Warning" "Order Status" 4
					#puts "Order Status: Handle: $hodbc Warning: $message"
				} 
			} else {
				ostat_st fetch op_params
				foreach or [array names op_params] {
					lappend oput $op_params($or)
				}
			}
		       }
		oracle {
			orabind $dbcur :os_w_id $w_id :os_d_id $d_id :os_c_id $c_id :byname \
			        $byname :os_c_last $name :os_c_first {} :os_c_middle {} \
				:os_c_balance {0} :os_o_id {} :os_entdate {} :os_o_carrier_id {}
			if {[catch {oraexec $dbcur} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Order_Status" $message 4
					Enter_log_item $log_id "TX_ERROR_Order_Status" [ oramsg $ostat_st all ] 4
					#error "Order Status : $message [ oramsg $ostat_st all ]"
				} else {
					puts $message
				} 
			} else {
				orafetch  $dbcur -datavariable output
			#	puts $output
			}
		       }
	       }
	       Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 2
}
#DELIVERY
proc delivery { delivery_st log_id sec_name rdbms hodbc dbhandle dbcur w_id RAISEERROR } {
	set carrier_id [ RandomNumber 1 10 ]
	set h_date [string map {{T} { }} [ gettimestamp ] ]
	set eh_date [string first $h_date "." ]
	set h_date [string range $h_date 0 [expr {$eh_date - 1} ]]
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  {
			if {[ catch {delivery_st execute [ list $w_id $carrier_id $h_date ]} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Delivery" $message 4
					#error "Delivery : $message"
				} else {
					Enter_log_item $log_id "Warning" \
						[format "Delivery w_id=%s carrier_id=%s date=%s" $w_id $carrier_id $h_date ] 4
					Enter_log_item $log_id "Warning" "Delivery Message: $message" 4
				} 
			} else {
				delivery_st fetch op_params
				foreach or [array names op_params] {
					lappend oput $op_params($or)
				}
			}
		       }
		oracle {
			orabind $dbcur :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $h_date
			if {[ catch {oraexec $dbcur} message ]} {
				puts "delivery error date passed is ===$date==="
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_Delivery" $message 4
					Enter_log_item $log_id "TX_ERROR_Delivery_date_passed" $date 4
					Enter_log_item $log_id "TX_ERROR_Delivery" [ oramsg $dbcur all ] 4
					#error "Delivery : $message [ oramsg $dbcur all ]"
				} else {
					puts $message
				} 
			} else {
				orafetch  $dbcur -datavariable output
			#	puts $output
		       	}
		       }
	       }
	       Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 2
}
#STOCK LEVEL
proc slev { slev_st log_id sec_name rdbms hodbc dbhandle dbcur w_id stock_level_d_id RAISEERROR } {
	set threshold [ RandomNumber 10 20 ]
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  {
			if {[ catch {slev_st execute [ list $w_id $stock_level_d_id $threshold ]} message]} {
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_SLEV" $message 4
					#error "Stock Level : $message"
				} else {
					Enter_log_item $log_id "Warning" "SLEV" 4
					#puts "Stock Level: Handle: $hodbc Warning: $message"
				} 
			} else {
				slev_st fetch op_params
				foreach or [array names op_params] {
					lappend oput $op_params($or)
				}
			}
		       }
		oracle {
			orabind $dbcur :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold 
			if {[catch {oraexec $dbcur} message]} { 
				puts "slev error"
				if { $RAISEERROR } {
					Enter_log_item $log_id "TX_ERROR_slev" $message 4
					Enter_log_item $log_id "TX_ERROR_slev" [ oramsg $dbcur all ] 4
					#error "Stock Level : $message [ oramsg $dbcur all ]"
				} else {
					puts $message
				} 
			} else {
				orafetch  $dbcur -datavariable output
			#	puts $output
			}

		       }
	       }
	       Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 2
}

proc MSSQL_prep_statement { rdbms hodbc dbcur statement_st } {
	switch $statement_st {
		slev_st {
			$hodbc statement slev_st "EXEC SLEV @st_w_id = ?, @st_d_id = ?, @threshold = ?" \
			                     {INTEGER INTEGER INTEGER} 
			return slev_st
			}
		delivery_st {
			$hodbc  statement delivery_st "EXEC DELIVERY @d_w_id = ?, @d_o_carrier_id = ?, @timestamp = ?" \
			                         {INTEGER INTEGER TIMESTAMP}
			return delivery_st
			}
		ostat_st {
			$hodbc  statement ostat_st "EXEC OSTAT @os_w_id = ?, @os_d_id = ?, @os_c_id = ?, @byname = ?, @os_c_last = ?" \
			                       {INTEGER INTEGER INTEGER INTEGER {CHAR 16}}
			return ostat_st
			}
		payment_st {
			$hodbc  statement payment_st "EXEC PAYMENT @p_w_id = ?, @p_d_id = ?, @p_c_w_id = ?, 
			                        @p_c_d_id = ?, @p_c_id = ?, @byname = ?, @p_h_amount = ?, 
						@p_c_last = ?, @timestamp =?" \
						{INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER {CHAR 16} TIMESTAMP}
			return payment_st
			}
		neword_st {
			$hodbc  statement neword_st "EXEC NEWORD @no_w_id = ?, @no_max_w_id = ?, @no_d_id = ?, 
			                        @no_c_id = ?, @no_o_ol_cnt = ?, @timestamp = ?" \
						{INTEGER INTEGER INTEGER INTEGER INTEGER TIMESTAMP}
			return neword_st
			}
	}
}


proc Oracle_prep_statement { dbhandle curn_st } {
	switch $curn_st {
		slev_st {
				set slev_st [oraopen $dbhandle ]
				set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold); END;"
				oraparse $slev_st $sql_sl
				return $slev_st
			}
		delivery_st {
				set delivery_st [oraopen $dbhandle ]
				set sql_dl "BEGIN delivery(:d_w_id,:d_o_carrier_id, 
				           TO_DATE(:timestamp,'YYYY-MM-DD HH24:MI:SS')); END;"
				oraparse $delivery_st $sql_dl
				return $delivery_st
			}
		ostat_st {
				set ostat_st [oraopen $dbhandle ]
				set sql_os "BEGIN ostat(:os_w_id,:os_d_id,:os_c_id,:byname,
				            :os_c_last,:os_c_first,:os_c_middle,:os_c_balance,
					    :os_o_id,:os_entdate,:os_o_carrier_id); END;"
				oraparse $ostat_st $sql_os
				return $ostat_st
			}
		payment_st {
				set payment_st [oraopen $dbhandle ]
				set sql_py "BEGIN payment(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,
				           :p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,
					   :p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,
					   :p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,
					   :p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,
					   :p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,
					   :p_c_discount,:p_c_balance,:p_c_data,
					   TO_DATE(:timestamp,'YYYY-MM-DD HH24:MI:SS')); END;"
				oraparse $payment_st $sql_py
				return $payment_st
			}
		neword_st {
				set neword_st [oraopen $dbhandle ]
				set sql_no "begin neword(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,
				           :no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,
					   :no_d_tax,:no_w_tax,:no_d_next_o_id,
					   TO_DATE(:timestamp,'YYYY-MM-DD HH24:MI:SS')); END;"
				oraparse $neword_st $sql_no
				return $neword_st
			}
    	}
}


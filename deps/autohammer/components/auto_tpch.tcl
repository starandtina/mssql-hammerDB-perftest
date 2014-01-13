# 
# Distributed under GPL 2.2
# Copyright Steve Shaw 2003-2012
# Copyright Tim Witham 2012
#
# for all of this
global dists weights dist_names dist_weights sql

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
	Enter_log_item $log_id "tpch_table_batch_load" "start" $xlevel
	Enter_log_tag  $log_id "S" "loading_nation" 1 xlevel
	set data_file_is [file join $base_data_dir "nation.dat"]
	Do_batch  $log_id $rdbms $database_name $dbhandle $hodbc $dbcur "nation" $data_file_is $xlevel
	Enter_log_tag  $log_id "E" "loading_nation" 1 xlevel
	Enter_log_tag  $log_id "S" "loading_region" 1 xlevel
	set data_file_is [file join $base_data_dir "region.dat"]
	Do_batch  $log_id $rdbms $database_name $dbhandle $hodbc $dbcur "region" $data_file_is $xlevel
	Enter_log_tag  $log_id "E" "loading_region" 1 xlevel

	Enter_log_tag $log_id "S" "running_threads" 1 xlevel
	set f_connect [Quote_slash $connect]
	set base_sec_dir [file join $base_log_dir $sec_name]
	file mkdir $base_sec_dir

	set l_thread 1
	while {$l_thread <= $load_threads } { 
		set tlog_id [Create_thread_log  $log_id $sec_name $l_thread $base_sec_dir "tlog_%05d.xml" $xlevel ]
		set t_list($l_thread) [thread::create -joinable {thread::wait}]
		thread::transfer $t_list($l_thread) $tlog_id
		Load_sources $t_list($l_thread) $rdbms "auto_tpch.tcl"
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

	set table_list [list "supplier" "customer" "part" "partsupp" "orders" "lineitem" ]
	foreach l_table $table_list {
		Enter_log_tag  $tlog_id "S" [format "loading_%s" $l_table] 1 xlevel
		set data_file_is [file join $base_data_dir [format "%s_%03d.dat" $l_table $l_thread]]
		Do_batch  $tlog_id $rdbms $database_name $dbhandle $hodbc $dbcur $l_table $data_file_is $xlevel
		Enter_log_tag  $tlog_id "E" [format "loading_%s" $l_table] 1 xlevel
	}
	set r_id [thread::id]
	thread::release

}

proc Load_tpch { sec_name load_type rdbms database_name log_id threads db_scale base_log_dir connect cmd_dir} {
global dists weights dist_names dist_weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
	set dbhandle "NOT_USED"
	set dbcur    "NOT_USED"
	set hodbc    "db_main"
	set xlevel   1
	set upd_num 0

	if { ![ array exists dists ] } { set_dists }
	foreach i [ array names dists ] {
		set_dist_list $i
	}
	set db_rows [ expr {$db_scale * 10000} ]
# Make sure it will work
	Validate_load_thread_count $threads
# create the directory for the thread logs
	set thread_dir [file join $base_log_dir $sec_name]
	file mkdir $thread_dir

	set load_type [string tolower $load_type]
	set gen_files 0
	switch $load_type {
		"generate" { 
                Enter_log_item $log_id "generating" "Will create data files for bulk loader" $xlevel 
                set gen_files 1
                set base_sec_dir [file join $base_log_dir "load_data"]
				file mkdir $base_sec_dir

        }
        "inline"   { 
				Enter_log_item $log_id "inserting" "Will generate and insert in one operation" $xlevel 
				set base_sec_dir "NOT_USED"
		}
        default { Enter_log_item $log_id "WARNING" "You didn't specify either generate or inline so inline is being used" $xlevel}
    }	

	# Fix the connect string so it can be passed
	set f_connect [Quote_slash $connect]


	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"
	
	if {$gen_files == 1 } {
		set region_data_file [file join $base_sec_dir "region.dat"]
		set region_id [open $region_data_file w]
		set nation_data_file [file join $base_sec_dir "nation.dat"]
		set nation_id [open $nation_data_file w]
		Make_region $log_id $gen_files $region_id $sec_name $rdbms $hodbc $dbhandle $dbcur $xlevel
		Make_nation $log_id $gen_files $nation_id $sec_name $rdbms $hodbc $dbhandle $dbcur $xlevel
	} else {
		Make_region $log_id $gen_files "NOT_USED" $sec_name $rdbms $hodbc $dbhandle $dbcur $xlevel
		Make_nation $log_id $gen_files "NOT_USED" $sec_name $rdbms $hodbc $dbhandle $dbcur $xlevel
	}

# This is what is done in parallel
	for {set l_thread 1 } { $l_thread <= $threads } {incr l_thread} {
		set tlog_id [Create_thread_log  $log_id $sec_name $l_thread $thread_dir "tlog_%05d.xml" $xlevel]
		#
		#Create a new thread that waits for the needed routines
		#
		set t_list($l_thread) [thread::create -joinable {thread::wait}]
		#
		# The load up the source code do this sync so that they happen one after another
		#	
		thread::transfer $t_list($l_thread) $tlog_id
		Load_sources $t_list($l_thread) $rdbms "auto_tpch.tcl"
		 
		#
		# And run the database build thread -async so they happen together
		#
		eval [subst {thread::send -async $t_list($l_thread) { \
			Build_tpch_thread $tlog_id $gen_files $sec_name $rdbms $f_connect \
			                  $database_name $db_rows $db_scale \
					  $l_thread $threads $upd_num $base_sec_dir } r_id } ]
	}
	#
	# Wait until all of the threads go away
	#
	while {[llength [thread::names]] > 1} {
		after 500
	}

	return
	
}

proc Build_tpch_thread { tlog_id gen_files sec_name rdbms connect database_name db_rows db_scale l_thread threads upd_num base_sec_dir } {
global dists weights dist_names dist_weights
set xlevel 2

	set hodbc [format "db_%d" $l_thread]

	if { ![ array exists dists ] } { set_dists }
		foreach i [ array names dists ] {
		set_dist_list $i
	}

	DB_use $tlog_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

	Auto_on_off $rdbms $hodbc $dbhandle "off"

	Make_supp  $tlog_id $gen_files $base_sec_dir $rdbms $hodbc $dbhandle $dbcur $sec_name $l_thread $threads $db_rows $xlevel
	Make_cust  $tlog_id $gen_files $base_sec_dir $rdbms $hodbc $dbhandle $dbcur $sec_name $l_thread $threads $db_rows $xlevel
	Make_part  $tlog_id $gen_files $base_sec_dir $rdbms $hodbc $dbhandle $dbcur $sec_name $l_thread $threads $db_rows $db_scale $xlevel
	Make_order $tlog_id $gen_files $base_sec_dir $rdbms $hodbc $dbhandle $dbcur $sec_name $l_thread $threads $db_rows $upd_num $db_scale $xlevel
	Put_thread_footer $tlog_id $sec_name
	flush $tlog_id
	close $tlog_id
	set r_id [thread::id]
	thread::release

}

proc Validate_load_thread_count { threads } {
set t_valid {1 2 4 5 8 10 16 20 25 40 50 80 100 125 200 250 400 500 625 1000 1250 2000 2500 5000 10000}
	foreach i $t_valid {
		if {$i == $threads} return
	}
	puts "ERROR: thread count $threads does not factor evenly into all table sizes"
	puts "\tPlease use one of these ==$t_valid=="
	exit
}

#
##
#

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

#
# This should be in an external XML config file that is loaded.
#
proc set_dists {} { 
global dists
	set dists(category) {{FURNITURE 1} {{STORAGE EQUIP} 1} {TOOLS 1} {{MACHINE TOOLS} 1} {OTHER 1}}

	set dists(p_cntr) {{{SM CASE} 1} {{SM BOX} 1} {{SM BAG} 1} {{SM JAR} 1} {{SM PACK} 1} {{SM PKG} 1} \
		           {{SM CAN} 1} {{SM DRUM} 1} {{LG CASE} 1} {{LG BOX} 1} {{LG BAG} 1} {{LG JAR} 1} \
			   {{LG PACK} 1} {{LG PKG} 1} {{LG CAN} 1} {{LG DRUM} 1} {{MED CASE} 1} {{MED BOX} 1} \
			   {{MED BAG} 1} {{MED JAR} 1} {{MED PACK} 1} {{MED PKG} 1} {{MED CAN} 1} {{MED DRUM} 1} \
			   {{JUMBO CASE} 1} {{JUMBO BOX} 1} {{JUMBO BAG} 1} {{JUMBO JAR} 1} {{JUMBO PACK} 1} \
			   {{JUMBO PKG} 1} {{JUMBO CAN} 1} {{JUMBO DRUM} 1} {{WRAP CASE} 1} {{WRAP BOX} 1} \
			   {{WRAP BAG} 1} {{WRAP JAR} 1} {{WRAP PACK} 1} {{WRAP PKG} 1} {{WRAP CAN} 1} {{WRAP DRUM} 1}}

	set dists(instruct) {{{DELIVER IN PERSON} 1} {{COLLECT COD} 1} {{TAKE BACK RETURN} 1} {NONE 1}}

	set dists(msegmnt) {{AUTOMOBILE 1} {BUILDING 1} {FURNITURE 1} {HOUSEHOLD 1} {MACHINERY 1}}

	set dists(p_names) {{CLEANER 1} {SOAP 1} {DETERGENT 1} {EXTRA 1}}

	set dists(nations) {{ALGERIA 0} {ARGENTINA 1} {BRAZIL 0} {CANADA 0} {EGYPT 3} {ETHIOPIA -4} {FRANCE 3} \
		            {GERMANY 0} {INDIA -1} {INDONESIA 0} {IRAN 2} {IRAQ 0} {JAPAN -2} {JORDAN 2} \
			    {KENYA -4} {MOROCCO 0} {MOZAMBIQUE 0} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} \
			    {VIETNAM -2} {RUSSIA 1} {{UNITED KINGDOM} 0} {{UNITED STATES} -2}}

	set dists(nations2) {{ALGERIA 1} {ARGENTINA 1} {BRAZIL 1} {CANADA 1} {EGYPT 1} {ETHIOPIA 1} {FRANCE 1} \
		             {GERMANY 1} {INDIA 1} {INDONESIA 1} {IRAN 1} {IRAQ 1} {JAPAN 1} {JORDAN 1} {KENYA 1} \
			     {MOROCCO 1} {MOZAMBIQUE 1} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} \
			     {VIETNAM 1} {RUSSIA 1} {{UNITED KINGDOM} 1} {{UNITED STATES} 1}}

	set dists(regions) {{AFRICA 1} {AMERICA 1} {ASIA 1} {EUROPE 1} {{MIDDLE EAST} 1}}

	set dists(o_oprio) {{1-URGENT 1} {2-HIGH 1} {3-MEDIUM 1} {{4-NOT SPECIFIED} 1} {5-LOW 1}}

	set dists(rflag) {{R 1} {A 1}}

	set dists(smode) {{{REG AIR} 1} {AIR 1} {RAIL 1} {TRUCK 1} {MAIL 1} {FOB 1} {SHIP 1}}

	set dists(p_types) {{{STANDARD ANODIZED TIN} 1} {{STANDARD ANODIZED NICKEL} 1} {{STANDARD ANODIZED BRASS} 1} \
		            {{STANDARD ANODIZED STEEL} 1} {{STANDARD ANODIZED COPPER} 1} {{STANDARD BURNISHED TIN} 1} \
			    {{STANDARD BURNISHED NICKEL} 1} {{STANDARD BURNISHED BRASS} 1} {{STANDARD BURNISHED STEEL} 1} \
			    {{STANDARD BURNISHED COPPER} 1} {{STANDARD PLATED TIN} 1} {{STANDARD PLATED NICKEL} 1} \
			    {{STANDARD PLATED BRASS} 1} {{STANDARD PLATED STEEL} 1} {{STANDARD PLATED COPPER} 1} \
			    {{STANDARD POLISHED TIN} 1} {{STANDARD POLISHED NICKEL} 1} {{STANDARD POLISHED BRASS} 1} \
			    {{STANDARD POLISHED STEEL} 1} {{STANDARD POLISHED COPPER} 1} {{STANDARD BRUSHED TIN} 1} \
			    {{STANDARD BRUSHED NICKEL} 1} {{STANDARD BRUSHED BRASS} 1} {{STANDARD BRUSHED STEEL} 1} \
			    {{STANDARD BRUSHED COPPER} 1} {{SMALL ANODIZED TIN} 1} {{SMALL ANODIZED NICKEL} 1} \
			    {{SMALL ANODIZED BRASS} 1} {{SMALL ANODIZED STEEL} 1} {{SMALL ANODIZED COPPER} 1} \
			    {{SMALL BURNISHED TIN} 1} {{SMALL BURNISHED NICKEL} 1} {{SMALL BURNISHED BRASS} 1} \
			    {{SMALL BURNISHED STEEL} 1} {{SMALL BURNISHED COPPER} 1} {{SMALL PLATED TIN} 1} \
			    {{SMALL PLATED NICKEL} 1} {{SMALL PLATED BRASS} 1} {{SMALL PLATED STEEL} 1} {{SMALL PLATED COPPER} 1} \
			    {{SMALL POLISHED TIN} 1} {{SMALL POLISHED NICKEL} 1} {{SMALL POLISHED BRASS} 1} \
			    {{SMALL POLISHED STEEL} 1} {{SMALL POLISHED COPPER} 1} {{SMALL BRUSHED TIN} 1} \
			    {{SMALL BRUSHED NICKEL} 1} {{SMALL BRUSHED BRASS} 1} {{SMALL BRUSHED STEEL} 1} \
			    {{SMALL BRUSHED COPPER} 1} {{MEDIUM ANODIZED TIN} 1} {{MEDIUM ANODIZED NICKEL} 1} \
			    {{MEDIUM ANODIZED BRASS} 1} {{MEDIUM ANODIZED STEEL} 1} {{MEDIUM ANODIZED COPPER} 1} \
			    {{MEDIUM BURNISHED TIN} 1} {{MEDIUM BURNISHED NICKEL} 1} {{MEDIUM BURNISHED BRASS} 1} \
			    {{MEDIUM BURNISHED STEEL} 1} {{MEDIUM BURNISHED COPPER} 1} {{MEDIUM PLATED TIN} 1} \
			    {{MEDIUM PLATED NICKEL} 1} {{MEDIUM PLATED BRASS} 1} {{MEDIUM PLATED STEEL} 1} \
			    {{MEDIUM PLATED COPPER} 1} {{MEDIUM POLISHED TIN} 1} {{MEDIUM POLISHED NICKEL} 1} \
			    {{MEDIUM POLISHED BRASS} 1} {{MEDIUM POLISHED STEEL} 1} {{MEDIUM POLISHED COPPER} 1} \
			    {{MEDIUM BRUSHED TIN} 1} {{MEDIUM BRUSHED NICKEL} 1} {{MEDIUM BRUSHED BRASS} 1} \
			    {{MEDIUM BRUSHED STEEL} 1} {{MEDIUM BRUSHED COPPER} 1} {{LARGE ANODIZED TIN} 1} \
			    {{LARGE ANODIZED NICKEL} 1} {{LARGE ANODIZED BRASS} 1} {{LARGE ANODIZED STEEL} 1} \
			    {{LARGE ANODIZED COPPER} 1} {{LARGE BURNISHED TIN} 1} {{LARGE BURNISHED NICKEL} 1} \
			    {{LARGE BURNISHED BRASS} 1} {{LARGE BURNISHED STEEL} 1} {{LARGE BURNISHED COPPER} 1} \
			    {{LARGE PLATED TIN} 1} {{LARGE PLATED NICKEL} 1} {{LARGE PLATED BRASS} 1} {{LARGE PLATED STEEL} 1} \
			    {{LARGE PLATED COPPER} 1} {{LARGE POLISHED TIN} 1} {{LARGE POLISHED NICKEL} 1} {{LARGE POLISHED BRASS} 1} \
			    {{LARGE POLISHED STEEL} 1} {{LARGE POLISHED COPPER} 1} {{LARGE BRUSHED TIN} 1} {{LARGE BRUSHED NICKEL} 1} \
			    {{LARGE BRUSHED BRASS} 1} {{LARGE BRUSHED STEEL} 1} {{LARGE BRUSHED COPPER} 1} {{ECONOMY ANODIZED TIN} 1} \
			    {{ECONOMY ANODIZED NICKEL} 1} {{ECONOMY ANODIZED BRASS} 1} {{ECONOMY ANODIZED STEEL} 1} \
			    {{ECONOMY ANODIZED COPPER} 1} {{ECONOMY BURNISHED TIN} 1} {{ECONOMY BURNISHED NICKEL} 1} \
			    {{ECONOMY BURNISHED BRASS} 1} {{ECONOMY BURNISHED STEEL} 1} {{ECONOMY BURNISHED COPPER} 1} \
			    {{ECONOMY PLATED TIN} 1} {{ECONOMY PLATED NICKEL} 1} {{ECONOMY PLATED BRASS} 1} {{ECONOMY PLATED STEEL} 1} \
			    {{ECONOMY PLATED COPPER} 1} {{ECONOMY POLISHED TIN} 1} {{ECONOMY POLISHED NICKEL} 1} \
			    {{ECONOMY POLISHED BRASS} 1} {{ECONOMY POLISHED STEEL} 1} {{ECONOMY POLISHED COPPER} 1} \
			    {{ECONOMY BRUSHED TIN} 1} {{ECONOMY BRUSHED NICKEL} 1} {{ECONOMY BRUSHED BRASS} 1} {{ECONOMY BRUSHED STEEL} 1} \
			    {{ECONOMY BRUSHED COPPER} 1} {{PROMO ANODIZED TIN} 1} {{PROMO ANODIZED NICKEL} 1} {{PROMO ANODIZED BRASS} 1} \
			    {{PROMO ANODIZED STEEL} 1} {{PROMO ANODIZED COPPER} 1} {{PROMO BURNISHED TIN} 1} {{PROMO BURNISHED NICKEL} 1} \
			    {{PROMO BURNISHED BRASS} 1} {{PROMO BURNISHED STEEL} 1} {{PROMO BURNISHED COPPER} 1} {{PROMO PLATED TIN} 1} \
			    {{PROMO PLATED NICKEL} 1} {{PROMO PLATED BRASS} 1} {{PROMO PLATED STEEL} 1} {{PROMO PLATED COPPER} 1} \
			    {{PROMO POLISHED TIN} 1} {{PROMO POLISHED NICKEL} 1} {{PROMO POLISHED BRASS} 1} {{PROMO POLISHED STEEL} 1} \
			    {{PROMO POLISHED COPPER} 1} {{PROMO BRUSHED TIN} 1} {{PROMO BRUSHED NICKEL} 1} {{PROMO BRUSHED BRASS} 1} \
			    {{PROMO BRUSHED STEEL} 1} {{PROMO BRUSHED COPPER} 1}}

	set dists(colors) {{almond 1} {antique 1} {aquamarine 1} {azure 1} {beige 1} {bisque 1} {black 1} {blanched 1} {blue 1} {blush 1} \
		           {brown 1} {burlywood 1} {burnished 1} {chartreuse 1} {chiffon 1} {chocolate 1} {coral 1} {cornflower 1} \
			   {cornsilk 1} {cream 1} {cyan 1} {dark 1} {deep 1} {dim 1} {dodger 1} {drab 1} {firebrick 1} {floral 1} {forest 1} \
			   {frosted 1} {gainsboro 1} {ghost 1} {goldenrod 1} {green 1} {grey 1} {honeydew 1} {hot 1} {indian 1} {ivory 1} \
			   {khaki 1} {lace 1} {lavender 1} {lawn 1} {lemon 1} {light 1} {lime 1} {linen 1} {magenta 1} {maroon 1} {medium 1} \
			   {metallic 1} {midnight 1} {mint 1} {misty 1} {moccasin 1} {navajo 1} {navy 1} {olive 1} {orange 1} {orchid 1} \
			   {pale 1} {papaya 1} {peach 1} {peru 1} {pink 1} {plum 1} {powder 1} {puff 1} {purple 1} {red 1} {rose 1} {rosy 1} \
			   {royal 1} {saddle 1} {salmon 1} {sandy 1} {seashell 1} {sienna 1} {sky 1} {slate 1} {smoke 1} {snow 1} {spring 1} \
			   {steel 1} {tan 1} {thistle 1} {tomato 1} {turquoise 1} {violet 1} {wheat 1} {white 1} {yellow 1}}

	set dists(nouns) {{packages 40} {requests 40} {accounts 40} {deposits 40} {foxes 20} {ideas 20} {theodolites 20} {{pinto beans} 20} \
		          {instructions 20} {dependencies 10} {excuses 10} {platelets 10} {asymptotes 10} {courts 5} {dolphins 5} \
			  {multipliers 1} {sauternes 1} {warthogs 1} {frets 1} {dinos 1} {attainments 1} {somas 1} {Tiresias 1} {patterns 1} \
			  {forges 1} {braids 1} {frays 1} {warhorses 1} {dugouts 1} {notornis 1} {epitaphs 1} {pearls 1} {tithes 1} {waters 1} \
			  {orbits 1} {gifts 1} {sheaves 1} {depths 1} {sentiments 1} {decoys 1} {realms 1} {pains 1} {grouches 1} {escapades 1} {{hockey players} 1}}

	set dists(verbs) {{sleep 20} {wake 20} {are 20} {cajole 20} {haggle 20} {nag 10} {use 10} {boost 10} {affix 5} {detect 5} {integrate 5} \
		          {maintain 1} {nod 1} {was 1} {lose 1} {sublate 1} {solve 1} {thrash 1} {promise 1} {engage 1} {hinder 1} {print 1} \
			  {x-ray 1} {breach 1} {eat 1} {grow 1} {impress 1} {mold 1} {poach 1} {serve 1} {run 1} {dazzle 1} {snooze 1} {doze 1} \
			  {unwind 1} {kindle 1} {play 1} {hang 1} {believe 1} {doubt 1}}

	set dists(adverbs) {{sometimes 1} {always 1} {never 1} {furiously 50} {slyly 50} {carefully 50} {blithely 40} {quickly 30} {fluffily 20} \
		            {slowly 1} {quietly 1} {ruthlessly 1} {thinly 1} {closely 1} {doggedly 1} {daringly 1} {bravely 1} {stealthily 1} \
			    {permanently 1} {enticingly 1} {idly 1} {busily 1} {regularly 1} {finally 1} {ironically 1} {evenly 1} {boldly 1} {silently 1}}

	set dists(articles) {{the 50} {a 20} {an 5}}

	set dists(prepositions) {{about 50} {above 50} {{according to} 50} {across 50} {after 50} {against 40} {along 40} {{alongside of} 30} \
		                 {among 30} {around 20} {at 10} {atop 1} {before 1} {behind 1} {beneath 1} {beside 1} {besides 1} {between 1} \
				 {beyond 1} {by 1} {despite 1} {during 1} {except 1} {for 1} {from 1} {{in place of} 1} {inside 1} \
				 {{instead of} 1} {into 1} {near 1} {of 1} {on 1} {outside 1} {over {1 }} {past 1} {since 1} {through 1} \
				 {throughout 1} {to 1} {toward 1} {under 1} {until 1} {up {1 }} {upon 1} {whithout 1} {with 1} {within 1}}

	set dists(auxillaries) {{do 1} {may 1} {might 1} {shall 1} {will 1} {would 1} {can 1} {could 1} {should 1} {{ought to} 1} {must 1} \
		                {{will have to} 1} {{shall have to} 1} {{could have to} 1} {{should have to} 1} {{must have to} 1} {{need to} 1} {{try to} 1}}

	set dists(terminators) {{. 50} {{;} 1} {: 1} {? 1} {! 1} {-- 1}}

	set dists(adjectives) {{special 20} {pending 20} {unusual 20} {express 20} {furious 1} {sly 1} {careful 1} {blithe 1} {quick 1} \
		               {fluffy 1} {slow 1} {quiet 1} {ruthless 1} {thin 1} {close 1} {dogged 1} {daring 1} {brave 1} {stealthy 1} \
			       {permanent 1} {enticing 1} {idle 1} {busy 1} {regular 50} {final 40} {ironic 40} {even 30} {bold 20} {silent 10}}

	set dists(grammar) {{{N V T} 3} {{N V P T} 3} {{N V N T} 3} {{N P V N T} 1} {{N P V P T} 1}}

	set dists(np) {{N 10} {{J N} 20} {{J J N} 10} {{D J N} 50}}

	set dists(vp) {{V 30} {{X V} 1} {{V D} 40} {{X V D} 1}}
	
	set dists(Q13a) {{special 20} {pending 20} {unusual 20} {express 20}}
	
	set dists(Q13b) {{packages 40} {requests 40} {accounts 40} {deposits 40}}
}

proc get_dists { dist_type } {
global dists
	if { ![ array exists dists ] } { set_dists }
	return $dists($dist_type)
}

proc set_dist_list {dist_type} {
global dists weights dist_names dist_weights
	set name $dist_type
	set dist_list $dists($dist_type)
	set dist_list_length [ llength $dist_list ]
	if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
		set max_weight [ calc_weight $dist_list $name ]
	}
	set i 0
	while {$i < $dist_list_length} {
		set dist_name [ lindex [lindex $dist_list $i ] 0 ]
		set dist_value [ lindex [ join [lindex $dist_list $i ] ] end ]
		lappend dist_names($dist_type) $dist_name
		lappend dist_weights($dist_type) $dist_value 
		incr i
	}
}

proc LEAP { y } {
	return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
	if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

proc julian { date } {
	set offset [ expr {$date - 92001} ]
	set result 92001
	while { 1 eq 1 } {
		set yr [ expr {$result / 1000} ]
		set yend [ expr {$yr * 1000 + 365 + [ LEAP $yr ]} ]
		if { [ expr {$result + $offset > $yend} ] } {
			set offset [ expr {$offset - ($yend - $result + 1)} ]
			set result [ expr {$result + 1000} ]
			continue
		} else { break }
	}
	return [ expr {$result + $offset} ]
}

proc mk_time { index } {
	set list {JAN 31 31 FEB 28 59 MAR 31 90 APR 30 120 MAY 31 151 JUN 30 181 JUL 31 212 AUG 31 243 SEP 30 273 OCT 31 304 NOV 30 334 DEC 31 365}
	set timekey [ expr {$index + 8035} ]
	set jyd [ julian [ expr {($index + 92001 - 1)} ] ] 
	set y [ expr {$jyd / 1000} ]
	set d [ expr {$jyd % 1000} ]
	set year [ expr {1900 + $y} ]
	set m 2
	set n [ llength $list ]
	set month [ lindex $list [ expr {$m - 2} ] ]
	set day $d
	while { ($d > [ expr {[ lindex $list $m ] + [ LEAP_ADJ $y [ expr {($m + 1) / 3} ]]}]) } {
		set month [ lindex $list [ expr $m + 1 ] ]
		set day [ expr {$d - [ lindex $list $m ] - [ LEAP_ADJ $y [ expr ($m + 1) / 3 ] ]} ]
		incr m +3
	}
	set day [ format %02d $day ]
	return [ concat $year-$month-$day ]
}

proc mk_sparse { i seq } {
	set ok $i
	set low_bits [ expr {$i & ((1 << 3) - 1)} ]
	set ok [ expr {$ok >> 3} ]
	set ok [ expr {$ok << 2} ]
	set ok [ expr {$ok + $seq} ]
	set ok [ expr {$ok << 3} ]
	set ok [ expr {$ok + $low_bits} ]
	return $ok
}

proc PART_SUPP_BRIDGE { p s db_scale } {
	set tot_scnt [ expr {10000 * $db_scale} ]
	set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
	return $suppkey
}

proc rpb_routine { p } {
	set price 90000
	set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
	set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
	return $price
}

proc gen_phone {} {
	set acode [ RandomNumber 100 999 ]
	set exchg [ RandomNumber 100 999 ]
	set number [ RandomNumber 1000 9999 ]
	return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
	set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
	for {set i 0} {$i < $len } {incr i } {
		append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
	}
	return $alphastring
}

proc calc_weight { list name } {
global weights
	set total 0
	set n [ expr {[llength $list] - 1} ]
	while {$n >= 0} {
		set interim [ lindex [ join [lindex $list $n] ] end ]
		set total [ expr {$total + $interim} ]
		incr n -1
	}
	set weights($name) $total
	return $total
}

proc pick_str { name } {
global weights dist_names dist_weights
	set total 0
	set i 0
	set ran_weight [ RandomNumber 1  $weights($name) ]
	while {$total < $ran_weight} {
		set total [ expr {$total + [lindex $dist_weights($name) $i ]} ]
		incr i
	}
	return  [lindex $dist_names($name) [ expr {$i - 1} ]]
}

proc txt_vp {} {
	set verb_list [ split [ pick_str vp ] ]
	set c 0
	set n [ expr {[llength $verb_list] - 1} ]
	while {$c <= $n } {
		set interim [lindex $verb_list $c]
		switch $interim {
			D { set src adverbs }
			V { set src verbs }
			X { set src auxillaries }
		}
		append verb_p [ pick_str $src ] " "
		incr c
	}
	return $verb_p
}

proc txt_np {} {
	set noun_list [ split [ pick_str np ] ]
	set c 0
	set n [ expr {[llength $noun_list] - 1} ]
	while {$c <= $n } {
		set interim [lindex $noun_list $c]
		switch $interim {
			A { set src articles }
			J { set src adjectives }
			D { set src adverbs }
			N { set src nouns }
		}
		append verb_p [ pick_str $src ] " "
		incr c
	}
	return $verb_p
}

proc txt_sentence {} {
	set sen_list [ split [ pick_str grammar ] ]
	set c 0
	set n [ expr {[llength $sen_list] - 1} ]
	while {$c <= $n } {
		set interim [lindex $sen_list $c]
		switch $interim {
			V { append txt [ txt_vp ] }
			N { append txt [ txt_np ] }
			P { append txt [ pick_str prepositions ] " the "
			    append txt [ txt_np ] }
			T { set txt [ string trimright $txt ]
			    append txt [ pick_str terminators ] }
		}
		incr c
	}
	return $txt
}

proc dbg_text {min max} {
	set wordlen 0
	set needed false
	set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
	while { $wordlen < $length } {
		set part_sen [ txt_sentence ] 
		set s_len [ string length $part_sen ]
		set needed [ expr {$length - $wordlen} ]
		if { $needed >= [ expr {$s_len + 1} ] } {
			append sentence "$part_sen "
			set wordlen [ expr {$wordlen + $s_len + 1}]
		} else {
			append sentence [ string range $part_sen 0 $needed ] 
			set wordlen [ expr {$wordlen + $needed} ]
		}
	}
	return $sentence
}

proc V_STR { avg } {
	set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
	set chalen [ llength $globArray ]
	return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
	return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}


proc Make_region { log_id gen_files file_id sec_name rdbms hodbc dbhandle dbcur xlevel} {
	set m_info "loading_REGION" 
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i 1 } { $i <= 5 } {incr i} {
		set code [ expr {$i - 1} ]
		set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
		set comment [ TEXT 72 ]
		if {$gen_files == 1 } {
			puts $file_id "$code=$text=$comment="
		} else {
			set sql_cmd "INSERT INTO region (r_regionkey, r_name, r_comment) VALUES ('$code' , '$text' , '$comment')"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
		}
	}
	if {$gen_files == 1 }  {
		close $file_id
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
	return
}

proc Make_nation { log_id gen_files file_id sec_name rdbms hodbc dbhandle dbcur xlevel} {
	set m_info "loading_NATION" 
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i 1 } { $i <= 25 } {incr i} {
		set code [ expr {$i - 1} ]
		set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
		set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
		switch $nind {
			0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
			1 - 2 - 3 - 17 - 24 { set join 1 }
			8 - 9 - 12 - 18 - 21 { set join 2 }
			6 - 7 - 19 - 22 - 23 { set join 3 }
			10 - 11 - 13 - 20 { set join 4 }
		}
		set comment [ TEXT 72 ]
		if {$gen_files == 1 } {
			puts $file_id "$code=$text=$join=$comment="
		} else {
			set sql_cmd "INSERT INTO nation (n_nationkey, n_name, n_regionkey, n_comment) VALUES ('$code' , '$text' , '$join' , '$comment')"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
		}
	}
	if {$gen_files == 1 } {
		close $file_id
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
	return
}

proc Make_supp { log_id gen_files base_sec_dir rdbms hodbc dbhandle dbcur sec_name l_thread threads db_rows xlevel} {

	if {$gen_files == 1} {
		set file_data_out [file join $base_sec_dir [format "supplier_%03d.dat" $l_thread ]]
		set id_data_out [open $file_data_out w]
	} 
	set sf_mult 1
	set db_chunk [expr { $db_rows / $threads }]
	set start_rows [expr {(($l_thread-1)*$db_chunk)+1}]
	set end_rows   [expr {$l_thread*$db_chunk}]
	set BBB_COMMEND   "Recommends"
	set BBB_COMPLAIN  "Complaints"
	set m_info "loading_SUPPLIER"
	flush stdout
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i $start_rows } { $i <= $end_rows } { incr i } {
		set suppkey $i
		set name [ concat Supplier#[format %1.9d $i]]
		set address [ V_STR 25 ]
		set nation_code [ RandomNumber 0 24 ]
		set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
		set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
		set comment [ TEXT 63 ]
		set bad_press [ RandomNumber 1 10000 ]
		set type [ RandomNumber 0 100 ]
		set noise [ RandomNumber 0 19 ]
		set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
		if { $bad_press <= 10 } {
			set st [ expr {9 + $offset + $noise} ]
			set fi [ expr {$st + 10} ]
			if { $type < 50 } {
				set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
			} else {
				set comment [ string replace $comment $st $fi $BBB_COMMEND ]
			}
		}
		if {$gen_files == 1 } {
			puts $id_data_out "$suppkey=$nation_code=$comment=$name=$address=$phone=$acctbal="
			if { ![ expr {$i % 10000} ] } {
				Enter_log_item $log_id "generating_supplier"  $i $xlevel
			}
		} else {
			append supp_val_list ('$suppkey', '$nation_code', '$comment', '$name', '$address', '$phone', '$acctbal')
			set sql_cmd "INSERT INTO supplier (s_suppkey, s_nationkey, 
		             s_comment, s_name, s_address, s_phone, s_acctbal) VALUES $supp_val_list"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
			unset supp_val_list
			if { ![ expr {$i % 10000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
				Enter_log_item $log_id "loading_supplier"  $i $xlevel
			}
		}
	}
	if {$gen_files ==1 } {
		close $id_data_out
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
	return
}

proc Make_cust { log_id gen_files base_sec_dir rdbms hodbc dbhandle dbcur sec_name l_thread threads db_rows xlevel} {

	if {$gen_files == 1} {
		set file_data_out [file join $base_sec_dir [format "customer_%03d.dat" $l_thread]]
		set id_data_out [open $file_data_out w]
	} 
	set cust_mult 15

	set db_chunk [expr { ($db_rows*$cust_mult) / $threads }]
	set start_rows [expr {(($l_thread-1)*$db_chunk)+1}]
	set end_rows   [expr {$l_thread*$db_chunk}]
	set m_info "loading_CUSTOMER" 
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i $start_rows } { $i <= $end_rows } { incr i } {
		set custkey $i
		set name [ concat Customer#[format %1.9d $i]]
		set address [ V_STR 25 ]
		set nation_code [ RandomNumber 0 24 ]
		set phone [ gen_phone ]
		set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
		set mktsegment [ pick_str msegmnt ]
		set comment [ TEXT 73 ]
		if {$gen_files == 1} {
			puts $id_data_out "$custkey=$mktsegment=$nation_code=$name=$address=$phone=$acctbal=$comment="
			if { ![ expr {$i % 10000} ] } {
				Enter_log_item $log_id "generating_customer"  $i $xlevel
			}
		} else {
			append cust_val_list ('$custkey', '$mktsegment', '$nation_code', '$name', '$address', '$phone', '$acctbal', '$comment') 
			set sql_cmd "INSERT INTO customer (c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment) VALUES $cust_val_list"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
			unset cust_val_list
			if { ![ expr {$i % 10000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
				Enter_log_item $log_id "loading_customer"  $i $xlevel
			}
		}
	}
	if {$gen_files ==1 } {
		close $id_data_out
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
	return
}

proc Make_part { log_id gen_files base_sec_dir rdbms hodbc dbhandle dbcur sec_name l_thread threads db_rows db_scale xlevel} {

	if {$gen_files == 1} {
		set file_data_ps [file join $base_sec_dir [format "partsupp_%03d.dat" $l_thread ]]
		set id_data_ps [open $file_data_ps w]
		set file_data_part [file join $base_sec_dir [format "part_%03d.dat" $l_thread ]]
		set id_data_part [open $file_data_part w]
	} 

	set part_mult 20

	set db_chunk [expr { ($db_rows*$part_mult) / $threads }]
	set start_rows [expr {(($l_thread-1)*$db_chunk)+1}]
	set end_rows   [expr {$l_thread*$db_chunk}]
	set m_info  "loading_PART_PARTSUPPLY"
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i $start_rows } { $i <= $end_rows } { incr i } {
		set partkey $i
		unset -nocomplain name
		for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
			append name [ pick_str colors ] " "
		}
		append name [ pick_str colors ]
		set mf [ RandomNumber 1 5 ]
		set mfgr [ concat Manufacturer#$mf ]
		set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
		set type [ pick_str p_types ] 
		set size [ RandomNumber 1 50 ]
		set container [ pick_str p_cntr ] 
		set price [ rpb_routine $i ]
		set comment [ TEXT 14 ]
		append part_val_list ('$partkey', '$type', '$size', '$brand', '$name', '$container', '$mfgr', '$price', '$comment')
#Part Supp Loop
		for {set k 0} {$k < 4 } {incr k } {
			set psupp_pkey $partkey
			set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $db_scale ]
			set psupp_qty [ RandomNumber 1 9999 ]
			set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
			set psupp_comment [ TEXT 124 ]
			if {$gen_files == 1} {
				puts $id_data_ps "$psupp_pkey=$psupp_suppkey=$psupp_scost=$psupp_qty=$psupp_comment=" 
			} else {
				append psupp_val_list ('$psupp_pkey', '$psupp_suppkey', '$psupp_scost', '$psupp_qty', '$psupp_comment') 
				set sql_cmd "INSERT INTO partsupp (ps_partkey, ps_suppkey, 
			             	ps_supplycost, ps_availqty, ps_comment) VALUES $psupp_val_list"
				RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
				unset psupp_val_list
			}
		}	
# end of psupp loop
		if {$gen_files == 1} {
			puts $id_data_part "$partkey=$type=$size=$brand=$name=$container=$mfgr=$price=$comment="
			if { ![ expr {$i % 1000} ] } {
				Enter_log_item $log_id "generating_part_partsupply" [format "count %d -time- %s" $i [Time_out]] $xlevel
			}
		} else {
			set sql_cmd "INSERT INTO part (p_partkey, p_type, p_size, p_brand, p_name, 
		             	p_container, p_mfgr, p_retailprice, p_comment) VALUES $part_val_list"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
			if { ![ expr {$i % 1000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
				Enter_log_item $log_id "loading_part_partsupply" [format "count %d -time- %s" $i [Time_out]] $xlevel
			}
		}
		unset part_val_list
	}
	if {$gen_files == 1} {
		close $id_data_ps
		close $id_data_part
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
	return
}

proc Make_order { log_id gen_files base_sec_dir rdbms hodbc dbhandle dbcur sec_name l_thread threads db_rows upd_num db_scale xlevel} {

	if {$gen_files == 1} {
		set file_data_lineitem [file join $base_sec_dir [format "lineitem_%03d.dat" $l_thread ]]
		set id_data_lineitem [open $file_data_lineitem w]
		set file_data_orders [file join $base_sec_dir [format "orders_%03d.dat" $l_thread ]]
		set id_data_orders [open $file_data_orders w]
	} 
	set ord_mult 150

	set db_chunk [expr { ($db_rows*$ord_mult) / $threads }]
	set start_rows [expr {(($l_thread-1)*$db_chunk)+1}]
	set end_rows   [expr {$l_thread*$db_chunk}]
	set upd_num [expr {$upd_num % 10000} ]
	set refresh 100
	set delta 1
	set L_PKEY_MAX   [ expr {200000 * $db_scale} ]
	set O_CKEY_MAX [ expr {150000 * $db_scale} ]
	set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]

	set m_info "loading_ORDERS_LINEITEM"
	Enter_log_tag $log_id "S" $m_info 1 xlevel
	for { set i $start_rows } { $i <= $end_rows } { incr i } {
		if { $upd_num == 0 } {
			set okey [ mk_sparse $i $upd_num ]
		} else {
			set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
		}
		set custkey [ RandomNumber 1 $O_CKEY_MAX ]
		while { $custkey % 3 == 0 } {
			set custkey [ expr {$custkey + $delta} ]
			if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
				set custkey $min
				set delta [ expr {$delta * -1} ]
		}
		if { ![ array exists ascdate ] } {
			for { set d 1 } { $d <= 2557 } {incr d} {
				set ascdate($d) [ mk_time $d ]
			}
		}
		set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
		set date $ascdate([ expr {$tmp_date - 92001} ])
		set opriority [ pick_str o_oprio ] 
		set clk_num [ RandomNumber 1 [ expr {$db_scale * 1000} ] ]
		set clerk [ concat Clerk#[format %1.9d $clk_num]]
		set comment [ TEXT 49 ]
		set spriority 0
		set totalprice 0
		set orderstatus "O"
		set ocnt 0
		set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
		for { set l 0 } { $l < $lcnt } {incr l} {
			set lokey $okey
			set llcnt [ expr {$l + 1} ]
			set lquantity [ RandomNumber 1 50 ]
			set ldiscount [ RandomNumber 0 10 ]
			set ltax [ RandomNumber 0 8 ]
			set linstruct [ pick_str instruct ] 
			set lsmode [ pick_str smode ] 
			set lcomment [ TEXT 27 ]
			set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
			set rprice [ rpb_routine $lpartkey ]
			set supp_num [ RandomNumber 0 3 ]
			set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $db_scale ]
			set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
			set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
			set s_date [ RandomNumber 1 121 ]
			set s_date [ expr {$s_date + $tmp_date} ] 
			set c_date [ RandomNumber 30 90 ]
			set c_date [ expr {$c_date + $tmp_date} ]
			set r_date [ RandomNumber 1 30 ]
			set r_date [ expr {$r_date + $s_date} ]
			set lsdate $ascdate([ expr {$s_date - 92001} ])
			set lcdate $ascdate([ expr {$c_date - 92001} ])
			set lrdate $ascdate([ expr {$r_date - 92001} ])
			if { [ julian $r_date ] <= 95168 } {
				set lrflag [ pick_str rflag ] 
			} else { set lrflag "N" }
			if { [ julian $s_date ] <= 95168 } {
				incr ocnt
				set lstatus "F"
			} else { 
				set lstatus "O" 
			}
			set sk [string tolower $rdbms]
			switch $sk {
				mssql  { 
					append lineit_val_list ('$lsdate','$lokey', '$ldiscount', \
					                        '$leprice', '$lsuppkey', '$lquantity', \
								'$lrflag', '$lpartkey', '$lstatus', '$ltax', \
								'$lcdate', '$lrdate', '$lsmode', \
								'$llcnt', '$linstruct', '$lcomment') 
					if {$gen_files == 1 } {
						puts $id_data_lineitem "$lsdate=$lokey=$ldiscount=$leprice=$lsuppkey=$lquantity=$lrflag=$lpartkey=$lstatus=$ltax=$lcdate=$lrdate=$lsmode=$llcnt=$linstruct=$lcomment=" 
					}
			    }
				oracle { 
					append lineit_val_list (TO_DATE('$lsdate','YYYY-Mon-dd'),'$lokey', '$ldiscount', \
					                        '$leprice', '$lsuppkey', '$lquantity', \
								'$lrflag', '$lpartkey', '$lstatus', '$ltax', \
								TO_DATE('$lcdate','YYYY-Mon-dd'), \
								TO_DATE('$lrdate','YYYY-Mon-dd'), '$lsmode', \
								'$llcnt', '$linstruct', '$lcomment') 
					if {$gen_files == 1 } {
						puts "NEED lineitem generate file for oracle"
					}

			    }
				pgsql  {
					puts "NEED lineitem append for pgsql"
					append lineit_val_list ('$lsdate','$lokey', '$ldiscount', \
					                        '$leprice', '$lsuppkey', '$lquantity', \
								'$lrflag', '$lpartkey', '$lstatus', '$ltax', \
								'$lcdate', '$lrdate', '$lsmode', \
								'$llcnt', '$linstruct', '$lcomment') 
					if {$gen_files == 1 } {
						puts "NEED lineitem generate file for pgsql"
					}
				}
				mysql  { 
					puts "NEED lineitem append for mysql"
					append lineit_val_list ('$lsdate','$lokey', '$ldiscount', \
					                        '$leprice', '$lsuppkey', '$lquantity', \
								'$lrflag', '$lpartkey', '$lstatus', '$ltax', \
								'$lcdate', '$lrdate', '$lsmode', \
								'$llcnt', '$linstruct', '$lcomment') 
					if {$gen_files == 1 } {
						puts "NEED lineitem generate file for mysql"
					}
				}
			}


			if {$gen_files == 0} {
				set sql_cmd "INSERT INTO lineitem (l_shipdate, l_orderkey, l_discount, l_extendedprice, 
		             		l_suppkey, l_quantity, l_returnflag, l_partkey, l_linestatus, l_tax, 
			     			l_commitdate, l_receiptdate, l_shipmode, l_linenumber, l_shipinstruct, 
			     			l_comment) VALUES $lineit_val_list"
			     
				RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
			}
			unset lineit_val_list
			continue
			# Need to remove this as it is never hit
			#if { $l < [ expr $lcnt - 1 ] } { 
		#		append lineit_val_list ,
		#	} else {
		#		if { $bld_cnt<= 1 } { 
		#			append lineit_val_list ,
		#		}
		#	}
  		}
		if { $ocnt > 0} { set orderstatus "P" }
		if { $ocnt == $lcnt } { set orderstatus "F" }
		set sk [string tolower $rdbms]
		switch $sk {
			mssql  { 
				append order_val_list ('$date', '$okey', '$custkey', '$opriority', \
				                       '$spriority', '$clerk', '$orderstatus', \
						       '$totalprice', '$comment') 
				if {$gen_files == 1 } {
					puts $id_data_orders "$date=$okey=$custkey=$opriority=$spriority=$clerk=$orderstatus=$totalprice=$comment=" 
					if { ![ expr {$i % 1000} ] } {
						Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
						Enter_log_item $log_id "generating_orders_lineitem" [format "count %d -time-  %s" $i [Time_out]] $xlevel
					}
				}
			}
			oracle { 
				append order_val_list (TO_DATE('$date','YYYY-Mon-dd'), '$okey', \
						       '$custkey', '$opriority', \
				                       '$spriority', '$clerk', '$orderstatus', \
						       '$totalprice', '$comment') 
				if {$gen_files == 1 } {
					puts "NEED orders generate file for oracle"
				}
		    }
			pgsql  {
				puts "NEED orders append for pgsql"
				if {$gen_files == 1 } {
					puts "NEED orders generate file for pgsql"
				}
		    }
			mysql  { 
				puts "NEED orders append for mysql"
				if {$gen_files == 1 } {
					puts "NEED orders generate file for mysql"
				}
		    }
		}
		if {$gen_files == 0 } {
			set sql_cmd "INSERT INTO orders (o_orderdate, o_orderkey, o_custkey, o_orderpriority, 
		             	o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment) VALUES $order_val_list"
			RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql_cmd "" 0 0 0
   		
			if { ![ expr {$i % 1000} ] } {
				Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
				Enter_log_item $log_id "loading_orders_lineitem" [format "count %d -time-  %s" $i [Time_out]] $xlevel
			}
		}
		unset order_val_list
	}
	if {$gen_files == 1 } {
		Enter_log_item $log_id "closing_log_files" "lineitem and orders" $xlevel
		close $id_data_lineitem
		close $id_data_orders
	} else {
		Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	}
	Enter_log_tag $log_id "E" $m_info 1 xlevel
}

proc Run_refresh1_sql1 {rdbms hodbc dbhandle dbcur date okey custkey opriority spriority clerk orderstatus totalprice comment } {
	set sk [string tolower $rdbms]
	switch $sk {
			mssql  { 
					$hodbc  "INSERT INTO orders (o_orderdate, o_orderkey, o_custkey, o_orderpriority, 
	                        o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment) 
				            VALUES ('$date', '$okey', '$custkey', '$opriority', '$spriority', '$clerk', 
					                 '$orderstatus', '$totalprice', '$comment')"
			}
			mysql  { 
					puts "No MySQL yet for refresh1_sql1"
					exit
			}
			pgsql  { 
					puts "No PGSQL yet for refresh1_sql1"
					exit
			}
			oracle { 
					orabind $dbcur  :O_ORDERDATE $date :O_ORDERKEY $okey \
						            :O_CUSTKEY $custkey :O_ORDERPRIORITY $opriority \
								    :O_SHIPPRIORITY $spriority :O_CLERK $clerk \
								    :O_ORDERSTATUS $orderstatus :O_TOTALPRICE $totalprice \
								    :O_COMMENT $comment
					if {[catch {oraexec $dbcur} message]} {
							puts "ERROR: Refresh1 SQL1"
							puts $message
							exit
					}
			}
	}
			
}

proc Run_refresh1_sql2 {rdbms hodbc dbhandle dbcur lsdate lokey ldiscount leprice lsuppkey lquantity lrflag lpartkey \
		lstatus ltax lcdate lrdate lsmode llcnt linstruct lcomment } {
	set sk [string tolower $rdbms]
	switch $sk {
			mssql  { 
					$hodbc  "INSERT INTO lineitem (l_shipdate, l_orderkey, l_discount, l_extendedprice, 
	                         l_suppkey, l_quantity, l_returnflag, l_partkey, 
						     l_linestatus, l_tax, l_commitdate, l_receiptdate, 
						     l_shipmode, l_linenumber, l_shipinstruct, l_comment) 
					    VALUES ('$lsdate','$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', 
						        '$lrflag', '$lpartkey', '$lstatus', '$ltax', '$lcdate', '$lrdate', 
								'$lsmode', '$llcnt', '$linstruct', '$lcomment')"
			}
			mysql  { 
					puts "No MySQL yet for refresh1_sql1"
					exit
			}
			pgsql  { 
					puts "No PGSQL yet for refresh1_sql1"
					exit
			}
			oracle { 
					orabind $dbcur :L_SHIPDATE $lsdate :L_ORDERKEY $lokey \
					        	   :L_DISCOUNT $ldiscount :L_EXTENDEDPRICE $leprice \
								   :L_SUPPKEY $lsuppkey :L_QUANTITY $lquantity \
								   :L_RETURNFLAG $lrflag :L_PARTKEY $lpartkey \
								   :L_LINESTATUS $lstatus :L_TAX $ltax :L_COMMITDATE $lcdate \
								   :L_RECEIPTDATE $lrdate :L_SHIPMODE $lsmode \
								   :L_LINENUMBER $llcnt :L_SHIPINSTRUCT $linstruct :L_COMMENT $lcomment 
					if {[catch {oraexec $dbcur} message]} {
							puts "ERROR: Refresh1 SQL1"
							puts $message
					}
			}
	}
			
}

proc Run_refresh2_sql1 {rdbms hodbc dbhandle dbcur okey } {
	set sk [string tolower $rdbms]
	switch $sk {
			mssql  { 
					$hodbc "DELETE FROM orders WHERE o_orderkey = $okey"
			}
			mysql  { 
					puts "No MySQL yet for refresh2_sql1"
					exit
			}
			pgsql  { 
					puts "No PGSQL yet for refresh2_sql1"
					exit
			}
			oracle { 
					orabind $dbcur  :O_ORDERKEY $okey 
					if {[catch {oraexec $dbcur} message]} {
							puts "ERROR: Refresh2 SQL1"
							puts $message
							exit
					}
			}
	}
			
}

proc Run_refresh2_sql2 {rdbms hodbc dbhandle dbcur okey } {
	set sk [string tolower $rdbms]
	switch $sk {
			mssql  { 
					$hodbc "DELETE FROM lineitem WHERE l_orderkey = $okey"
			}
			mysql  { 
					puts "No MySQL yet for refresh2_sql2"
					exit
			}
			pgsql  { 
					puts "No PGSQL yet for refresh2_sql2"
					exit
			}
			oracle { 
					orabind $dbcur  :L_ORDERKEY $okey 
					if {[catch {oraexec $dbcur} message]} {
							puts "ERROR: Refresh2 SQL2"
							puts $message
							exit
					}
			}
	}
			
}

proc Set_refresh1_sql { rdbms which connect hodbc dbhandle} {
global dists weights dist_names dist_weights sql
	
	set sk [string tolower $rdbms]
	switch $sk {
			mssql {
					# Nothing to do here - all in the running
					set sql(1) "NOT_USED"
					set sql(2) "NOT_USED"
			}
			mysql {
					puts "Refresh1 SQL set isn't done for MySQL yet!"
					exit
			}
			oracle {
					if {$which == 1 } {
				 		set sql(1)  "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, 
					                                     O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, 
													     O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) 
								 	VALUES (TO_DATE(:O_ORDERDATE,'YYYY-MM-DD'), :O_ORDERKEY, 
								 	:O_CUSTKEY, :O_ORDERPRIORITY, :O_SHIPPRIORITY, :O_CLERK, 
								 	:O_ORDERSTATUS, :O_TOTALPRICE, :O_COMMENT)"
						set dbcur1 [ oraopen $dbhandle]
						oraparse $dbcur1 $sql(1)
						return $dbcur1
					}
					
					if {$which == 2 } { 
						set sql(2) "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, 
					                                  	  L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, 
													      L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, 
													      L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, 
													      L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) 
							    	values (TO_DATE(:L_SHIPDATE,'YYYY-MM-DD'), :L_ORDERKEY, :L_DISCOUNT, 
									:L_EXTENDEDPRICE, :L_SUPPKEY, :L_QUANTITY, :L_RETURNFLAG, :L_PARTKEY, 
									:L_LINESTATUS, :L_TAX, TO_DATE(:L_COMMITDATE,'YYYY-MM-DD'), 
									TO_DATE(:L_RECEIPTDATE,'YYYY-MM-DD'), :L_SHIPMODE, :L_LINENUMBER, 
									:L_SHIPINSTRUCT, :L_COMMENT)"

						set dbcur2 [ oraopen $dbhandle]
						oraparse $dbcur2 $sql(2)
						return $dbcur2
					}
			}
			pgsql {
					puts "Refresh1 SQL set isn't done for PGSQL yet!"
					exit
			}
	}
}

proc Set_refresh2_sql { rdbms which connect dbhandle} {
global dists weights dist_names dist_weights sql
	
	set sk [string tolower $rdbms]
	switch $sk {
			mssql {
					# Nothing to do here - all in the running
					set sql(1) "NOT_USED"
					set sql(2) "NOT_USED"
			}
			mysql {
					puts "Refresh1 SQL set isn't done for MySQL yet!"
					exit
			}
			oracle {
					if {$which == 1 } {
				 		set sql(1)  "DELETE FROM ORDERS WHERE O_ORDERKEY = :O_ORDERKEY"
						set dbcur1 [ oraopen $dbhandle]
						oraparse $dbcur1 $sql(1)
						return $dbcur1
					}
					
					if {$which == 2 } { 
						set sql(2) "DELETE FROM LINEITEM WHERE L_ORDERKEY = :L_ORDERKEY"
						set dbcur2 [ oraopen $dbhandle]
						oraparse $dbcur2 $sql(2)
						return $dbcur2
					}
			}
			pgsql {
					puts "Refresh1 SQL set isn't done for PGSQL yet!"
					exit
			}
	}
}

proc refresh_pick_str { pdists name } {
global dists weights dist_names dist_weights sql
	set total 0
	set i 0
	if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
		set max_weight [ calc_weight $pdists $name ]
	}
	set ran_weight [ RandomNumber 1 $max_weight ]
	while {$total < $ran_weight} {
		set interim [ lindex [ join [lindex $pdists $i ] ] end ]
		set total [ expr {$total + $interim} ]
		incr i
	}
	set pkstr [ lindex [lindex $pdists [ expr {$i - 1} ] ] 0 ]
	return $pkstr
}


proc Do_refresh1 { log_id rdbms sec_name connect hodbc dbhandle database_name scale_factor xlevel} {
global dists weights dist_names dist_weights sql
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
	

	set upd_num  1
	set dbcur1   "NOT_USED"
	set dbcur2   "NOT_USED"
	set dbcur1 [Set_refresh1_sql $rdbms 1 $connect $hodbc $dbhandle]
	set dbcur2 [Set_refresh1_sql $rdbms 2 $connect $hodbc $dbhandle]

	set refresh 100
	set delta 1
	set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
	set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
	set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
	set sfrows [ expr {$scale_factor * 1500} ] 
	set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
	set endindex [ expr {$upd_num * $sfrows} ]

	set start_time [clock milliseconds]
	for { set i $startindex } { $i <= $endindex } { incr i } {
		set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
		set custkey [ RandomNumber 1 $O_CKEY_MAX ]
		while { $custkey % 3 == 0 } {
			set custkey [ expr {$custkey + $delta} ]
			if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
			set custkey $min
			set delta [ expr {$delta * -1} ]
		}
		if { ![ array exists ascdate ] } {
			for { set d 1 } { $d <= 2557 } {incr d} {
				set ascdate($d) [ mk_time $d ]
			}
		}
		set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
		set date $ascdate([ expr {$tmp_date - 92001} ])
		set opriority [ refresh_pick_str [ get_dists o_oprio ] o_oprio ] 
		set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
		set clerk [ concat Clerk#[format %1.9d $clk_num]]
		set comment [ TEXT 49 ]
		set spriority 0
		set totalprice 0
		set orderstatus "O"
		set ocnt 0
		set lcnt [ RandomNumber 1 7 ]
		if { $ocnt > 0} { set orderstatus "P" }
		if { $ocnt == $lcnt } { set orderstatus "F" }
		Run_refresh1_sql1 $rdbms $hodbc $dbhandle $dbcur1 $date $okey \
		                  $custkey $opriority $spriority $clerk $orderstatus \
				          $totalprice $comment
#Lineitem Loop
		for { set l 0 } { $l < $lcnt } {incr l} {
			set lokey $okey
			set llcnt [ expr {$l + 1} ]
			set lquantity [ RandomNumber 1 50 ]
			set ldiscount [ RandomNumber 0 10 ] 
			set ltax [ RandomNumber 0 8 ] 
			set linstruct [ refresh_pick_str [ get_dists instruct ] instruct ] 
			set lsmode [ refresh_pick_str [ get_dists smode ] smode ] 
			set lcomment [ TEXT 27 ]
			set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
			set rprice [ rpb_routine $lpartkey ]
			set supp_num [ RandomNumber 0 3 ]
			set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
			set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
			set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
			set s_date [ RandomNumber 1 121 ]
			set s_date [ expr {$s_date + $tmp_date} ] 
			set c_date [ RandomNumber 30 90 ]
			set c_date [ expr {$c_date + $tmp_date} ]
			set r_date [ RandomNumber 1 30 ]
			set r_date [ expr {$r_date + $s_date} ]
			set lsdate $ascdate([ expr {$s_date - 92001} ])
			set lcdate $ascdate([ expr {$c_date - 92001} ])
			set lrdate $ascdate([ expr {$r_date - 92001} ])
			if { [ julian $r_date ] <= 95168 } {
				set lrflag [ refresh_pick_str [ get_dists rflag ] rflag ] 
			} else { 
				set lrflag "N" 
			}
			if { [ julian $s_date ] <= 95168 } {
				incr ocnt
				set lstatus "F"
			} else { 
				set lstatus "O" 
			}
			Run_refresh1_sql2 $rdbms $hodbc $dbhandle $dbcur2 $lsdate $lokey $ldiscount $leprice \
			                  $lsuppkey $lquantity $lrflag $lpartkey $lstatus $ltax $lcdate $lrdate \
							  $lsmode $llcnt $linstruct $lcomment
  		}
		if { ![ expr {$i % 1000} ] } {     
			Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
   		}
	}
	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	set end_time   [clock milliseconds]
	Enter_log_item $log_id "msec" [expr {$end_time - $start_time}] $xlevel
}

proc Do_refresh2 { log_id rdbms sec_name connect hodbc dbhandle database_name scale_factor xlevel} {
global dists weights dist_names dist_weights sql
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
	set upd_num 1
	set dbcur1   "NOT_USED"
	set dbcur2   "NOT_USED"
	set f_connect [Quote_slash $connect]
	set dbcur1 [Set_refresh2_sql $rdbms 1 $connect $dbhandle]
	set dbcur2 [Set_refresh2_sql $rdbms 2 $connect $dbhandle]

	set refresh 100
	set sfrows [ expr {$scale_factor * 1500} ] 
	set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
	set endindex [ expr {$upd_num * $sfrows} ]

	set start_time [clock milliseconds]
	for { set i $startindex } { $i <= $endindex } { incr i } {
		set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
		Run_refresh2_sql2 $rdbms $hodbc $dbhandle $dbcur2 $okey

		Run_refresh2_sql1 $rdbms $hodbc $dbhandle $dbcur1 $okey
		if { ![ expr {$i % 1000} ] } {     
			Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
   		}
	}
	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel
	set end_time   [clock milliseconds]
	Enter_log_item $log_id "msec" [expr {$end_time - $start_time}] $xlevel]
	Disconnect_from_DB $log_id $rdbms $hodbc $dbhandle $xlevel
	
}

proc Do_power_tpch_queries {log_id rdbms sec_name connect database_name db_scale maxdop log_dir xlevel} {
global dists weights dist_names dist_weights sql

	set xlevel 0
	set f_connect [Quote_slash $connect]
	set tlog_id [Create_thread_log  $log_id $sec_name 1 $log_dir "power_throughput.xml" $xlevel]
	set xlevel 2

	set run_cond  [tsv::set tasks run_cond  [thread::cond create]]
	set run_mutex [tsv::set tasks run_mutex [thread::mutex create]]
	thread::mutex lock $run_mutex

	#
	#Create a new thread that waits for the needed routines
	#
	set t_list(1) [thread::create -joinable {thread::wait}]
	#
	# The load up the source code do this sync so that they happen one after another
	#	
	thread::transfer $t_list(1) $tlog_id
	Load_sources $t_list(1) $rdbms "auto_tpch.tcl"
	#
	# And run the database thread -async so they happen together
	#
	eval [subst {thread::send -async $t_list(1) { 	\
		Run_session $tlog_id $rdbms $sec_name $f_connect $database_name 1 $db_scale $maxdop "no" $xlevel } r_id } ]
	#
	# OK, now send for everybody to start at the same time - because you are using the throughput routines
	#
	tsv::set tasks predicate 1
	thread::cond notify $run_cond
	thread::mutex unlock $run_mutex
	#
	# Wait for everybody (threads) before repeating
	#
	while {[llength [thread::names]] > 1} {
		after 500
	}
	thread::cond destroy  $run_cond
	thread::mutex destroy $run_mutex

}


proc Run_tpch_power {log_id rdbms sec_name connect sysconnect database_name db_scale maxdop log_dir cmd_dir trace_sql}  {
global dists weights dist_names dist_weights sql

	set dbhandle "NOT_USED"
	set dbcur    "NOT_USED" 
	set hodbc    "db_main"

	set plog_name [file join $log_dir "power_log.xml"]
	if [catch {open $plog_name w} plog_id] {
		puts "ERROR: Unable to open/create $plog_name"
		exit
	}
	Put_thread_header $plog_id "power"
	set xlevel 2

	set upd_num 0
	if { ![ array exists dists ] } { set_dists }
	foreach i [ array names dists ] {
		set_dist_list $i
	}
	set db_rows [ expr {$db_scale * 10000} ]
	set f_connect [Quote_slash $connect]
	set f_sysconnect [Quote_slash $sysconnect]
	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	Auto_on_off $rdbms $hodbc $dbhandle "off"

	Enter_log_tag $plog_id "S" "refresh1" 0 xlevel
   	Do_refresh1   $plog_id $rdbms $sec_name $connect $hodbc $dbhandle $database_name $db_scale $xlevel
	Enter_log_tag $plog_id "E" "refresh1" 0 xlevel
	
	Enter_log_tag $plog_id "S" "queries" 0 xlevel
	Do_power_tpch_queries $plog_id $rdbms $sec_name $connect $database_name $db_scale $maxdop $log_dir $xlevel
	Enter_log_tag $plog_id "E" "queries" 0 xlevel
	
	Enter_log_tag $plog_id "S" "refresh2" 0 xlevel
	Do_refresh2   $plog_id $rdbms $sec_name $connect $hodbc $dbhandle $database_name $db_scale $xlevel
	Enter_log_tag $plog_id "E" "refresh2" 0 xlevel

	Put_thread_footer $plog_id "power"
	close $plog_id

}


proc Run_tpch_throughput {log_id rdbms sec_name connect sysconnect database_name threads repeat db_scale maxdop log_dir cmd_dir trace_sql}  {
global dists weights dist_names dist_weights sql
	set upd_num 0
	if { ![ array exists dists ] } { set_dists }
	foreach i [ array names dists ] {
		set_dist_list $i
	}
	set db_rows [ expr {$db_scale * 10000} ]
	# 
	# setup for running in parallel
	#
	#Load_sources $t_list($l_thread) $rdbms "auto_tpch.tcl"
	# Fix the connect string so it can be passed
	set f_connect [Quote_slash $connect]
	set f_sysconnect [Quote_slash $sysconnect]

	#
	# If you are going to repeat it only makes sense for this to happen after each
	# group of queries have ended.
	#
	set xlevel 2
	for {set i 1} { $i <= $repeat } { incr i } {
		#
		# Set mutex so that nobody starts before they are all ready
		#
		set run_cond  [tsv::set tasks run_cond  [thread::cond create]]
		set run_mutex [tsv::set tasks run_mutex [thread::mutex create]]
		thread::mutex lock $run_mutex

		set thread_dir [file join $log_dir [format "throughput_%05d" $i] ]
		file mkdir $thread_dir
		#
		# This is the throughput run 
		#
		for {set l_thread 1} {$l_thread <= $threads } {incr l_thread } {
			set tlog_id [Create_thread_log  $log_id $sec_name $l_thread $thread_dir "tlog_%02d.xml" $xlevel]
			#
			#Create a new thread that waits for the needed routines
			#
			set t_list($l_thread) [thread::create -joinable {thread::wait}]
			#
			# The load up the source code do this sync so that they happen one after another
			#	
			thread::transfer $t_list($l_thread) $tlog_id
			Load_sources $t_list($l_thread) $rdbms "auto_tpch.tcl"
			#
			# And run the database thread -async so they happen together
			#
			set xlevel 2
			eval [subst {thread::send -async $t_list($l_thread) { 	\
				Run_session $tlog_id $rdbms $sec_name $f_connect $database_name $l_thread $db_scale $maxdop $trace_sql $xlevel } r_id } ]
		}
		#
		# OK, now send for everybody to start at the same time
		#
		tsv::set tasks predicate 1
		thread::cond notify $run_cond
		thread::mutex unlock $run_mutex
		#
		# Wait for everybody (threads) before repeating
		#
		while {[llength [thread::names]] > 1} {
			after 500
		}
		thread::cond destroy  $run_cond
		thread::mutex destroy $run_mutex
	}
	return
}

#
# This will be run in the user/session/thread for each one
#
proc Run_session {log_id rdbms sec_name connect database_name my_id db_scale maxdop trace_sql xlevel} {
global sql

	# Setup the basic query for this session/thread
	Set_query $rdbms $maxdop $my_id
	# connect to the database
	set dbhandle "NOT_USED"
	set dbcur    "NOT_USED"
	set hodbc    "db_main"
	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur
	
	Enter_log_item $log_id "maxdop" $maxdop $xlevel
	set my_position [expr { ($my_id % 39) + 1} ]
	set run_order [Ordered_set $my_position]

	set run_mutex [tsv::get tasks run_mutex]
	set run_cond  [tsv::get tasks run_cond]
	thread::mutex lock $run_mutex
	while {![tsv::get tasks predicate]} {
		thread::cond wait $run_cond $run_mutex
	}
	thread::mutex unlock $run_mutex
	set start_total_ms [clock milliseconds ]
	for {set i 0 } {$i < 22} { incr i } {
		set query_id [lindex $run_order $i]
		if {$trace_sql == 1} {Enter_log_item $log_id "sql_stmt" [Sub_query $rdbms $query_id $db_scale $my_id] $xlevel}
		set start_query_ms [clock milliseconds ]
		set this_query [Sub_query $rdbms $maxdop $query_id $db_scale $my_id]
		while {1} {
			 set parts [string first "-- HAMMERORA GO" $this_query]  
			 if {$parts  >= 0 } {
				set part_query [string range $this_query 0 [expr {$parts-1}]]
				set this_query [string range $this_query [expr {$parts + 15}] end ]
				RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $part_query "" 0 0 0
				if {[string length $this_query] > 0 } {
					continue
				} else {
					break
				}
			 } else {
				RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $this_query "" 0 0 0
				break
			}
		}
		set end_query_ms [clock milliseconds ]
		Enter_log_tag  $log_id "S" "query" 0 xlevel
		Enter_log_item $log_id "number" $query_id $xlevel
		Enter_log_item $log_id "msec"   [expr {$end_query_ms - $start_query_ms}] $xlevel
		Enter_log_tag  $log_id "E" "query" 0 xlevel
	}
	set end_total_ms [clock milliseconds ]
	Enter_log_tag  $log_id "S" "session" 0 xlevel
	Enter_log_item $log_id "number" $query_id $xlevel
	Enter_log_item $log_id "msec"   [expr {$end_total_ms - $start_total_ms}] $xlevel
	Enter_log_tag  $log_id "E" "session" 0 xlevel
	Enter_log_tag $log_id "E" $sec_name 1 xlevel
	Enter_log_tag $log_id "E" "autohammer" 1 xlevel
	flush $log_id
	close $log_id
	set r_id [thread::id]
	thread::release
}

# This should be in a common load/run for TPCH
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc Get_query { rdbms maxdop query_no myposition } {
global sql
	if { ![ array exists sql ] } { Set_query $rdbms $maxdop $myposition }
	return $sql($query_no)
}

proc Set_query { rdbms maxdop myposition } {
global sql
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { MSSQL_set_query $maxdop $myposition }
		oracle { Oracle_set_query $myposition }
		pgsql  { puts "Need to make PGSQL_set_query" }
		mysql  { puts "Need to make MySQL_set_query" }
		default { puts "ERROR ERROR - somehow don't have one of the known databases - have ==$sk== instead" }
	}
}

#########################
#TPCH QUERY GENERATION
proc MSSQL_set_query { maxdop myposition } {
global sql
	set sql(1) "select l_returnflag, l_linestatus, sum(cast (l_quantity as bigint)) 
	            as sum_qty, sum(l_extendedprice) 
		    as sum_base_price, sum(l_extendedprice * (1 - l_discount)) 
		    as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) 
		    as sum_charge, avg(cast (l_quantity as bigint))
		    as avg_qty, 
		    avg(l_extendedprice) 
		    as avg_price, avg(l_discount) 
		    as avg_disc, count(*) 
		    as count_order 
		    from lineitem where l_shipdate <= dateadd(dd,-:1,cast('1998-12-01'as datetime)) 
		    group by l_returnflag, l_linestatus 
		    order by l_returnflag, l_linestatus option (maxdop $maxdop)"
	set sql(old1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= dateadd(dd,-:1,cast('1998-12-01'as datetime)) group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus option (maxdop $maxdop)"
	set sql(2) "select top 100 s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey option (maxdop $maxdop)"
	set sql(3) "select top 10 l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < ':2' and l_shipdate > ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate option (maxdop $maxdop)"
	set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= ':1' and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority option (maxdop $maxdop)"
	set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= ':2' and o_orderdate < dateadd(yy,1,cast(':2'as datetime)) group by n_name order by revenue desc option (maxdop $maxdop)"
	set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(yy,1,cast(':1'as datetime)) and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3 option (maxdop $maxdop)"
	set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, datepart(yy,l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between '1995-01-01' and '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year option (maxdop $maxdop)"
	set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from (select datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between '1995-01-01' and '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year option (maxdop $maxdop)"
	set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc option (maxdop $maxdop)"
	set sql(10) "select top 20 c_custkey, 
	                           c_name, 
		                   sum(l_extendedprice * (1 - l_discount)) 
		      as revenue, c_acctbal, 
                             	  n_name, 
                             	  c_address, 
                             	  c_phone, 
                             	  c_comment 
                      from customer, 
                      	   orders, 
                           lineitem, 
                           nation 
                      where c_custkey = o_custkey 
                      and l_orderkey = o_orderkey 
                      and o_orderdate >= ':1' 
                      and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) 
                      and l_returnflag = 'R' 
                      and c_nationkey = n_nationkey 
                      group by c_custkey, 
                               c_name, 
                               c_acctbal, 
                               c_phone, 
                               n_name, 
                               c_address, 
                               c_comment 
                      order by revenue desc"
	set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc option (maxdop $maxdop)"
	set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= ':3' and l_receiptdate < dateadd(mm,1,cast(':3' as datetime)) group by l_shipmode order by l_shipmode option (maxdop $maxdop)"
	set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc option (maxdop $maxdop)"
	set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= ':1' and l_shipdate < dateadd(mm,1,':1') option (maxdop $maxdop)"

	set sql(15) "with revenue(supplier_no, total_revenue) as (select l_suppkey, SUM(l_extendedprice*(1-l_discount))
                     from lineitem
                     where l_shipdate >=cast(':1' as datetime)
                     and l_shipdate < DATEADD(mm,3,cast(':1' as datetime))
                     group by l_suppkey)
                     select s_suppkey, s_name, s_address, s_phone, total_revenue
                     from supplier, revenue
                     where s_suppkey = supplier_no
                     and total_revenue = (select MAX(total_revenue) from revenue )
                     order by s_suppkey option (maxdop $maxdop)"

	set sql(old15) "create view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(mm,3,cast(':1' as datetime)) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey option (maxdop $maxdop); drop view revenue$myposition"
	set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size option (maxdop $maxdop)"
	set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey) option (maxdop $maxdop)"
	set sql(18) "select top 100 c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
	set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') option (maxdop $maxdop)"
	set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= ':2' and l_shipdate < dateadd(yy,1,':2'))) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
	set sql(21) "select top 100 s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name option (maxdop $maxdop)"
	set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substring(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode option (maxdop $maxdop)"
}

proc Oracle_set_query { myposition } {
global sql
	set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= date '1998-12-01' - interval ':1' day (3) group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
	set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey"
	set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate"
	set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
	set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + interval '1' year group by n_name order by revenue desc"
	set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' year and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
	set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
	set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
	set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
	set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc"
	set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
	set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + interval '1' year group by l_shipmode order by l_shipmode"
	set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
	set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' month"
	set sql(new15) "with revenue(supplier_no, total_revenue) as
		     select l_suppkey, SUM(l_extendedprice*(1-l_discount))
                     from lineitem
                     where l_shipdate >=TO_DATE(':1', 'YYYY-MM-DD')
                     and l_shipdate < ADD_MONTHS(TO_DATE(':1', 'YYYY-MM-DD'), 3))
                     group by l_suppkey
                     select s_suppkey, s_name, s_address, s_phone, total_revenue
                     from supplier, revenue
                     where s_suppkey = supplier_no
                     and total_revenue = (select MAX(total_revenue) from revenue )
                     order by s_suppkey"
	set sql(sub15) "create or replace view revenue0
	             (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) 
		     from lineitem where l_shipdate >= to_date( '1996-01-01', 'YYYY-MM-DD') 
		     and l_shipdate < add_months( to_date ('1996-01-01', 'YYYY-MM-DD'), 3) 
		     group by l_suppkey; 
		     select s_suppkey, s_name, s_address, s_phone, total_revenue
		     from supplier, revenue0
		     where s_suppkey = supplier_no 
		     and total_revenue = ( select max(total_revenue) from revenue0) 
		     order by s_suppkey;   
		     drop view revenue0"
	set sql(15) "create or replace view revenue$myposition 
	             (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) 
		     from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') 
		     and l_shipdate < add_months( to_date (':1', 'YYYY-MM-DD'), 3) 
		     group by l_suppkey 
		     -- HAMMERORA GO
		     select s_suppkey, s_name, s_address, s_phone, total_revenue 
		     from supplier, revenue$myposition 
		     where s_suppkey = supplier_no 
		     and total_revenue = ( select max(total_revenue) from revenue$myposition) 
		     order by s_suppkey 
		     -- HAMMERORA GO
		     drop view revenue$myposition"
	set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
	set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
	set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
	set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
	set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + interval '1' year)) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
	set sql(21) "select s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name"
	set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
}

#
# This should be in a common source file for both load and run 
#
#
proc run_pick_str { dists name } {
global weights
	set total 0
	set i 0
	if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
		set max_weight [ calc_weight $dists $name ]
	}
	set ran_weight [ RandomNumber 1 $max_weight ]
	while {$total < $ran_weight} {
		set interim [ lindex [ join [lindex $dists $i ] ] end ]
		set total [ expr {$total + $interim} ]
		incr i
	}
	set pkstr [ lindex [lindex $dists [ expr {$i - 1} ] ] 0 ]
	return $pkstr
}

proc calc_weight { list name } {
global weights
	set total 0
	set n [ expr {[llength $list] - 1} ]
	while {$n >= 0} {
		set interim [ lindex [ join [lindex $list $n] ] end ]
		set total [ expr {$total + $interim} ]
		incr n -1
	}
	set weights($name) $total
	return $total
}

#
# This should be in a common source file for both load and run 
#

proc get_dists { dist_type } {
global dists
	if { ![ array exists dists ] } { set_dists }
	return $dists($dist_type)
}

#
# This should be in a common source file for both load and run 
#

proc set_dists {} { 
global dists
	set dists(category) {{FURNITURE 1} {{STORAGE EQUIP} 1} {TOOLS 1} {{MACHINE TOOLS} 1} {OTHER 1}}

	set dists(p_cntr) {{{SM CASE} 1} {{SM BOX} 1} {{SM BAG} 1} {{SM JAR} 1} {{SM PACK} 1} {{SM PKG} 1} \
		           {{SM CAN} 1} {{SM DRUM} 1} {{LG CASE} 1} {{LG BOX} 1} {{LG BAG} 1} {{LG JAR} 1} \
			   {{LG PACK} 1} {{LG PKG} 1} {{LG CAN} 1} {{LG DRUM} 1} {{MED CASE} 1} {{MED BOX} 1} \
			   {{MED BAG} 1} {{MED JAR} 1} {{MED PACK} 1} {{MED PKG} 1} {{MED CAN} 1} {{MED DRUM} 1} \
			   {{JUMBO CASE} 1} {{JUMBO BOX} 1} {{JUMBO BAG} 1} {{JUMBO JAR} 1} {{JUMBO PACK} 1} \
			   {{JUMBO PKG} 1} {{JUMBO CAN} 1} {{JUMBO DRUM} 1} {{WRAP CASE} 1} {{WRAP BOX} 1} \
			   {{WRAP BAG} 1} {{WRAP JAR} 1} {{WRAP PACK} 1} {{WRAP PKG} 1} {{WRAP CAN} 1} {{WRAP DRUM} 1}}

	set dists(instruct) {{{DELIVER IN PERSON} 1} {{COLLECT COD} 1} {{TAKE BACK RETURN} 1} {NONE 1}}

	set dists(msegmnt) {{AUTOMOBILE 1} {BUILDING 1} {FURNITURE 1} {HOUSEHOLD 1} {MACHINERY 1}}

	set dists(p_names) {{CLEANER 1} {SOAP 1} {DETERGENT 1} {EXTRA 1}}

	set dists(nations) {{ALGERIA 0} {ARGENTINA 1} {BRAZIL 0} {CANADA 0} {EGYPT 3} {ETHIOPIA -4} {FRANCE 3} \
		            {GERMANY 0} {INDIA -1} {INDONESIA 0} {IRAN 2} {IRAQ 0} {JAPAN -2} {JORDAN 2} \
			    {KENYA -4} {MOROCCO 0} {MOZAMBIQUE 0} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} \
			    {VIETNAM -2} {RUSSIA 1} {{UNITED KINGDOM} 0} {{UNITED STATES} -2}}

	set dists(nations2) {{ALGERIA 1} {ARGENTINA 1} {BRAZIL 1} {CANADA 1} {EGYPT 1} {ETHIOPIA 1} {FRANCE 1} \
		             {GERMANY 1} {INDIA 1} {INDONESIA 1} {IRAN 1} {IRAQ 1} {JAPAN 1} {JORDAN 1} {KENYA 1} \
			     {MOROCCO 1} {MOZAMBIQUE 1} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} \
			     {VIETNAM 1} {RUSSIA 1} {{UNITED KINGDOM} 1} {{UNITED STATES} 1}}

	set dists(regions) {{AFRICA 1} {AMERICA 1} {ASIA 1} {EUROPE 1} {{MIDDLE EAST} 1}}

	set dists(o_oprio) {{1-URGENT 1} {2-HIGH 1} {3-MEDIUM 1} {{4-NOT SPECIFIED} 1} {5-LOW 1}}

	set dists(rflag) {{R 1} {A 1}}

	set dists(smode) {{{REG AIR} 1} {AIR 1} {RAIL 1} {TRUCK 1} {MAIL 1} {FOB 1} {SHIP 1}}

	set dists(p_types) {{{STANDARD ANODIZED TIN} 1} {{STANDARD ANODIZED NICKEL} 1} {{STANDARD ANODIZED BRASS} 1} \
		            {{STANDARD ANODIZED STEEL} 1} {{STANDARD ANODIZED COPPER} 1} {{STANDARD BURNISHED TIN} 1} \
			    {{STANDARD BURNISHED NICKEL} 1} {{STANDARD BURNISHED BRASS} 1} {{STANDARD BURNISHED STEEL} 1} \
			    {{STANDARD BURNISHED COPPER} 1} {{STANDARD PLATED TIN} 1} {{STANDARD PLATED NICKEL} 1} \
			    {{STANDARD PLATED BRASS} 1} {{STANDARD PLATED STEEL} 1} {{STANDARD PLATED COPPER} 1} \
			    {{STANDARD POLISHED TIN} 1} {{STANDARD POLISHED NICKEL} 1} {{STANDARD POLISHED BRASS} 1} \
			    {{STANDARD POLISHED STEEL} 1} {{STANDARD POLISHED COPPER} 1} {{STANDARD BRUSHED TIN} 1} \
			    {{STANDARD BRUSHED NICKEL} 1} {{STANDARD BRUSHED BRASS} 1} {{STANDARD BRUSHED STEEL} 1} \
			    {{STANDARD BRUSHED COPPER} 1} {{SMALL ANODIZED TIN} 1} {{SMALL ANODIZED NICKEL} 1} \
			    {{SMALL ANODIZED BRASS} 1} {{SMALL ANODIZED STEEL} 1} {{SMALL ANODIZED COPPER} 1} \
			    {{SMALL BURNISHED TIN} 1} {{SMALL BURNISHED NICKEL} 1} {{SMALL BURNISHED BRASS} 1} \
			    {{SMALL BURNISHED STEEL} 1} {{SMALL BURNISHED COPPER} 1} {{SMALL PLATED TIN} 1} \
			    {{SMALL PLATED NICKEL} 1} {{SMALL PLATED BRASS} 1} {{SMALL PLATED STEEL} 1} {{SMALL PLATED COPPER} 1} \
			    {{SMALL POLISHED TIN} 1} {{SMALL POLISHED NICKEL} 1} {{SMALL POLISHED BRASS} 1} \
			    {{SMALL POLISHED STEEL} 1} {{SMALL POLISHED COPPER} 1} {{SMALL BRUSHED TIN} 1} \
			    {{SMALL BRUSHED NICKEL} 1} {{SMALL BRUSHED BRASS} 1} {{SMALL BRUSHED STEEL} 1} \
			    {{SMALL BRUSHED COPPER} 1} {{MEDIUM ANODIZED TIN} 1} {{MEDIUM ANODIZED NICKEL} 1} \
			    {{MEDIUM ANODIZED BRASS} 1} {{MEDIUM ANODIZED STEEL} 1} {{MEDIUM ANODIZED COPPER} 1} \
			    {{MEDIUM BURNISHED TIN} 1} {{MEDIUM BURNISHED NICKEL} 1} {{MEDIUM BURNISHED BRASS} 1} \
			    {{MEDIUM BURNISHED STEEL} 1} {{MEDIUM BURNISHED COPPER} 1} {{MEDIUM PLATED TIN} 1} \
			    {{MEDIUM PLATED NICKEL} 1} {{MEDIUM PLATED BRASS} 1} {{MEDIUM PLATED STEEL} 1} \
			    {{MEDIUM PLATED COPPER} 1} {{MEDIUM POLISHED TIN} 1} {{MEDIUM POLISHED NICKEL} 1} \
			    {{MEDIUM POLISHED BRASS} 1} {{MEDIUM POLISHED STEEL} 1} {{MEDIUM POLISHED COPPER} 1} \
			    {{MEDIUM BRUSHED TIN} 1} {{MEDIUM BRUSHED NICKEL} 1} {{MEDIUM BRUSHED BRASS} 1} \
			    {{MEDIUM BRUSHED STEEL} 1} {{MEDIUM BRUSHED COPPER} 1} {{LARGE ANODIZED TIN} 1} \
			    {{LARGE ANODIZED NICKEL} 1} {{LARGE ANODIZED BRASS} 1} {{LARGE ANODIZED STEEL} 1} \
			    {{LARGE ANODIZED COPPER} 1} {{LARGE BURNISHED TIN} 1} {{LARGE BURNISHED NICKEL} 1} \
			    {{LARGE BURNISHED BRASS} 1} {{LARGE BURNISHED STEEL} 1} {{LARGE BURNISHED COPPER} 1} \
			    {{LARGE PLATED TIN} 1} {{LARGE PLATED NICKEL} 1} {{LARGE PLATED BRASS} 1} {{LARGE PLATED STEEL} 1} \
			    {{LARGE PLATED COPPER} 1} {{LARGE POLISHED TIN} 1} {{LARGE POLISHED NICKEL} 1} {{LARGE POLISHED BRASS} 1} \
			    {{LARGE POLISHED STEEL} 1} {{LARGE POLISHED COPPER} 1} {{LARGE BRUSHED TIN} 1} {{LARGE BRUSHED NICKEL} 1} \
			    {{LARGE BRUSHED BRASS} 1} {{LARGE BRUSHED STEEL} 1} {{LARGE BRUSHED COPPER} 1} {{ECONOMY ANODIZED TIN} 1} \
			    {{ECONOMY ANODIZED NICKEL} 1} {{ECONOMY ANODIZED BRASS} 1} {{ECONOMY ANODIZED STEEL} 1} \
			    {{ECONOMY ANODIZED COPPER} 1} {{ECONOMY BURNISHED TIN} 1} {{ECONOMY BURNISHED NICKEL} 1} \
			    {{ECONOMY BURNISHED BRASS} 1} {{ECONOMY BURNISHED STEEL} 1} {{ECONOMY BURNISHED COPPER} 1} \
			    {{ECONOMY PLATED TIN} 1} {{ECONOMY PLATED NICKEL} 1} {{ECONOMY PLATED BRASS} 1} {{ECONOMY PLATED STEEL} 1} \
			    {{ECONOMY PLATED COPPER} 1} {{ECONOMY POLISHED TIN} 1} {{ECONOMY POLISHED NICKEL} 1} \
			    {{ECONOMY POLISHED BRASS} 1} {{ECONOMY POLISHED STEEL} 1} {{ECONOMY POLISHED COPPER} 1} \
			    {{ECONOMY BRUSHED TIN} 1} {{ECONOMY BRUSHED NICKEL} 1} {{ECONOMY BRUSHED BRASS} 1} {{ECONOMY BRUSHED STEEL} 1} \
			    {{ECONOMY BRUSHED COPPER} 1} {{PROMO ANODIZED TIN} 1} {{PROMO ANODIZED NICKEL} 1} {{PROMO ANODIZED BRASS} 1} \
			    {{PROMO ANODIZED STEEL} 1} {{PROMO ANODIZED COPPER} 1} {{PROMO BURNISHED TIN} 1} {{PROMO BURNISHED NICKEL} 1} \
			    {{PROMO BURNISHED BRASS} 1} {{PROMO BURNISHED STEEL} 1} {{PROMO BURNISHED COPPER} 1} {{PROMO PLATED TIN} 1} \
			    {{PROMO PLATED NICKEL} 1} {{PROMO PLATED BRASS} 1} {{PROMO PLATED STEEL} 1} {{PROMO PLATED COPPER} 1} \
			    {{PROMO POLISHED TIN} 1} {{PROMO POLISHED NICKEL} 1} {{PROMO POLISHED BRASS} 1} {{PROMO POLISHED STEEL} 1} \
			    {{PROMO POLISHED COPPER} 1} {{PROMO BRUSHED TIN} 1} {{PROMO BRUSHED NICKEL} 1} {{PROMO BRUSHED BRASS} 1} \
			    {{PROMO BRUSHED STEEL} 1} {{PROMO BRUSHED COPPER} 1}}

	set dists(colors) {{almond 1} {antique 1} {aquamarine 1} {azure 1} {beige 1} {bisque 1} {black 1} {blanched 1} {blue 1} {blush 1} \
		           {brown 1} {burlywood 1} {burnished 1} {chartreuse 1} {chiffon 1} {chocolate 1} {coral 1} {cornflower 1} \
			   {cornsilk 1} {cream 1} {cyan 1} {dark 1} {deep 1} {dim 1} {dodger 1} {drab 1} {firebrick 1} {floral 1} {forest 1} \
			   {frosted 1} {gainsboro 1} {ghost 1} {goldenrod 1} {green 1} {grey 1} {honeydew 1} {hot 1} {indian 1} {ivory 1} \
			   {khaki 1} {lace 1} {lavender 1} {lawn 1} {lemon 1} {light 1} {lime 1} {linen 1} {magenta 1} {maroon 1} {medium 1} \
			   {metallic 1} {midnight 1} {mint 1} {misty 1} {moccasin 1} {navajo 1} {navy 1} {olive 1} {orange 1} {orchid 1} \
			   {pale 1} {papaya 1} {peach 1} {peru 1} {pink 1} {plum 1} {powder 1} {puff 1} {purple 1} {red 1} {rose 1} {rosy 1} \
			   {royal 1} {saddle 1} {salmon 1} {sandy 1} {seashell 1} {sienna 1} {sky 1} {slate 1} {smoke 1} {snow 1} {spring 1} \
			   {steel 1} {tan 1} {thistle 1} {tomato 1} {turquoise 1} {violet 1} {wheat 1} {white 1} {yellow 1}}

	set dists(nouns) {{packages 40} {requests 40} {accounts 40} {deposits 40} {foxes 20} {ideas 20} {theodolites 20} {{pinto beans} 20} \
		          {instructions 20} {dependencies 10} {excuses 10} {platelets 10} {asymptotes 10} {courts 5} {dolphins 5} \
			  {multipliers 1} {sauternes 1} {warthogs 1} {frets 1} {dinos 1} {attainments 1} {somas 1} {Tiresias 1} {patterns 1} \
			  {forges 1} {braids 1} {frays 1} {warhorses 1} {dugouts 1} {notornis 1} {epitaphs 1} {pearls 1} {tithes 1} {waters 1} \
			  {orbits 1} {gifts 1} {sheaves 1} {depths 1} {sentiments 1} {decoys 1} {realms 1} {pains 1} {grouches 1} {escapades 1} {{hockey players} 1}}

	set dists(verbs) {{sleep 20} {wake 20} {are 20} {cajole 20} {haggle 20} {nag 10} {use 10} {boost 10} {affix 5} {detect 5} {integrate 5} \
		          {maintain 1} {nod 1} {was 1} {lose 1} {sublate 1} {solve 1} {thrash 1} {promise 1} {engage 1} {hinder 1} {print 1} \
			  {x-ray 1} {breach 1} {eat 1} {grow 1} {impress 1} {mold 1} {poach 1} {serve 1} {run 1} {dazzle 1} {snooze 1} {doze 1} \
			  {unwind 1} {kindle 1} {play 1} {hang 1} {believe 1} {doubt 1}}

	set dists(adverbs) {{sometimes 1} {always 1} {never 1} {furiously 50} {slyly 50} {carefully 50} {blithely 40} {quickly 30} {fluffily 20} \
		            {slowly 1} {quietly 1} {ruthlessly 1} {thinly 1} {closely 1} {doggedly 1} {daringly 1} {bravely 1} {stealthily 1} \
			    {permanently 1} {enticingly 1} {idly 1} {busily 1} {regularly 1} {finally 1} {ironically 1} {evenly 1} {boldly 1} {silently 1}}

	set dists(articles) {{the 50} {a 20} {an 5}}

	set dists(prepositions) {{about 50} {above 50} {{according to} 50} {across 50} {after 50} {against 40} {along 40} {{alongside of} 30} \
		                 {among 30} {around 20} {at 10} {atop 1} {before 1} {behind 1} {beneath 1} {beside 1} {besides 1} {between 1} \
				 {beyond 1} {by 1} {despite 1} {during 1} {except 1} {for 1} {from 1} {{in place of} 1} {inside 1} \
				 {{instead of} 1} {into 1} {near 1} {of 1} {on 1} {outside 1} {over {1 }} {past 1} {since 1} {through 1} \
				 {throughout 1} {to 1} {toward 1} {under 1} {until 1} {up {1 }} {upon 1} {whithout 1} {with 1} {within 1}}

	set dists(auxillaries) {{do 1} {may 1} {might 1} {shall 1} {will 1} {would 1} {can 1} {could 1} {should 1} {{ought to} 1} {must 1} \
		                {{will have to} 1} {{shall have to} 1} {{could have to} 1} {{should have to} 1} {{must have to} 1} {{need to} 1} {{try to} 1}}

	set dists(terminators) {{. 50} {{;} 1} {: 1} {? 1} {! 1} {-- 1}}

	set dists(adjectives) {{special 20} {pending 20} {unusual 20} {express 20} {furious 1} {sly 1} {careful 1} {blithe 1} {quick 1} \
		               {fluffy 1} {slow 1} {quiet 1} {ruthless 1} {thin 1} {close 1} {dogged 1} {daring 1} {brave 1} {stealthy 1} \
			       {permanent 1} {enticing 1} {idle 1} {busy 1} {regular 50} {final 40} {ironic 40} {even 30} {bold 20} {silent 10}}

	set dists(grammar) {{{N V T} 3} {{N V P T} 3} {{N V N T} 3} {{N P V N T} 1} {{N P V P T} 1}}

	set dists(np) {{N 10} {{J N} 20} {{J J N} 10} {{D J N} 50}}

	set dists(vp) {{V 30} {{X V} 1} {{V D} 40} {{X V D} 1}}
	
	set dists(Q13a) {{special 20} {pending 20} {unusual 20} {express 20}}
	
	set dists(Q13b) {{packages 40} {requests 40} {accounts 40} {deposits 40}}
}

proc Ordered_set { myposition } {
	set o_s(0)  { 14 2 9 20 6 17 18 8 21 13 3 22 16 4 11 15 1 10 19 5 7 12 }
	set o_s(1)  { 21 3 18 5 11 7 6 20 17 12 16 15 13 10 2 8 14 19 9 22 1 4 }
	set o_s(2)  { 6 17 14 16 19 10 9 2 15 8 5 22 12 7 13 18 1 4 20 3 11 21 }
	set o_s(3)  { 8 5 4 6 17 7 1 18 22 14 9 10 15 11 20 2 21 19 13 16 12 3 }
	set o_s(4)  { 5 21 14 19 15 17 12 6 4 9 8 16 11 2 10 18 1 13 7 22 3 20 }
	set o_s(5)  { 21 15 4 6 7 16 19 18 14 22 11 13 3 1 2 5 8 20 12 17 10 9 }
	set o_s(6)  { 10 3 15 13 6 8 9 7 4 11 22 18 12 1 5 16 2 14 19 20 17 21 }
	set o_s(7)  { 18 8 20 21 2 4 22 17 1 11 9 19 3 13 5 7 10 16 6 14 15 12 }
	set o_s(8)  { 19 1 15 17 5 8 9 12 14 7 4 3 20 16 6 22 10 13 2 21 18 11 }
	set o_s(9)  { 8 13 2 20 17 3 6 21 18 11 19 10 15 4 22 1 7 12 9 14 5 16 }
	set o_s(10) { 6 15 18 17 12 1 7 2 22 13 21 10 14 9 3 16 20 19 11 4 8 5 }
	set o_s(11) { 15 14 18 17 10 20 16 11 1 8 4 22 5 12 3 9 21 2 13 6 19 7 }
	set o_s(12) { 1 7 16 17 18 22 12 6 8 9 11 4 2 5 20 21 13 10 19 3 14 15 }
	set o_s(13) { 21 17 7 3 1 10 12 22 9 16 6 11 2 4 5 14 8 20 13 18 15 19 }
	set o_s(14) { 2 9 5 4 18 1 20 15 16 17 7 21 13 14 19 8 22 11 10 3 12 6 }
	set o_s(15) { 16 9 17 8 14 11 10 12 6 21 7 3 15 5 22 20 1 13 19 2 4 18 }
	set o_s(16) { 1 3 6 5 2 16 14 22 17 20 4 9 10 11 15 8 12 19 18 13 7 21 }
	set o_s(17) { 3 16 5 11 21 9 2 15 10 18 17 7 8 19 14 13 1 4 22 20 6 12 }
	set o_s(18) { 14 4 13 5 21 11 8 6 3 17 2 20 1 19 10 9 12 18 15 7 22 16 }
	set o_s(19) { 4 12 22 14 5 15 16 2 8 10 17 9 21 7 3 6 13 18 11 20 19 1 }
	set o_s(20) { 16 15 14 13 4 22 18 19 7 1 12 17 5 10 20 3 9 21 11 2 6 8 }
	set o_s(21) { 20 14 21 12 15 17 4 19 13 10 11 1 16 5 18 7 8 22 9 6 3 2 }
	set o_s(22) { 16 14 13 2 21 10 11 4 1 22 18 12 19 5 7 8 6 3 15 20 9 17 }
	set o_s(23) { 18 15 9 14 12 2 8 11 22 21 16 1 6 17 5 10 19 4 20 13 3 7 }
	set o_s(24) { 7 3 10 14 13 21 18 6 20 4 9 8 22 15 2 1 5 12 19 17 11 16 }
	set o_s(25) { 18 1 13 7 16 10 14 2 19 5 21 11 22 15 8 17 20 3 4 12 6 9 }
	set o_s(26) { 13 2 22 5 11 21 20 14 7 10 4 9 19 18 6 3 1 8 15 12 17 16 }
	set o_s(27) { 14 17 21 8 2 9 6 4 5 13 22 7 15 3 1 18 16 11 10 12 20 19 }
	set o_s(28) { 10 22 1 12 13 18 21 20 2 14 16 7 15 3 4 17 5 19 6 8 9 11 }
	set o_s(29) { 10 8 9 18 12 6 1 5 20 11 17 22 16 3 13 2 15 21 14 19 7 4 }
	set o_s(30) { 7 17 22 5 3 10 13 18 9 1 14 15 21 19 16 12 8 6 11 20 4 2 }
	set o_s(31) { 2 9 21 3 4 7 1 11 16 5 20 19 18 8 17 13 10 12 15 6 14 22 }
	set o_s(32) { 15 12 8 4 22 13 16 17 18 3 7 5 6 1 9 11 21 10 14 20 19 2 }
	set o_s(33) { 15 16 2 11 17 7 5 14 20 4 21 3 10 9 12 8 13 6 18 19 22 1 }
	set o_s(34) { 1 13 11 3 4 21 6 14 15 22 18 9 7 5 10 20 12 16 17 8 19 2 }
	set o_s(35) { 14 17 22 20 8 16 5 10 1 13 2 21 12 9 4 18 3 7 6 19 15 11 }
	set o_s(36) { 9 17 7 4 5 13 21 18 11 3 22 1 6 16 20 14 15 10 8 2 12 19 }
	set o_s(37) { 13 14 5 22 19 11 9 6 18 15 8 10 7 4 17 16 3 1 12 2 21 20 }
	set o_s(38) { 20 5 4 14 11 1 6 16 8 22 7 3 2 12 21 19 17 13 10 15 18 9 }
	set o_s(39) { 3 7 14 15 6 5 21 20 18 10 4 16 19 1 13 9 8 17 11 12 22 2 }
	set o_s(40) { 13 15 17 1 22 11 3 4 7 20 14 21 9 8 2 18 16 6 10 12 5 19 }

	return $o_s($myposition)
}

proc Sub_query { rdbms maxdop query_no scale_factor myposition } {
	set P_SIZE_MIN 1
	set P_SIZE_MAX 50
	set MAX_PARAM 10
	set q2sub [Get_query $rdbms $maxdop $query_no $myposition ]
	switch $query_no {
		1 {
			regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  		}
		2 {
			regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
			set qc [ lindex [ split [ run_pick_str [ get_dists p_types ] p_types ] ] 2 ]
			regsub -all {:2} $q2sub $qc q2sub
			set qc [ run_pick_str [ get_dists regions ] regions ]
			regsub -all {:3} $q2sub $qc q2sub
  		}
		3 {
			set qc [ run_pick_str [ get_dists msegmnt ] msegmnt ]
			regsub -all {:1} $q2sub $qc q2sub
			set tmp_date [RandomNumber 1 31]
			if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
			regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  		}
		4 {
			set tmp_date [RandomNumber 1 58]
			set yr [ expr 93 + $tmp_date/12 ]
			set mon [ expr $tmp_date % 12 + 1 ]
			if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
			set tmp_date [ concat 19$yr-$mon-01 ]
			regsub -all {:1} $q2sub $tmp_date q2sub
  		}
		5 {
			set qc [ run_pick_str [ get_dists regions ] regions ]
			regsub -all {:1} $q2sub $qc q2sub
			set tmp_date [RandomNumber 93 97]
			regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  		}
		6 {
			set tmp_date [RandomNumber 93 97]
			regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
			regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
			regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  		}
		7 {
			set qc [ run_pick_str [ get_dists nations2 ] nations2 ]
			regsub -all {:1} $q2sub $qc q2sub
			set qc2 $qc
			while { $qc2 eq $qc } { set qc2 [ run_pick_str [ get_dists nations2 ] nations2 ] }
			regsub -all {:2} $q2sub $qc2 q2sub
  		}
		8 {
			set nationlist [ get_dists nations2 ]
			set regionlist [ get_dists regions ]
			set qc [ run_pick_str $nationlist nations2 ] 
			regsub -all {:1} $q2sub $qc q2sub
			set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
			switch $nind {
				0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
				1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
				8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
				6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
				10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
			}
			regsub -all {:2} $q2sub $qc q2sub
			set qc [ run_pick_str [ get_dists p_types ] p_types ]
			regsub -all {:3} $q2sub $qc q2sub
  		}
		9 {
			set qc [ run_pick_str [ get_dists colors ] colors ]
			regsub -all {:1} $q2sub $qc q2sub
  		}
		10 {
			set tmp_date [RandomNumber 1 24]
			set yr [ expr 93 + $tmp_date/12 ]
			set mon [ expr $tmp_date % 12 + 1 ]
			if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
			set tmp_date [ concat 19$yr-$mon-01 ]
			regsub -all {:1} $q2sub $tmp_date q2sub
   		}
		11 {
			set qc [ run_pick_str [ get_dists nations2 ] nations2 ]
			regsub -all {:1} $q2sub $qc q2sub
			set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
			regsub -all {:2} $q2sub $q11_fract q2sub
		}
		12 {
			set qc [ run_pick_str [ get_dists smode ] smode ]
			regsub -all {:1} $q2sub $qc q2sub
			set qc2 $qc
			while { $qc2 eq $qc } { set qc2 [ run_pick_str [ get_dists smode ] smode ] }
			regsub -all {:2} $q2sub $qc2 q2sub
			set tmp_date [RandomNumber 93 97]
			regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
		}
		13 {
			set qc [ run_pick_str [ get_dists Q13a ] Q13a ]
			regsub -all {:1} $q2sub $qc q2sub
			set qc [ run_pick_str [ get_dists Q13b ] Q13b ]
			regsub -all {:2} $q2sub $qc q2sub
		}
		14 {
			set tmp_date [RandomNumber 1 60]
			set yr [ expr 93 + $tmp_date/12 ]
			set mon [ expr $tmp_date % 12 + 1 ]
			if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
			set tmp_date [ concat 19$yr-$mon-01 ]
			regsub -all {:1} $q2sub $tmp_date q2sub
		}
		15 {
			set tmp_date [RandomNumber 1 58]
			set yr [ expr 93 + $tmp_date/12 ]
			set mon [ expr $tmp_date % 12 + 1 ]
			if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
			set tmp_date [ concat 19$yr-$mon-01 ]
			regsub -all {:1} $q2sub $tmp_date q2sub
		}
		16 {
			set tmp1 [RandomNumber 1 5] 
			set tmp2 [RandomNumber 1 5] 
			regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
			set p_type [ split [ run_pick_str [ get_dists p_types ] p_types ] ]
			set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
			regsub -all {:2} $q2sub $qc q2sub
			set permute [list]
			for {set i 3} {$i <= $MAX_PARAM} {incr i} {
				set tmp3 [RandomNumber 1 50] 
				while { [ lsearch $permute $tmp3 ] != -1  } {
					set tmp3 [RandomNumber 1 50] 
				} 
				lappend permute $tmp3
				set qc $tmp3
				regsub -all ":$i" $q2sub $qc q2sub
			}
   		}
		17 {
			set tmp1 [RandomNumber 1 5] 
			set tmp2 [RandomNumber 1 5] 
			regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
			set qc [ run_pick_str [ get_dists p_cntr ] p_cntr ]
			regsub -all {:2} $q2sub $qc q2sub
 		}
		18 {
			regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
		}
		19 {
			set tmp1 [RandomNumber 1 5] 
			set tmp2 [RandomNumber 1 5] 
			regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
			set tmp1 [RandomNumber 1 5] 
			set tmp2 [RandomNumber 1 5] 
			regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
			set tmp1 [RandomNumber 1 5] 
			set tmp2 [RandomNumber 1 5] 
			regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
			regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
			regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
			regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
		}
		20 {
			set qc [ run_pick_str [ get_dists colors ] colors ]
			regsub -all {:1} $q2sub $qc q2sub
			set tmp_date [RandomNumber 93 97]
			regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
			set qc [ run_pick_str [ get_dists nations2 ] nations2 ]
			regsub -all {:3} $q2sub $qc q2sub
		}
		21 {
			set qc [ run_pick_str [ get_dists nations2 ] nations2 ]
			regsub -all {:1} $q2sub $qc q2sub
		}
		22 {
			set permute [list]
			for {set i 0} {$i <= 7} {incr i} {
				set tmp3 [RandomNumber 10 34] 
				while { [ lsearch $permute $tmp3 ] != -1  } {
					set tmp3 [RandomNumber 10 34] 
				} 
				lappend permute $tmp3
				set qc $tmp3
				regsub -all ":$i" $q2sub $qc q2sub
			}
    		}
	}
	return $q2sub
}
proc xmk_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
	set sql "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES (TO_DATE(:O_ORDERDATE,'YYYY-MM-DD'), :O_ORDERKEY, :O_CUSTKEY, :O_ORDERPRIORITY, :O_SHIPPRIORITY, :O_CLERK, :O_ORDERSTATUS, :O_TOTALPRICE, :O_COMMENT)"
	set statement {orabind $curn1 :O_ORDERDATE $date :O_ORDERKEY $okey :O_CUSTKEY $custkey :O_ORDERPRIORITY $opriority :O_SHIPPRIORITY $spriority :O_CLERK $clerk :O_ORDERSTATUS $orderstatus :O_TOTALPRICE $totalprice :O_COMMENT $comment}
	set sql2 "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) values (TO_DATE(:L_SHIPDATE,'YYYY-MM-DD'), :L_ORDERKEY, :L_DISCOUNT, :L_EXTENDEDPRICE, :L_SUPPKEY, :L_QUANTITY, :L_RETURNFLAG, :L_PARTKEY, :L_LINESTATUS, :L_TAX, TO_DATE(:L_COMMITDATE,'YYYY-MM-DD'), TO_DATE(:L_RECEIPTDATE,'YYYY-MM-DD'), :L_SHIPMODE, :L_LINENUMBER, :L_SHIPINSTRUCT, :L_COMMENT)"
	set statement2 {orabind $curn2 :L_SHIPDATE $lsdate :L_ORDERKEY $lokey :L_DISCOUNT $ldiscount :L_EXTENDEDPRICE $leprice :L_SUPPKEY $lsuppkey :L_QUANTITY $lquantity :L_RETURNFLAG $lrflag :L_PARTKEY $lpartkey :L_LINESTATUS $lstatus :L_TAX $ltax :L_COMMITDATE $lcdate :L_RECEIPTDATE $lrdate :L_SHIPMODE $lsmode :L_LINENUMBER $llcnt :L_SHIPINSTRUCT $linstruct :L_COMMENT $lcomment }
	set curn1 [oraopen $lda ]
	oraparse $curn1 $sql
	set curn2 [oraopen $lda ]
	oraparse $curn2 $sql2
	set refresh 100
	set delta 1
	set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
	set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
	set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
	set sfrows [ expr {$scale_factor * 1500} ] 
	set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
	set endindex [ expr {$upd_num * $sfrows} ]
	for { set i $startindex } { $i <= $endindex } { incr i } {
		after $trickle_refresh
		if { $upd_num == 0 } {
			set okey [ mk_sparse $i $upd_num ]
		} else {
			set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
		}
		set custkey [ RandomNumber 1 $O_CKEY_MAX ]
		while { $custkey % 3 == 0 } {
			set custkey [ expr {$custkey + $delta} ]
			if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
			set custkey $min
			set delta [ expr {$delta * -1} ]
		}
		if { ![ array exists ascdate ] } {
			for { set d 1 } { $d <= 2557 } {incr d} {
				set ascdate($d) [ mk_time $d ]
			}
		}
		set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
		set date $ascdate([ expr {$tmp_date - 92001} ])
		set opriority [ pick_str [ get_dists o_oprio ] o_oprio ] 
		set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
		set clerk [ concat Clerk#[format %1.9d $clk_num]]
		set comment [ TEXT 49 ]
		set spriority 0
		set totalprice 0
		set orderstatus "O"
		set ocnt 0
		set lcnt [ RandomNumber 1 7 ]
		if { $ocnt > 0} { set orderstatus "P" }
		if { $ocnt == $lcnt } { set orderstatus "F" }
		if { $REFRESH_VERBOSE } {
				puts "Refresh Insert Orderkey $okey..."
		}
		eval $statement
		if {[ catch {oraexec $curn1} message ] } {
				puts "Error in cursor 1:$curn1 $message"
				puts [ oramsg $curn1 all ]
		}
#Lineitem Loop
		for { set l 0 } { $l < $lcnt } {incr l} {
			set lokey $okey
			set llcnt [ expr {$l + 1} ]
			set lquantity [ RandomNumber 1 50 ]
			set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
			set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
			set linstruct [ pick_str [ get_dists instruct ] instruct ] 
			set lsmode [ pick_str [ get_dists smode ] smode ] 
			set lcomment [ TEXT 27 ]
			set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
			set rprice [ rpb_routine $lpartkey ]
			set supp_num [ RandomNumber 0 3 ]
			set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
			set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
			set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
			set s_date [ RandomNumber 1 121 ]
			set s_date [ expr {$s_date + $tmp_date} ] 
			set c_date [ RandomNumber 30 90 ]
			set c_date [ expr {$c_date + $tmp_date} ]
			set r_date [ RandomNumber 1 30 ]
			set r_date [ expr {$r_date + $s_date} ]
			set lsdate $ascdate([ expr {$s_date - 92001} ])
			set lcdate $ascdate([ expr {$c_date - 92001} ])
			set lrdate $ascdate([ expr {$r_date - 92001} ])
			if { [ julian $r_date ] <= 95168 } {
				set lrflag [ pick_str [ get_dists rflag ] rflag ] 
			} else { 
				set lrflag "N" 
			}
			if { [ julian $s_date ] <= 95168 } {
				incr ocnt
				set lstatus "F"
			} else { 
				set lstatus "O" 
			}
			eval $statement2
			if {[ catch {oraexec $curn2} message ] } {
				puts "Error in cursor 2:$curn2 $message"
				puts [ oramsg $curn2 all ]
			}
  		}
		if { ![ expr {$i % 1000} ] } {     
	  		oracommit $lda
        	update
   		}
	}
	oracommit $lda
	oraclose $curn1
	oraclose $curn2
	update
}


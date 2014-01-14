catch {console show}
##
# auto_tpcds_query_sort.tcl -- Post TPC-DS query log parser 
# Produces sorted query list longest running to shortest
#
# Copyright 2012 Timothy D. Witham
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
# 
# Set verbose to 1 for lots of messages 0 for normal operation
source "components/auto_xml.tcl"
dict set values "verbose" 0
dict set values "average" 0.0
dict set values "max_run" 0.0
dict set values "min_run" 0.0
dict set values "query_cnt" 0

set verbose 0
set average 0.0
set max_run 0.0
set min_run 0.0
set runcnt 0
#
# Since this is all one small operation things are set to global
# as it is all one group
#
global queries refresh1 refresh2 max_query_run
#
# Print the csv file
#

proc Not_provided {not_name } {
	puts "\n\nHey, you need to run the $not_name test for these results to be meaningful."
	puts "\tSo go back and run them!"
	puts "\tWork stoppage until management provides required tools."
	exit
}

proc Put_error_exit {} {
		puts "Dude fail!"
		exit
}

#
# main of program
#
set error_exit 0
#
# Parse the arguments
#
if {$argc < 2 | $argc > 3 } { Put_error_exit }
if {$argc == 3} {
	if {[string equal -nocase [lindex $argv 2] "verbose" ] == 1 } {
		set verbose 1
	} else { Put_error_exit }
}

# Otherwise set use the first argv for the results directory 
# and create a csv output file placed into the results directory.
# The results directory must already exist and the output file
# will be replace if it already exists.
#
set log_dir [lindex $argv 0]
set query_file [file join $log_dir [lindex $argv 1]]
set sorted_file [file join $log_dir [format "Sorted_%s" [lindex $argv 1]]]
if [catch {open $sorted_file w 0600} spread_id] {
	puts stderr [format "ERROR: Cannot create output file %s." $sorted_file]
	exit
}
if {$verbose} {puts "Successfully created output file"}
# test dict usage
#
dict for {id info } {
		puts "Values $id:" 
		dict with info {
				puts "\t$values"
		}
}
#

if {[file exists $query_file] == 1 } {
	if {$verbose} {puts "Query File exists \n\t== $query_file"}
	Get_query_xml $query_file $verbose
	Parse_log_xml $verbose
} else {
	Not_provided $query_file
}
set run_dir_cnt 1
set max_threads -1
while {1} {
	set run_dir [file join $log_dir [format "throughput_%05d" $run_dir_cnt]]
	if {[file isdirectory $run_dir] == 0 } break
	if {$verbose} {puts "Directory $run_dir is there!"}
	set run_log_cnt 1
	while {1} {
		set run_log [file join $run_dir [format "tlog_%02d.xml" $run_log_cnt]]
		if {[file exists $run_log] == 0 } break
		if {$verbose} {puts "\tFile $run_log is there!"}
		incr num_threads
		Get_throughput_xml $run_log $verbose
		Parse_log_xml $verbose
		incr run_log_cnt
	}
	if {$max_threads < 0 } {
		set max_threads $run_log_cnt
	} else {
		if {$max_threads != $run_log_cnt } {
			puts "ERROR: For iteration $run_dir_cnt and thread $run_log_cnt."
			puts "       Thread count doesn't match."
			exit
		}
	}
	incr run_dir_cnt
}
if {$max_threads == -1} { Not_provided "throughput" }
if {$verbose} {incr run_dir_cnt -1}
if {$verbose} {incr max_threads -1}
if {$verbose} {puts "Total iterations $run_dir_cnt" }
if {$verbose} {puts "With $max_threads per iteration" }
if {$verbose} {
	for {set i 1} {$i <= 22 } {incr i} {
		puts [format "Sum for query(%2d) is %10d and its average is %10.2f" \
	      	$i $queries($i) [expr {($queries($i) * 1.0) / ( $run_dir_cnt * $max_threads) } ] ]
	}
	puts [format "\nFor the sessions the sum is %10d and the average is %10.2f" \
      		$queries(0) [expr {($queries(0)*1.0) / ( $run_dir_cnt * $max_threads) } ] ]
}
puts ".csv file generated"
exit
	

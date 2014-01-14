#  Copyright Timothy D. Witham 2012
#  Distributed under GPL 2.2
#
# Routines to log storage and processor information
#
# Start of main
#
# usage: utilization.tcl directory ms_interval storage_type
#
#package require platform
#source "components/auto_logs.tcl"
#
# Begin main
#

proc Dump_os { log_loc which_os} {
	switch $which_os {
		"Windows NT" {
					  set msinfo [file join $log_loc "os_info_ms.nfo" ]
					  exec "msinfo32" "/nfo" $msinfo
			  		 }
			 "Linux" {
					  set linuxinfo [file join $log_loc "linux_info.xml" ]
					  set log_id [open $linuxinfo w]
					  Linux_dump $log_id
					  close $log_id
			         }
		default      {
					  set err_flg 1 
				      puts stderr "Don't know this operating system\n"
					  exit
		}
	}

	return
}

proc Linux_dump { log_id } {

set sys_kernel {hostname domainname ostype version osrelease shmmax sysrq msgmax \
		        threads-max max_lock_depth latencytop sched_compat_yield \
				io_delay_type sched_tunable_scaling blk_iopoll sched_latency_ns msgmax}
set procs { cpuinfo uptime }

	set xlevel 0

	puts $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $log_id "S" "linuxconf" 0 xlevel
	Enter_log_tag $log_id "S" "software"  0 xlevel
	Put_proc      $log_id $xlevel "domainname"            "/proc/sys/kernel/domainname"
	Put_proc      $log_id $xlevel "ostype"                "/proc/sys/kernel/ostype"
	Put_proc      $log_id $xlevel "version"               "/proc/sys/kernel/version"
	Put_proc      $log_id $xlevel "osrelease"             "/proc/sys/kernel/osrelease"
	Put_proc      $log_id $xlevel "shmmax"                "/proc/sys/kernel/shmmax"
	Put_proc      $log_id $xlevel "sysrq"                 "/proc/sys/kernel/sysrq"
	Put_proc      $log_id $xlevel "msgmax"                "/proc/sys/kernel/msgmax"
	Put_proc      $log_id $xlevel "threads-max"           "/proc/sys/kernel/threads-max"
	Put_proc      $log_id $xlevel "max_lock_depth"        "/proc/sys/kernel/max_lock_depth"
	Put_proc      $log_id $xlevel "latencytop"            "/proc/sys/kernel/latencytop"
	Put_proc      $log_id $xlevel "sched_compat_yield"    "/proc/sys/kernel/sched_compat_yield"
	Put_proc      $log_id $xlevel "io_delay_type"         "/proc/sys/kernel/io_delay_type"
	Put_proc      $log_id $xlevel "sched_tunable_scaling" "/proc/sys/kernel/sched_tunable_scaling"
	Put_proc      $log_id $xlevel "blk_iopoll"            "/proc/sys/kernel/blk_iopoll"
	Put_proc      $log_id $xlevel "sched_latency_ns"      "/proc/sys/kernel/sched_latency_ns"
	Put_proc      $log_id $xlevel "msgmax"                "/proc/sys/kernel/msgmax"
	Enter_log_tag $log_id "E" "software" 0 xlevel

	Enter_log_tag $log_id "S" "hardware" 0 xlevel
	Put_proc      $log_id $xlevel "uptime"    "/proc/uptime" 
	Put_cpuinfo   $log_id $xlevel
	Put_meminfo   $log_id $xlevel
	Put_devices   $log_id $xlevel
	Enter_log_tag $log_id "E" "hardware"  0 xlevel
	Enter_log_tag $log_id "E" "linuxconf" 0 xlevel

}

proc Put_proc {log_id xlevel sec_name file_in} {
	if [catch {open $file_in r} file_id] {
			puts $log_id "<ERROR>Unable to open file $file_in</ERROR>"
			exit
	}
	Enter_log_item $log_id $sec_name [string trim [read $file_id]] $xlevel 
	close $file_id
}

proc Put_cpuinfo {log_id xlevel} {
	set file_in "/proc/cpuinfo"
	set sec_name "cpuinfo"
	if [catch {open $file_in r} file_id] {
			puts $log_id "<ERROR>Unable to open file $file_in</ERROR>"
			exit
	}
	Enter_log_tag $log_id "S" $sec_name 0 xlevel

	while {1} {
		set line_in [gets $file_id]
		if {[eof $file_id]} {
			close $file_id
			Enter_log_tag $log_id "E" $sec_name 0 xlevel
			return
		}
		set in_line [split $line_in ":"]
		if {[string trim [lindex $in_line 0]] != "processor"} continue
		Enter_log_tag $log_id "S" "processor" 0 xlevel
		Enter_log_item $log_id "cpu_number" [string trim [lindex $in_line 1]] $xlevel
		while {1} {
			set line_in [gets $file_id]
			if {[eof $file_id]} {
				close $file_id
				Enter_log_item $log_id "ERROR" "Broken /proc/cpuinfo" $xlevel
				exit
			}
			set in_line [split $line_in ":"]
			set in_tag [string trim [lindex $in_line 0]]
			set in_tag [string map {{ } _} $in_tag]
			set in_tag [string map {{(} _} $in_tag]
			set in_tag [string map {{)} _} $in_tag]
			Enter_log_item $log_id $in_tag [string trim [lindex $in_line 1]] $xlevel
			if {[string trim [lindex $in_line 0]] == "power management"} {
					Enter_log_tag $log_id "E" "processor" 0 xlevel
					break
			}
		}

	}
}

proc Put_meminfo {log_id xlevel } {
	set file_in "/proc/meminfo"
	set sec_name "meminfo"
	if [catch {open $file_in r} file_id] {
			puts $log_id "<ERROR>Unable to open file $file_in</ERROR>"
			exit
	}
	Enter_log_tag $log_id "S" $sec_name 0 xlevel
	incr xlevel 
	while {1} {
		set line_in [gets $file_id]
		if {[eof $file_id]} {
			close $file_id
			incr xlevel -1
			Enter_log_tag $log_id "E" $sec_name 0 xlevel
			return
		}
		set in_line [split $line_in ":"]
		set in_tag [string trim [lindex $in_line 0]]
		set in_tag [string map {{ } _} $in_tag]
			set in_tag [string map {{(} _} $in_tag]
			set in_tag [string map {{)} _} $in_tag]
		Enter_log_item $log_id $in_tag [string trim [lindex $in_line 1]] $xlevel
	}
}

proc Put_devices {log_id xlevel } {
	set file_in "/proc/devices"
	set sec_name "devices"
	if [catch {open $file_in r} file_id] {
			puts $log_id "<ERROR>Unable to open file $file_in</ERROR>"
			exit
	}
	Enter_log_tag $log_id "S" $sec_name 0 xlevel
	while {1} {
		set line_in [gets $file_id]
		if {[eof $file_id]} {
			close $file_id
			Enter_log_item $log_id "ERROR" "Broken /proc/devices" $xlevel
			exit
		}
		set in_line [split $line_in ":"]
		if {[string trim [lindex $in_line 0]] == "Character devices"} break
	}
	Enter_log_tag $log_id "S" "character_devices" 0 xlevel
	while {1} {
		set line_in [gets $file_id]
		if {[eof $file_id]} {
			close $file_id
			Enter_log_item $log_id "ERROR" "Broken /proc/devices" $xlevel
			exit
		}
		if {[string length $line_in] == 0 } continue
		set in_line [split $line_in ":"]
		if {[string trim [lindex $in_line 0]] == "Block devices"} break
		set in_line [split [string trim $line_in] " "]
		set in_tag [string trim [lindex $in_line 1]]
		set in_tag [string map {{ } _} $in_tag]
		set in_tag [string map {/ _} $in_tag]
		Enter_log_item $log_id $in_tag [string trim [lindex $in_line 0]] $xlevel

	}
	Enter_log_tag $log_id "E" "character_devices" 0 xlevel
	Enter_log_tag $log_id "S" "block_devices"     0 xlevel
	while {1} {
		set line_in [gets $file_id]
		if {[eof $file_id]} {
			close $file_id
			break
		}
		if {[string length $line_in] == 0 } continue
		set in_line [split $line_in " "]
		set in_line [split [string trim $line_in] " "]
		set in_tag [string trim [lindex $in_line 1]]
		set in_tag [string map {{ } _} $in_tag]
		set in_tag [string map {/ _} $in_tag]
		Enter_log_item $log_id $in_tag [string trim [lindex $in_line 0]] $xlevel

	}
	Enter_log_tag $log_id "E" "block_devices" 0 xlevel
	Enter_log_tag $log_id "E" $sec_name       0 xlevel
}

set err_flg 0
set log_loc ""
set db_ops 0
	switch $argc {
		1 { set log_loc "." 
			set log_int [lindex $argv 1]
			set type_store "system"
        }
		2 { set log_loc   [lindex $argv 0] 
			set log_int [lindex $argv 1]
			set type_store "system"
        }
		3 { set log_loc   [lindex $argv 0] 
			set log_int [lindex $argv 1]
			set type_store [lindex $argv 2]
        }
	  	default { set err_flg 1
	    	    	puts stderr "Wrong number of arguments\n"
        }
	  }

	if {$err_flg == 1 } {
		puts stderr "ERROR: Invalid usage"
		puts stderr "\tsys_info.tcl <optional output directory>"
		puts stderr "\t Currently supported OS:"
       	puts stderr "\t\t Linux & Microsoft Windows"
       	puts stderr "\t Currently supported storage"
		puts stderr "\t\tLinux:"
		puts stderr "\t\t\tX-IO ISC"
		puts stderr "\t\t\tStandard storage"
		puts stderr "\t\tMicrosoft Windows:"
		puts stderr "\t\t\tX-IO ISC"
		exit
	}

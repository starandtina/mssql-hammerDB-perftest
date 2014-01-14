# These procedures have been copied from the OpenACS 4.x project
# (http://openacs.org). 
#
# They are subject to the GNU General Public License (v2).

# The main purpose of this code is to provide the ad_proc facility
# with its management of args and a way to allow for inline
# documentation, and some code from the OpenACS api-browser for
# producing formatted output of that documentation.

# It was changed in the regard that the inline documentation is not
# stored in an nsv array anymore but a global array variable called
# api_proc_doc. The key for that array is the name of the procedure,
# and each array element contains a list that is of the same structure
# as in the original ad_proc.

# Note that the global array with the documentation strings is built
# up upon every startup, which might be considered a waste of
# memory. If you want to implement a workaround for this, or prove
# that it is not that bad, you are welcome.


# -------------------------------------------------------------------------
# from OpenACS packages/acs-bootstrap-installer/tcl/00-proc-procs.tcl


package provide tclwebtest 1.0


namespace eval ::tclwebtest { }



proc ::tclwebtest::number_p { str } {
    return [regexp {^[-+]?[0-9]*(.[0-9]+)?$} $str]
}

proc ::tclwebtest::empty_string_p { query_string } {
    return [string equal $query_string ""]
}

proc ::tclwebtest::ad_parse_documentation_string { doc_string elements_var } {
    upvar $elements_var elements
    if { [info exists elements] } {
        unset elements
    }

    set lines [split $doc_string "\n\r"]

    array set elements [list]
    set current_element main
    set buffer ""

    foreach line $lines {
	
	# lars@pinds.com, 8 July, 2000
	# We don't do a string trim anymore, because it breaks the formatting of 
	# code examples in the documentation, something that we want to encourage.
        
	# set line [string trim $line]

        if { [regexp {^[ \t]*@([-a-zA-Z_]+)(.*)$} $line "" element remainder] } {
            lappend elements($current_element) [string trim $buffer]

            set current_element $element
            set buffer "$remainder\n"
        } else {
            append buffer $line "\n"
        }
    }

    lappend elements($current_element) [string trim $buffer]
}


proc ::tclwebtest::ad_proc_valid_switch_p {str} {
    return [expr [string equal "-" [string index $str 0]] && ![number_p $str]]
}

proc ::tclwebtest::ad_proc args {
    set public_p 0
    set private_p 0
    set deprecated_p 0
    set warn_p 0
    set debug_p 0

    # Loop through args, stopping at the first argument which is
    # not a switch.
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]

        # If the argument doesn't begin with a hyphen, break.
        if { ![ad_proc_valid_switch_p $arg] } {
            break
        }

        # If the argument is "--", stop parsing for switches (but
        # bump up $i to the next argument, which is the first
        # argument which is not a switch).
        if { [string equal $arg "--"] } {
            incr i
            break
        }

        switch -- $arg {
            -public { set public_p 1 }
            -private { set private_p 1 }
            -deprecated { set deprecated_p 1 }
            -warn { set warn_p 1 }
            -debug { set debug_p 1 }
            default {
                return -code error "Invalid switch [lindex $args $i] passed to ad_proc"
            }
        }
    }

    if { $public_p && $private_p } {
        return -code error "Mutually exclusive switches -public and -private passed to ad_proc"
    }

    if { $warn_p && !$deprecated_p } {
        return -code error "Switch -warn can be provided to ad_proc only if -deprecated is also provided"
    }

    # Now $i is set to the index of the first non-switch argument.
    # There must be either three or four arguments remaining.
    set n_args_remaining [expr { [llength $args] - $i }]
    if { $n_args_remaining != 3 && $n_args_remaining != 4 } {
        return -code error "Wrong number of arguments passed to ad_proc"
    }

    # Set up the remaining arguments.
    set proc_name [lindex $args $i]

    # (SDW - OpenACS). If proc_name is being defined inside a namespace, we
    # want to use the fully qualified name. Except for actually defining the
    # proc where we want to use the name as passed to us. We always set
    # proc_name_as_passed and conditionally make proc_name fully qualified
    # if we were called from inside a namespace eval.

    set proc_name_as_passed $proc_name
    set proc_namespace [uplevel {::namespace current}]
    if { $proc_namespace != "::" } {
	regsub {^::} $proc_namespace {} proc_namespace
	set proc_name "${proc_namespace}::${proc_name}"
    }

    set arg_list [lindex $args [expr { $i + 1 }]]
    if { $n_args_remaining == 3 } {
        # No doc string provided.
        array set doc_elements [list]
	set doc_elements(main) ""
    } else {
        # Doc string was provided.
        ad_parse_documentation_string [lindex $args end-1] doc_elements
    }
    set code_block [lindex $args end]

    #####
    #
    #  Parse the argument list.
    #
    #####

    set switches [list]
    set positionals [list]
    set seen_positional_with_default_p 0
    set n_positionals_with_defaults 0
    array set default_values [list]
    array set flags [list]
    set varargs_p 0
    set switch_code ""

    # If the first element contains 0 or more than 2 elements, then it must
    # be an old-style ad_proc. Mangle effective_arg_list accordingly.
    if { [llength $arg_list] > 0 } {
        set first_arg [lindex $arg_list 0]
        if { [llength $first_arg] == 0 || [llength $first_arg] > 2 } {
            set new_arg_list [list]
            foreach { switch default_value } $first_arg {
                lappend new_arg_list [list $switch $default_value]
            }
            set arg_list [concat $new_arg_list [lrange $arg_list 1 end]]
        }
    }

    set effective_arg_list $arg_list

    set last_arg [lindex $effective_arg_list end]
    if { [llength $last_arg] == 1 && [string equal [lindex $last_arg 0] "args"] } {
        set varargs_p 1
        set effective_arg_list [lrange $effective_arg_list 0 [expr { [llength $effective_arg_list] - 2 }]]
    }

    set check_code ""
    foreach arg $effective_arg_list {
        if { [llength $arg] == 2 } {
            set default_p 1
            set default_value [lindex $arg 1]
            set arg [lindex $arg 0]
        } else {
            if { [llength $arg] != 1 } {
                return -code error "Invalid element \"$arg\" in argument list"
            }
            set default_p 0
        }

        set arg_flags [list]
        set arg_split [split $arg ":"]
        if { [llength $arg_split] == 2 } {
            set arg [lindex $arg_split 0]
            foreach flag [split [lindex $arg_split 1] ","] {
                if { ![string equal $flag "required"] && ![string equal $flag "boolean"] } {
                    return -code error "Invalid flag \"$flag\""
                }
                lappend arg_flags $flag
            }
        } elseif { [llength $arg_split] != 1 } {
            return -code error "Invalid element \"$arg\" in argument list"
        }

        if { [string equal [string index $arg 0] "-"] } {
            if { [llength $positionals] > 0 } {
                return -code error "Switch -$arg specified after positional parameter"
            }

            set switch_p 1
            set arg [string range $arg 1 end]
            lappend switches $arg

            if { [lsearch $arg_flags "boolean"] >= 0 } {
                set default_values(${arg}_p) 0
		append switch_code "            -$arg - -$arg=1 {
                ::uplevel ::set ${arg}_p 1
            }
            -$arg=0 {
                ::uplevel ::set ${arg}_p 0
            }
"
            } else {
		append switch_code "            -$arg {
                if { \$i >= \[llength \$args\] - 1 } {
                    ::return -code error \"No argument to switch -$arg\"
                }
                ::upvar ${arg} val ; ::set val \[::lindex \$args \[::incr i\]\]\n"
		append switch_code "            }\n"
            }

            if { [lsearch $arg_flags "required"] >= 0 } {
                append check_code "    ::if { !\[::uplevel ::info exists $arg\] } {
        ::return -code error \"Required switch -$arg not provided\"
    }
"
            }
        } else {
            set switch_p 0
            if { $default_p } {
                incr n_positionals_with_defaults
            }
            if { !$default_p && $n_positionals_with_defaults != 0 } {
                return -code error "Positional parameter $arg needs a default value (since it follows another positional parameter with a default value)"
            }
            lappend positionals $arg
        }

        set flags($arg) $arg_flags

        if { $default_p } {
            set default_values($arg) $default_value
        }

        if { [llength $arg_split] > 2 } {
            return -code error "Invalid format for parameter name: \"$arg\""
        }
    }

    foreach element { public_p private_p deprecated_p warn_p varargs_p arg_list switches positionals } {
        set doc_elements($element) [set $element]
    }
    foreach element { default_values flags } {
        set doc_elements($element) [array get $element]
    }
    
    set doc_elements(script) [info script]

    global api_proc_doc
    set api_proc_doc($proc_name) [array get doc_elements]

    

    if { [string equal $code_block "-"] } {
        return
    }

    if { [llength $switches] == 0 } {
        uplevel [::list proc $proc_name_as_passed $arg_list $code_block]
    } else {
        set parser_code "    ::upvar args args\n"

        foreach { name value } [array get default_values] {
            append parser_code "    ::upvar $name val ; ::set val [::list $value]\n"
        }
        
        append parser_code "
    ::for { ::set i 0 } { \$i < \[::llength \$args\] } { ::incr i } {
        ::set arg \[::lindex \$args \$i\]
        ::if { !\[::tclwebtest::ad_proc_valid_switch_p \$arg\] } {
            ::break
        }
        ::if { \[::string equal \$arg \"--\"\] } {
            ::incr i
            ::break
        }
        ::switch -- \$arg {
$switch_code
            default { ::return -code error \"Invalid switch: \\\"\$arg\\\"\" }
        }
    }
"

        set n_required_positionals [expr { [llength $positionals] - $n_positionals_with_defaults }]
        append parser_code "
    ::set n_args_remaining \[::expr { \[::llength \$args\] - \$i }\]
    ::if { \$n_args_remaining < $n_required_positionals } {
        ::return -code error \"No value specified for argument \[::lindex { [::lrange $positionals 0 [::expr { $n_required_positionals - 1 }]] } \$n_args_remaining\]\"
    }
"
        for { set i 0 } { $i < $n_required_positionals } { incr i } {
            append parser_code "    ::upvar [::lindex $positionals $i] val ; ::set val \[::lindex \$args \[::expr { \$i + $i }\]\]\n"
        }
        for {} { $i < [llength $positionals] } { incr i } {
            append parser_code "    ::if { \$n_args_remaining > $i } {
        ::upvar [::lindex $positionals $i] val ; ::set val \[::lindex \$args \[::expr { \$i + $i }\]\]
    }
"
        }
        
        if { $varargs_p } {
            append parser_code "    ::set args \[::lrange \$args \[::expr { \$i + [::llength $positionals] }\] end\]\n"
        } else {
            append parser_code "    ::if { \$n_args_remaining > [::llength $positionals] } {
        return -code error \"Too many positional parameters specified\"
    }
    ::unset args
"
        }

        append parser_code $check_code

        if { $debug_p } {
            ns_write "PARSER CODE:\n\n$parser_code\n\n"
        }

        uplevel [::list proc ${proc_name_as_passed}__arg_parser {} $parser_code]
        uplevel [::list proc $proc_name_as_passed args "    ${proc_name_as_passed}__arg_parser\n$code_block"]
    }
}







# -------------------------------------------------------------------------
# from OpenACS packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl


::tclwebtest::ad_proc -private ::tclwebtest::api_proc_documentation {
    { -format text/html }
    -script:boolean
    -source:boolean
    proc_name
} {

    Generates formatted documentation for a procedure.

    @param format the type of documentation to generate. Currently, only
    <code>text/html</code> and <code>text/plain</code> are supported.
    @param script include information about what script this proc lives in?
    @param source include the source code for the script?
    @param proc_name the name of the procedure for which to generate documentation.
    @return the formatted documentation string.
    @error if the procedure is not defined.	   

} {
    
    if { ![string equal $format "text/html"] && \
             ![string equal $format "text/plain"] } {
        return -code error "Only text/html and text/plain documentation are currently supported"
    }
    global api_proc_doc
    array set doc_elements $api_proc_doc($proc_name)
    array set flags $doc_elements(flags)
    array set default_values $doc_elements(default_values)
    
    if { $script_p } {
        append out "<h3>[api_proc_pretty_name $proc_name]</h3>"
    } else {
        append out "<h3>[api_proc_pretty_name -link $proc_name]</h3>"
    }
    
    lappend command_line $proc_name
    foreach switch $doc_elements(switches) {
        if { [lsearch $flags($switch) "boolean"] >= 0 } {
            lappend command_line "\[ -$switch \]"
        } elseif { [lsearch $flags($switch) "required"] >= 0 } {
            lappend command_line "-$switch <i>$switch</i>"
        } else {
            lappend command_line "\[ -$switch <i>$switch</i> \]"
        }
    }
    
    set counter 0
    foreach positional $doc_elements(positionals) {
        if { [info exists default_values($positional)] } {
            lappend command_line "\[ <i>$positional</i> \]"
        } else {
            lappend command_line "<i>$positional</i>"
        }
    }
    if { $doc_elements(varargs_p) } {
        lappend command_line "\[ <i>args</i>... \]"
    }
    append out "[util_wrap_list $command_line]\n<blockquote>\n"
    
    if { $script_p } {
        append out "Defined in <a href=\"/api-doc/procs-file-view?path=[ns_urlencode $doc_elements(script)]\">$doc_elements(script)</a><p>"
    }
    
    if { $doc_elements(deprecated_p) } {
        append out "<b><i>Deprecated."
        if { $doc_elements(warn_p) } {
            append out " Invoking this procedure generates a warning."
        }
        append out "</i></b><p>\n"
    }

    append out "[lindex $doc_elements(main) 0]
	
<p>
<dl>
"

    if { [info exists doc_elements(param)] } {
        foreach param $doc_elements(param) {
            if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
                set params($name) $value
            }
        }
    }
    
    if { [llength $doc_elements(switches)] > 0 } {
        append out "<dt><b>Switches:</b></dt><dd>\n"
        foreach switch $doc_elements(switches) {
            append out "<b>-$switch</b>"
            if { [lsearch $flags($switch) "boolean"] >= 0 } {
                append out " (boolean)"
            } 
            
            if { [info exists default_values($switch)] && \
                     ![::tclwebtest::empty_string_p $default_values($switch)] } {
                append out " (defaults to <code>\"$default_values($switch)\"</code>)"
            } 
            
            if { [lsearch $flags($switch) "required"] >= 0 } {
                append out " (required)"
            } else {
                append out " (optional)"
            }
            
            if { [info exists params($switch)] } {
                append out " - $params($switch)"
            }
            append out "<br>\n"
        }
        append out "</dd>\n"
    }
    
    if { [llength $doc_elements(positionals)] > 0 } {
        append out "<dt><b>Parameters:</b></dt><dd>\n"
        foreach positional $doc_elements(positionals) {
            append out "<b>$positional</b>"
            if { [info exists default_values($positional)] } {
                if { [::tclwebtest::empty_string_p $default_values($positional)] } {
                    append out " (optional)"
                } else {
                    append out " (defaults to <code>\"$default_values($positional)\"</code>)"
                }
            }
            if { [info exists params($positional)] } {
                append out " - $params($positional)"
            }
            append out "<br>\n"
        }
        append out "</dd>\n"
    }
    

    # @option is used in  template:: and cms:: (and maybe should be used in some other 
    # things like ad_form which have internal arg parsers.  although an option 
    # and a switch are the same thing, just one is parsed in the proc itself rather than 
    # by ad_proc.

    if { [info exists doc_elements(option)] } {
        append out "<b>Options:</b><dl>"
        foreach param $doc_elements(option) {
            if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
                append out "<dt><b>-$name</b></dt><dd>$value<br/></dd>"
            }
        }
        append out "</dl>"
    }
    

    if { [info exists doc_elements(return)] } {
        append out "<dt><b>Returns:</b></dt><dd>[join $doc_elements(return) "<br>"]</dd>\n"
    }
    
    if { [info exists doc_elements(error)] } {
        append out "<dt><b>Error:</b></dt><dd>[join $doc_elements(error) "<br>"]</dd>\n"
    }
    
    append out [api_format_common_elements doc_elements]
    
    if { $source_p } {
        append out "<dt><b>Source code:</b></dt><dd>
<pre>[ns_quotehtml [info body $proc_name]]<pre>
</dd><p>\n"
	}
	
	# No "see also" yet.
	
	append out "</dl></blockquote>"
	
	return $out
}



::tclwebtest::ad_proc ::tclwebtest::api_proc_pretty_name { 
    -link:boolean
    proc 
} {
    Return a pretty version of a proc name

    
} {
    if { $link_p } {
        # simplified -til
	append out "$proc"
    } else {	
	append out "$proc"
    }
    global api_proc_doc
    array set doc_elements $api_proc_doc($proc)
    if { $doc_elements(public_p) } {
	append out " (public)"
    }
    if { $doc_elements(private_p) } {
	append out " (private)"
    }
    return $out
}


::tclwebtest::ad_proc -private ::tclwebtest::util_wrap_list {
    { -eol " \\" }
    { -indent 4 }
    { -length 70 }
    items
} {

    Wraps text to a particular line length.

    @param eol the string to be used at the end of each line.
    @param indent the number of spaces to use to indent all lines after the
    first.
    @param length the maximum line length.
    @param items the list of items to be wrapped. Items are
    HTML-formatted. An individual item will never be wrapped onto separate
    lines.

} {
    set out "<pre>"
    set line_length 0
    foreach item $items {
	regsub -all {<[^>]+>} $item "" item_notags
	if { $line_length > $indent } {
	    if { $line_length + 1 + [string length $item_notags] > $length } {
		append out "$eol\n"
		for { set i 0 } { $i < $indent } { incr i } {
		    append out " "
		}
		set line_length $indent
	    } else {
		append out " "
		incr line_length
	    }
	}
	append out $item
	incr line_length [string length $item_notags]
    }
    append out "</pre>"
    return $out
}

::tclwebtest::ad_proc -private ::tclwebtest::api_format_common_elements { doc_elements_var } {
    upvar $doc_elements_var doc_elements

    set out ""

    if { [info exists doc_elements(author)] } {
        # TODO import the api_format_common_elements function
	#append out [::tclwebtest::api_format_author_list $doc_elements(author)]
    }
    if { [info exists doc_elements(creation-date)] } {
	append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]\n"
    }
    if { [info exists doc_elements(change-log)] } {
	append out [api_format_changelog_list $doc_elements(change-log)]
    }
    if { [info exists doc_elements(cvs-id)] } {
	append out "<dt><b>CVS ID:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code>\n"
    }
    if { [info exists doc_elements(see)] } {
	append out [api_format_see_list $doc_elements(see)]
    }

    return $out
}



::tclwebtest::ad_proc -private ::tclwebtest::api_script_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a content page. Sources the file
    to obtain the comment or contract at the beginning.

    @param format the type of documentation to generate. Currently, only
    <code>text/html</code> is supported.
    @param path the path of the Tcl file to examine, relative to the
    OpenACS root directory.
    @return the formatted documentation string.
    @error if the file does not exist.

} {
    append out "<h3>[file tail $path]</h3>\n"

    if { ![string equal [file extension $path] ".tcl"] } {
	append out "<blockquote><i>Delivered as [ns_guesstype $path]</i></blockquote>\n"
	return $out
    }

    if { [catch { array set doc_elements [api_read_script_documentation $path] } error] } {
	append out "<blockquote><i>Unable to read $path: [ns_quotehtml $error]</i></blockquote>\n"
	return $out
    }

    array set params [list]

    if { [info exists doc_elements(param)] } {
	foreach param $doc_elements(param) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
		set params($name) $value
	    }
	}
    }
    
    append out "<blockquote>"
    if { [info exists doc_elements(main)] } {
	append out [lindex $doc_elements(main) 0]
    } else {
	append out "<i>Does not contain a contract.</i>"
    }
    append out "<dl>\n"
    # XXX: This does not work at the moment. -bmq
    #     if { [array size doc_elements] > 0 } {
    #         array set as_flags $doc_elements(as_flags)
    # 	array set as_filters $doc_elements(as_filters)
    #         array set as_default_value $doc_elements(as_default_value)

    #         if { [llength $doc_elements(as_arg_names)] > 0 } {
    # 	    append out "<dt><b>Query Parameters:</b><dd>\n"
    # 	    foreach arg_name $doc_elements(as_arg_names) {
    # 		append out "<b>$arg_name</b>"
    # 		set notes [list]
    # 		if { [info exists as_default_value($arg_name)] } {
    # 		    lappend notes "defaults to <code>\"$as_default_value($arg_name)\"</code>"
    # 		} 
    #  		set notes [concat $notes $as_flags($arg_name)]
    # 		foreach filter $as_filters($arg_name) {
    # 		    set filter_proc [ad_page_contract_filter_proc $filter]
    # 		    lappend notes "<a href=\"[api_proc_url $filter_proc]\">$filter</a>"
    # 		}
    # 		if { [llength $notes] > 0 } {
    # 		    append out " ([join $notes ", "])"
    # 		}
    # 		if { [info exists params($arg_name)] } {
    # 		    append out " - $params($arg_name)"
    # 		}
    # 		append out "<br>\n"
    # 	    }
    # 	    append out "</dd>\n"
    # 	}
    # 	if { [info exists doc_elements(type)] && ![empty_string_p $doc_elements(type)] } {
    # 	    append out "<dt><b>Returns Type:</b><dd><a href=\"type-view?type=$doc_elements(type)\">$doc_elements(type)</a>\n"
    # 	}
    # 	# XXX: Need to support "Returns Properties:"
    #     }
    append out "<dt><b>Location:</b><dd>$path\n"
    append out [api_format_common_elements doc_elements]

    append out "</dl></blockquote>"

    return $out
}


::tclwebtest::ad_proc -private ::tclwebtest::api_format_see_list { sees } { 
    Generate an HTML list of referenced procs and pages.
} { 
    append out "<br /><strong>See Also:</strong>\n<ul>"
    foreach see $sees { 
	append out "<li>[api_format_see $see]\n"
    }
    append out "</ul>\n"
    
    return $out
}

::tclwebtest::ad_proc -private ::tclwebtest::api_format_see { see } {
    regsub -all {proc *} $see {} see
    set see [string trim $see]

    # just don't return a link for now
    #if {[nsv_exists api_proc_doc $see]} { 
    #    return "<a href=\"proc-view?proc=[ns_urlencode ${see}]\">$see</a>"
    #} else { 
    return $see
    #}
}

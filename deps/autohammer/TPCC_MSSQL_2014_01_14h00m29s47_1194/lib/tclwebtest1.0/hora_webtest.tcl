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
# note: if you change the version here change it in the other .tcl
# files as well
package provide tclwebtest 1.0
package require http

# this version contains the speedup fixes of gustaf neumann (up to more than 60 times faster)
# - much more efficient caption code
# - let tcl compile expressions, ifs, etc...

namespace eval ::tclwebtest:: { 
    namespace export do_request reset_session debug response cookies assert assertion_failed link form field translate_entities known_bug
}

# try to import the base64 package, fake it if we can't
if {![catch {package require base64}]} {
    set ::tclwebtest::base64_encode ::base64::encode
} else {
    set ::tclwebtest::base64_encode ::tclwebtest::fake_base64_encode
}

# set static variables
namespace eval ::tclwebtest:: {

    # do we print debugging msgs that are in this file?
    variable DEBUG_LIB_P 0

    variable VERSION "0.9"

    # shell the html checker tidy be invoked on each result page?
    variable TIDY 0

    # follow dirty redirects by default?
    variable FOLLOWEQUIV 1

    # default identation
    variable LOG_MESSAGE_INDENTATION ""

    # user agent strings
    set user_agent_dict(original) "tclwebtest/$VERSION"
    set user_agent_dict(opera70) "Mozilla/4.0 (compatible; MSIE 6.0; MSIE 5.5; Windows NT 5.1) Opera 7.0 \[en\]"
    set user_agent_dict(netscape70) "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
    set user_agent_dict(elinks04) "ELinks (0.4pre24.CVS; Linux 2.4.19-4GB i686; 145x55)"
    set user_agent_dict(mozilla09) "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.8) Gecko/20020204"

    # initial value
    set user_agent $user_agent_dict(original)
}






::tclwebtest::ad_proc -public ::tclwebtest::init {} {
    
    <p>
    Defines all tclwebtest wide variables that carry state information
    and sets them to a default value. To be used upon initialization and
    to reset the variables. The variables will exist in the ::tclwebtest:: 
    namespace.
    </p>
    
    <p>
    When running tclwebtest normally from a shell don't need to call this 
    explicitely, it will be called during the first call of package require. If
    you are running tclwebtest from within AOLServer however you need to call
    ::tclwebtest::init explicitely in the beginning of your session because the 
    connection thread might have been reused from the previous connection and 
    could contain old variable values.
    </p>
    
} {
    # Important: every variable command here must also set a value,
    # otherwise reset won't work as expected and cause ugly and subtle
    # failures.

    variable url ""
    variable http_status ""
    variable body ""
    variable body_without_comments ""

    # All visible text of this page
    variable text ""

    # A list that contains alternating cookie name and value. Value is
    # a list by itself, containing array key and value pairs. This is
    # different from the format of the other lists, e.g. links
    variable cookies [list]

    # A list of http headers returned by the last http request. Format
    # is suitable to initialize an array with. Same as the 'meta'
    # element from the tcl http command. 
    variable headers [list]

    # A list that contains lists, each with two elements, url_prefix
    # and value. Value is the string which has to be injected 'as-is'
    # in the http request header Authorization. Usually the list will
    # be sorted alphabetically decreasing
    variable http_authentication [list]

    # This is an ugly global hack to avoid polluting do_request's
    # parameters, when it's not empty, it will be injected in the
    # http request and deleted. See do_request's 401 treatement.
    variable http_auth_string ""

    # not implemented yet
    variable framed_p ""
    variable frames_name ""
    variable frames_body ""

    # has the corresponding proc already been called after the current
    # request?
    variable links_extracted_p 0

    # A list of lists. The inner list contains a key/value list
    # prepared for array set; with those keys: full, url, content
    variable links [list]


    # has the corresponding proc already been called after the current
    # request?
    variable forms_extracted_p 0


    # Again a list of lists, where the inner list is an array
    # list. Keys: full, action, method, content, fields. Fields is a
    # list of array lists, that contains those keys: full, name, type,
    # value, caption, choices

    # caption is what appears before the field, e.g. "First name:"

    # choices is a list of possible values when field is of type
    # select, radio or checkbox. For checkbox it will always contain
    # an empty string and the value of the "value" attribute

    variable forms [list]

    # Indices of the current active form and field.
    variable current_form ""
    variable current_field ""
    variable field_modified_p 0
    variable current_link ""
    variable referer_policy 1
    variable forged_referer ""

}


namespace eval ::tclwebtest:: {
    init
}

::tclwebtest::ad_proc -public ::tclwebtest::user_agent_id {
    id
} {

    By default tclwebtest identifies itself as
    "<code>tclwebtest/$VERSION</code>". With this command you can change
    the the agent string. This is useful to test web sites which send
    different HTML depending on the user browser, or you need to fake
    an identity because some webmaster decided to restrict access to
    his page to a subset of the <i>popular</i> browsers. You can find
    a list of common user agent strings at:
    <a href="http://www.pgts.com.au/pgtsj/pgtsj0208c.html">http://www.pgts.com.au/pgtsj/pgtsj0208c.html</a>

    @param id Indicate the user agent you want to set, which should be
    a string. There are a few shortcuts built into tclwebtest, you can
    set <b>id</b> to <code>opera70</code>, <code>msie60</code>,
    <code>netscape70</code>, <code>mozilla09</code> and
    <code>elinks04</code>. Use <code>list</code> to retrieve a pair list
    in the form <code>shortcut, agent string</code> with the currently
    available shortcuts. Use <code>original</code> if you want to set
    back the default tclwebtest string. Example:

    <blockquote><pre>
    log "Showing available builtin user agent strings:"
    array set agents [user_agent_id list]
    foreach id [array names agents] {
        log "  $id: $agents($id)"
    }
    
    log "Let's fool Google"
    do_request -nocomplain http://www.google.com/search?q=linux
    user_agent_id "super mozilla like browser"
    do_request http://www.google.com/search?q=linux
    </pre></blockquote>

} {

    if { $id eq "list" } {
        return [array get ::tclwebtest::user_agent_dict]
    } elseif { [catch { set ::tclwebtest::user_agent $::tclwebtest::user_agent_dict($id) }] } {
        set ::tclwebtest::user_agent $id
    }

    log "User agent string switched to '$::tclwebtest::user_agent'"
    
}

::tclwebtest::ad_proc -deprecated -public ::tclwebtest::reset_session {
} {

    Used to reset the session to a pristine state, as if there had been
    no use of tclwebtest at all. Example:

    <blockquote><pre>
    do_request "file://$TESTHOME/select.html"
    assert { [string length [response text]] &gt; 0 }

    reset_session

    assert { [response text] eq "" }

    debug "l: [string length [response text]]"
    </pre></blockquote>

    <p>
    Deprecated, use ::tclwebtest::init instead.
    </p>

    @see ::tclwebtest::init

} {
    namespace eval ::tclwebtest:: init
}


::tclwebtest::ad_proc -public ::tclwebtest::debug {
    -lib:boolean
    msg
} {

    Emit the message to stdout, even if logging output is redirected to
    a file. Intended to be used when writing tests. Its only advantage
    over using puts is that it does not have to be deleted when writing
    the test is finished.

    However, if the variable <code>::tclwebtest::in_memory</code> exists
    (through the previous execution of <code>test_run</code>), this
    procedure will route it's message  through
    <code>::tclwebtest::log</code>, thus allowing all output to be
    redirected to a memory string.
    
} {

    set output ""
    if { $lib_p } {
        # debugging message from the tclwebtest code itself
        if { [info exists ::tclwebtest::DEBUG_LIB_P] && $::tclwebtest::DEBUG_LIB_P } {
            set output "DEBUG LIB: $msg"
        }
    } else {
        # normal debugging message. TODO implement a -debug switch,
        # currently it's always on
        set output "DEBUG: $msg"
    }

    if { $output ne "" } {
        variable in_memory

        if { [info exists in_memory] && $in_memory != 0} {
            log "$output"
        } else {
            puts "$output"
        }
    }

}


::tclwebtest::ad_proc -public ::tclwebtest::log {
    msg 
} {

    Log msg to log_channel. If the variable
    <code>::tclwebtest::in_memory</code> exists (through the previous
    execution of <code>::tclwebtest::test_run</code>),
    <code>::tclwebtest::log_channel</code> will be treated like a
    string instead of a file object (which defaults to <b>stdout</b>).
    
} {

    variable log_channel
    variable in_memory

    set charmap [list "\n" "\n$::tclwebtest::LOG_MESSAGE_INDENTATION"]
    set msg [string map $charmap $msg]

    if { [info exists in_memory] && $in_memory != 0 } {
        if { $msg ne "" } {
            append log_channel "$::tclwebtest::LOG_MESSAGE_INDENTATION$msg\n"
        }
        return
    }

    if { ![info exists log_channel] || $log_channel eq "" } {
        set log_channel stdout
    }

    puts $log_channel "$::tclwebtest::LOG_MESSAGE_INDENTATION$msg"
    
}

# ---------------------------------------------------------------------------
# Begin of link procs.

# TODO implement current_link similar to work like current_field
# (esp. when no further arguments are given, e.g. like this "link
# follow")

::tclwebtest::ad_proc -public ::tclwebtest::link {
    command
    args
} {

    Search for the first link in the extracted links that matches the
    given criteria and return an index-value pair list with it's
    contents, which can be converted to an array if you want to extract
    specific attributes manually. If there is no link that matches,
    throws <b>assertion_failed</b>. Example of retrieving links,
    which you could use with
    <a href="#tclwebtest::do_request">do_request</a> to create a
    simple web crawler:

    <blockquote><pre>
    <a href="#link_reset_current">link reset_current</a>
    while { ![catch { link find -next } ] } {
        debug "found a link: [<a href="#link_get">link get_text</a>] to [link get_url]"
    }
    </pre></blockquote>

    @param command Specify one of the commands:
    <a href="#link_find">find</a>,
    <a href="#link_follow">follow</a>,
    <a href="#link_all">all</a>,
    <a href="#link_reset_current">reset_current</a>,
    <a href="#link_current">current</a>,
    <a href="#link_get">get_*</a>.
    
    <blockquote><dl>
    <dt><b><a name="link_find">find</a></b></dt>
    <dd>Find and return the first link that matches <i>args</i>
    (or the first link if no <i>args</i> are given). Valid modifiers
    for <i>args</i>:

    <blockquote>
    
    <code>~c</code> (default). <b>c</b>ontent, the text between the
    &lt;a&gt;&lt;/a&gt; tags<br>
    <code>~u</code> <b>u</b>rl (content of the href attribute)<br>
    <code>~f</code> <b>f</b>ull html source<br>

    </blockquote>

    Additionally, you can use the following switches in <i>args</i>:
    <blockquote><dl>
    <dt><b>-index</b></dt>
    <dd>???</dd>

    <dt><b>-next</b></dt>
    <dd>Used alone to loop throught available links. If <b>current_link</b>
    is the last link of the page, it will throw <b>assertion_failed</b>
    unless you are using the switch <b>-fail</b> too.
    </dd>

    <dt><b>-fail</b></dt>
    <dd>Negates the outcome, e.g. if a link is searched and not found, it
    won't throw <b>assertion_failed</b>, if the search was negated, then
    <b>assertion_failed</b> would be thrown, etc.
    </dd>
    
    </dl>
    </blockquote>

    <h4>Matching syntax</h4>
    
    The syntax of the matching functionality is inspired by the filter
    function in the Mutt mailclient. A list of arguments can be given as
    search criteria. When an argument is the "<b>~</b>" followed by a
    single character it acts as modifier that determines in which data
    field the following argument has to match. There is always a default
    data field.
    
    <p>
    
    So e.g. a hyperlink has the data fields content (the text between the
                                                     &lt;a&gt;...&lt;/a&gt; tags), url (the href attribute) and full (the
                                                                                                                      full html source of that link). content is the default data field,
    so you can search for a link that contains some text like that:
    
    <blockquote><pre>
    link find "<b>sometext</b>"
    </pre></blockquote>
    
    If you are looking for a specific url add the ~u modifier:
    
    <blockquote><pre>
    link find ~u "<b>/some/url</b>"
    </pre></blockquote>
    
    Several search criteria are automatically concatenated with AND. So
    you can search for:
    
    <blockquote><pre>
    link find "<b>sometext</b>" ~u "<b>/some/url</b>" "<b>someothertext</b>" ~f "<b>&lt;a[^&gt;]+class=\"?someclass\"?[^&gt;]&gt;</b>"
    </pre></blockquote>
    
    All those attributes have to match - the link must contain
    "<b>sometext</b>" AND "<b>someothertext</b>" in its text, point
    to the specified url AND must have a class attribute. Note that
    e.g. the class attribute is not parsed in a specified data field,
    so it has to be retrieved by searching the full html source of the
    field (but at least its possible to search for it at all).
    
    Search criterias can contain a "<b>!</b>" to specify that the
    following argument must NOT match. "<b>!</b>" can optionally be
    prepended or followed by a "<b>~</b>" modifier. For example:
    
    <blockquote><pre>
    link find "<b>sometext</b>" ! ~u "<b>/but/not/this/url</b>"
    </pre></blockquote>
    
    The matching will always be done with "<b>regexp -nocase</b>". I
    wonder if case sensitive matching will ever be necessary for
    website testing. See the proc find_in_array_list for the matching
    implementation.
    
    <p>
    
    Currently search
    arguments are appended at the end of the command and get parsed into
    the args parameter of the proc. This allows for the maybe more
    convenient syntax:
    
    <blockquote><pre>
    link find "<b>some text with spaces</b>" ~u "<b>/some/url</b>"
    </pre></blockquote>
    
    as opposed to putting everything in a seperate list:
    
    <blockquote><pre>
    link find { "<b>some text with spaces</b>" ~u "<b>/some/url</b>" }
    </pre></blockquote>

    Commands supporting this behaviour are find, form and field.

    </dd>
    
    <dt><b><a name="link_follow">follow</a></b></dt>
    <dd>
    this is the same like doing <code>link find</code> (which means
                                                        that you can use a regular expression as parameter), and then
    <code>do_request</code> with the previous result. Example:
    <blockquote><pre>
    link follow "Download"
    link follow "Back to contents"
    link follow ~u {em[[:alpha:]]+sa}
    </pre></blockquote>

    Note that after this command you can get the current URL with
    <a href="#response_url">response url</a>, useful if you followed a
    link by text and you want to store/verify the url tclwebtest chose.

    </dd>

    <dt><b><a name="link_all">all</a></b></dt>
    <dd>
    Returns all links. Example:
    <blockquote><pre>
    assert { [llength [link all]] == 3 }

    do_request <em>some_url</em>
    
    foreach { data } [link all] {
        array set one_link $data
        log "found link, dumping contents"
        foreach { key } [array names one_link] {
            log "  $key: $one_link($key)"
        }
    }
    </pre></blockquote>

    Note that this example is different from the previous one which
    retrieves all links, in that here you can't use the
    <a href="#link_get">get</a> command to extract only the text of
    a link, because <code>link</code> works like a state machine,
    and after the <code>all</code> command it points at the last
    link of the current page.

    <p>
    
    The only keys you can rely on being available are <code>url</code>,
    <code>content</code> and <code>full</code>. You might see more when
    you log all the packaged data, but these are for internal use and
    you shouldn't use them.

    <p>

    Besides getting everything at once, you can use the familiar
    expression sintax to get only specific links. Also, this command
    accepts the switch <b>-onlyurl</b>, which will return only the
    available urls instead of the whole information of each link which
    was shown with the previous example. You can also add the
    <b>-absolute</b> switch to convert all links to absolute urls.
    The following example connects to Slashdot and then retrieves all
    links with the text content <b>"Read more"</b> which have the
    word <b>article</b> in their urls:

    <blockquote><pre>
    do_request http://slashdot.org/
    foreach url [link all -onlyurl {read more} ~u article] {
        log "$url"
    }
    </blockquote></pre>
    
    </dd>

    <dt><b><a name="link_reset_current">reset_current</a></b></dt>
    <dd>
    This will delete the internal pointer <b>current_link</b>,
    which will behave as if the current page was just loaded and no
    link search had been done. Usefull to go back from
    <code>link find -next</code>.
    </dd>

    <dt><b><a name="link_current">current</a></b></dt>
    <dd>
    Returns the currently selected link. If no link is selected, the
    first one will be returned, or an assertion thrown if there are no
    links at all.
    </dd>

    <dt><b><a name="link_get">get_*</a></b></dt>
    <dd>
    Returns the specified attribute of a link. Example:
    <blockquote><pre>
    debug "found a link: [link get_text]"
    assert { [link get_full] == "&lt;a href=\"mailto:tils@tils.net\"&gt;Tilmann Singer&lt;/a&gt;" }
    </pre></blockquote>
    </dd>

    </dl></blockquote>
    
} {
    
    extract_links_if_necessary

    if { [regexp {get_(.+)} $command match attribute_name] } {
        eval link_get $attribute_name $args
    } else {
        eval link_$command $args
    }

}


::tclwebtest::ad_proc -private ::tclwebtest::link_find {
    -index:boolean
    -next:boolean
    -fail:boolean
    args
} {
    find a link with the given attributes or the first one
    and return the full list or the index.
} {

    # We need a way to loop through all links.This assumes
    # that somehow current_link will be set to -1 for a full
    # search through all links and is somewhat different to
    # the field behaviour
    if { $next_p } {
        # find the next link that matches after the
        # current_link
        
        # fail if current_link points to the last link already
        if { [expr {$::tclwebtest::current_link + 1}] >= [llength $::tclwebtest::links] } {
            if { $fail_p } {
                return
            } else {
                assertion_failed "No more links, thus \"link find -next\" failed. "
            }
        }
        
        incr ::tclwebtest::current_link
        set offset $::tclwebtest::current_link
        debug -lib "next is true, offset is $offset"
    } else {
        # find the first that matches
        set offset 0
    }

    # do something if called without args
    if { [llength $args] == 0 } {
        if { [llength $::tclwebtest::links] == 0 } {
            if { $fail_p } {
                return
            } else {
                assertion_failed "There are no links"
            }
        } else {
            if { !$next_p } {
                # "link find" called without -next and without
                # arguments
                if { $::tclwebtest::current_link == -1 } {
                    # set to first link
                    set ::tclwebtest::current_link 0
                }
            }
            if {$index_p} {
                return $::tclwebtest::current_link
            } else {
                return [lindex $::tclwebtest::links $::tclwebtest::current_link]
            }
        }
    }

    set list_to_search [lrange $::tclwebtest::links $offset end]

    set found_idx [find_in_array_list -index $list_to_search [list ~c content ~u url ~f full] $args]

    if { $found_idx eq "" } {
        if { $fail_p } {
            return
        } else {
            assertion_failed "No link found that matches '$args'"
        }
    } else {
        set found_idx [expr {$found_idx + $offset}]
        set ::tclwebtest::current_link $found_idx

        if { $fail_p } {
            # found something while -fail was set
            assertion_failed "'link find -fail $args' did not expect to find a link, yet it found this one: [lindex $::tclwebtest::links $found_idx]"
        } else {
            if {$index_p} { return $found_idx } else {
                return [lindex $::tclwebtest::links $found_idx] 
            }
        }
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::link_reset_current { } {
    see "field find -next" above
} {
    set ::tclwebtest::current_link -1
}

::tclwebtest::ad_proc -private ::tclwebtest::link_follow args {
    just a shortcut for "do_request [link find args]"
} {
    set evalstr "do_request \[link get_url $args\]"
    debug -lib "following a link by: $evalstr"
    eval $evalstr
}

::tclwebtest::ad_proc -private ::tclwebtest::link_current { } {

} {
    if { $::tclwebtest::current_link == -1 } {
        # set to the first link. will scream if there are no
        # links
        link find
        debug -lib "resetting current_link"
    }

    debug -lib "current_link is $::tclwebtest::current_link"

    return [lindex $::tclwebtest::links $::tclwebtest::current_link]
}

::tclwebtest::ad_proc -private ::tclwebtest::link_all {
    -fail:boolean
    -onlyurl:boolean
    -absolute:boolean
    args
} {
    @see link
} {

    # do something if called without args
    if { [llength $args] == 0 } {
        if { [llength $::tclwebtest::links] == 0 } {
            if { $fail_p } {
                return
            } else {
                assertion_failed "There are no links"
            }
        } else {
            set value $::tclwebtest::links
        }
    } else {
        set value [find_in_array_list -return_matches $::tclwebtest::links [list ~c content ~u url ~f full] $args]
    }

    if { $absolute_p } {
        set counter -1
        foreach item $value {
            incr counter
            array set a_link $item
            set a_link(url) [post_process_url [absolute_link $a_link(url)]]
            set value [lreplace $value $counter $counter [array get a_link]]
        }
    }

    if { $onlyurl_p } {
        set temp [list]
        foreach item $value {
            array set a_link $item
            lappend temp $a_link(url)
        }
        set value $temp
    }

    return $value
    
}

::tclwebtest::ad_proc -private ::tclwebtest::link_get {
    attribute_name
    args
} {
    return the specified attribute of a link. TODO write a
    selftest for this
} {
    
    # it's called content but some might want to call it text,
    # which sounds better
    if { $attribute_name eq "text" } { set attribute_name "content" }

    if { [llength $args] > 0 } {
        eval "link find $args"
    }
    
    array set a_link [link current]

    if { [lsearch [array names a_link] $attribute_name] == -1 } {
        error "In link $command: $attribute_name not found in array, we only have: [array names a_link]"
    }

    return $a_link($attribute_name)
}

# End of link procs.
# ---------------------------------------------------------------------------


# The weird command dispatching below is mainly done to preserve the
# old api 'assert text -fail' instead of having to switch to 'assert
# -fail text' after ad_proc-ifying this, to avoid breaking existing
# test files. Peter Marklund suggested a different API: 'assert
# <explanation> ![response_contains <text>]'. Should consider when
# changing other APIs.

::tclwebtest::ad_proc -public ::tclwebtest::assert {
    args
} {

    Test <i>args</i>, a required boolean expresion (and only one).
    Throws <b>assertion_failed</b> if it's false. Usually <i>args</i>
    is a comparison.

    <p>

    Examples:
    <blockquote><pre>
    assert { $val eq "foo" }
    assert text "Hello world"
    assert full "body&gt;here"
    assert -fail { 0 == 1 }
    assert text -fail "Do not find me"
    assert full -fail "&lt;not"
    </pre></blockquote>

    @param text Test an expression against the visible text of the
    result page.
    @param full Test an expression against the full HTML source of
    the result page.
    @param fail the assertion expects the condition to be false.
    
} {

    if { [lindex $args 0] eq "body" || [lindex $args 0] eq "full" } {

        eval assert_body [lrange $args 1 end]

    } elseif { [lindex $args 0] eq "text" } {

        eval assert_text [lrange $args 1 end]

    } else {
        # normal condition

        if { [lindex $args 0] eq "-fail" } {
            set fail_p 1
            set condition [lindex $args 1]
        } else {
            set fail_p 0
            set condition [lindex $args 0]
        }

        # Sets the variable _assert_p in the calling
        # context. Don't know how else i could evaluate a
        # condition in the same way that if {...} does

        set to_eval "if \{ $condition \} \{ set _assert_p 1 \} else \{ set _assert_p 0 \}"
        uplevel $to_eval
        upvar _assert_p _assert_p
        if { $_assert_p == $fail_p } {
            set condition [string trim $condition]
            set extra [list]

            # Heuristically parse the condition for all variables
            # ($a, $b ...), upvar them and append their values to
            # the message. Cannot do execution of [...] blocks
            # (would propably have unforeseeable side effects)
            set condition_to_search $condition
            regsub -all {\[.*?\]} $condition {} condition_to_search
            foreach word [split $condition_to_search {$}] {
                if { $word eq "" || [string first $word $condition_to_search] == 0 } {
                    # the first result from the split is the text
                    # from the beginning to the first $
                    continue
                }
                if {[regexp {(.*?)(\s|$)} $word match varname]} {
                    debug -lib "displaying the value of '$varname'"
                    upvar $varname value
                    if { [string length $value] > 30 } {
                        set value "[string range $value 0 26]..."
                    }
                    lappend extra "\$$varname: $value"
                }
            }

            if {$fail_p} {
                assertion_failed "Assertion \"$condition\" did not fail, but -fail was given"
            } else {
                assertion_failed "Assertion \"$condition\" failed. [join $extra "; "]"
            }
        }
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::assert_text {
    -fail:boolean
    search_expr
} {
    Test an expression against the visible text of the
    result page. TODO make a more meaningful message
} {
    if {$fail_p} {
        assert -fail { [regexp -nocase $search_expr $::tclwebtest::text] }
    } else { 
        assert { [regexp -nocase $search_expr $::tclwebtest::text] }
    }
}


::tclwebtest::ad_proc -private ::tclwebtest::assert_body {
    -fail:boolean
    search_expr
} {
    Test an expression against the full html source of the
    result page.
} {
    
    if {$fail_p} {
        assert -fail { [regexp -nocase $search_expr $::tclwebtest::body] }
    } else {
        assert { [regexp -nocase $search_expr $::tclwebtest::body] }
    }
}



# from /acs-test-harness/tcl/test-procs.tcl
::tclwebtest::ad_proc -public ::tclwebtest::assertion_failed {
    assertionMsg
} {

    Usually called by tclwebtest, this procedure will raise an error with
    the messsage <i>assertionMsg</i>, which will be caught by a test unit
    and written to the standard output. There will be no error code.

} {
    error "$assertionMsg" "$assertionMsg\n--- end of assertionMsg ---\n" { NONE }
}


# current - get or set the index of the current form. TODO complain
# when called with non-existing command

# parameters should be
#   command
#   args
::tclwebtest::ad_proc -public ::tclwebtest::form {
    command
    args
} {

    tclwebtest keeps an internal pointer, <b>current_form</b>.
    Operations that do not explicitely specify a target
    operate on the element of the current pointer. When such an
    operation is called before a current form or field is set, then
    the pointer will be set to the first possible value. As a result,
    the first (or the only) form is always the default.

    @param command Specify one of the commands:
    <a href="#form_find">find</a>,
    <a href="#form_submit">submit</a>,
    <a href="#form_current">current</a>,
    <a href="#form_get">get_*</a>,
    <a href="#form_all">all</a>.

    <blockquote><dl>
    <dt><b><a name="form_find">find</a></b></dt>
    <dd>
    Set the <b>current_form</b> pointer to the form that matches or
    to the first form when called without <i>args</i>. Valid modifiers
    for <i>args</i>:
    <blockquote>
    <code>~c</code> (default).The user viewable text (<b>c</b>ontent)
    that is between the &lt;form&gt;&lt;/form&gt;
    tags.<br>
    <code>~a</code> the form's <b>a</b>ction<br>
    <code>~m</code> <b>m</b>ethod - either get or post, in
    <b>lower case</b><br>
    <code>~n</code> <b>n</b>ame of the form (also searches id attribute)<br>
    <code>~f</code> the <b>f</b>ull html source of the form<br>
    </blockquote>
    Returns the form as a list suitable for <code>array set</code>.
    For a deeper explanation of the matching syntax, take a look
    at the documentation of <code><a href="#link_find">link find</a
    ></code>. Examples:
    <blockquote><pre>
    form find "dropdown"
    form find ~n "form1"
    </pre></blockquote>
    </dd>

    <dt><b><a name="form_submit">submit</a></b></dt>
    <dd>
    Submit the current form. Invokes <code>form find</code> if no
    current form has previously been set. You can use this without
    parameters (only the first submit button of the form will be used
                to build the query) or specify a regular expression to select the
    submit button you want to use/push. You can also use the search
    modifiers like with <a href="#form_find">form find<a>. Examples:
    <blockquote><pre>
    # required to avoid getting forbidden access (403)
    user_agent_id "Custom mozilla"

    # get number of found entries for tclwebtest
    do_request http://www.google.com/
    field fill tclwebtest
    form submit

    # go directly to the first entry
    do_request http://www.google.com/
    field fill tclwebtest
    form submit {feeling lucky}
    </pre></blockquote>
    </dd>

    <dt><b><a name="form_current">current</a></b></dt>
    <dd>Returns the currently selected form. Example:
    <blockquote><pre>
    # the third form
    form find "firma"
    assert { [form current] == 2 }
    </pre></blockquote>
    </dd>

    <dt><b><a name="form_get">get_*</a></b></dt>
    <dd>
    Returns the specified attribute of a form. TODO write a
    selftest for this.
    </dd>

    <dt><b><a name="form_all">all</a></b></dt>
    <dd>Return a list of all forms.</dd>

    </dl></blockquote>
    
} {

    extract_forms_if_necessary

    if { $command ne "find" } {
        if { ![info exists ::tclwebtest::current_form] || 
             $::tclwebtest::current_form == -1 } {
            # initialize to the first form
            form find
        }

        if { [set current_form $::tclwebtest::current_form] == -1 } {
            error "No form found at all"
        }
    }

    eval form_$command $args
}

::tclwebtest::ad_proc -private ::tclwebtest::form_find args {
    find - set currentform to the first form or to a form on the page
    with specified criteria
} {

    # TODO -next

    if { [llength $::tclwebtest::forms] == 0 } {
        # no forms present
        assertion_failed "No form present"
    } elseif { [llength $args] == 0 } {
        # set to first form on this page
        set ::tclwebtest::current_form 0
        return
    }

    set found [find_in_array_list -index $::tclwebtest::forms [list ~c content ~a action ~m method ~n name ~f full] $args]

    if { $found eq "" } {
        assertion_failed "No form with found with search_string $args"
    }
    set ::tclwebtest::current_form $found
    set ::tclwebtest::current_field 0
    set ::tclwebtest::field_modified_p 0

}

::tclwebtest::ad_proc -private ::tclwebtest::form_submit {
    {args ""}
} {

    Using the current form, it will search for a post/get method and
    use it to retrieve the next page. Only one submit button will be
    used, either the first found, or the one specified by args with
    a regular expression.

    @param args Regular expression which should match one available
    submit button.

} {

    array set a_form [form current]
    set list_to_search [field all]
    # tricky search: ignore non-submit forms, and search for value instead of content
    set args "~T submit $args"
    set found [find_in_array_list -index $list_to_search { ~c value ~T type ~f full ~v value ~n name } $args]

    if { $found eq "" } {
        # no submit widget found. we allow to submit anyway since that
        # is possible in a browser too by hitting return.
        set submit_name ""
        set submit_value ""
    } else {
        array set a_field $[lindex $list_to_search $found]
        set submit_name $a_field(name)
        set submit_value $a_field(value)
    }

    # detect method and initialise memory/function pointers
    if { [string compare -nocase $a_form(method) "post"] == 0 } {
        set temp [list]
        set add_value_to_form_query add_value_to_form_post_query
        set finish_form_query finish_form_post_query
    } elseif { [string compare -nocase $a_form(method) "get"] == 0 } {
        set temp ""
        set add_value_to_form_query add_value_to_form_get_query
        set finish_form_query finish_form_get_query
    } else {
        assertion_failed "Bogus form doesn't have a method?\n$a_form(fields)"
    }
    set temp_files [list]
    
    # now loop over fields calling the procs which build the query
    foreach field $a_form(fields) {
        
        catch { unset a_field }
        array set a_field $field

        if { [string match $a_field(type) "submit"] } {
            # ignore all submit buttons
        } elseif { [string match $a_field(type) "select"] } {
            # a select field - special format of value (it's a
            # list)
            foreach select_value $a_field(value) {
                $add_value_to_form_query temp $a_field(name) $select_value
            }
        } elseif { [string match $a_field(type) "checkbox"] } {
            if { $a_field(value) ne "" } {
                $add_value_to_form_query temp $a_field(name) $a_field(value)
            }
        } elseif {$a_field(type) eq "file"} {
            if { $a_field(value) ne "" } {
                $add_value_to_form_query temp_files $a_field(name) $a_field(value)
            }
        } else {
            $add_value_to_form_query temp $a_field(name) $a_field(value)
        }
    }
    # add submit button as last element and perform query
    $add_value_to_form_query temp $submit_name $submit_value
    $finish_form_query temp temp_files a_form
}

::tclwebtest::ad_proc -private ::tclwebtest::add_value_to_form_post_query {
    holder_name
    field_name
    field_value
} {

    <a href="#tclwebtest::form_submit">form_submit</a> helper for
    post query operations.

    @param holder_name name of the variable holding the temporary memory
    used to store additional query parameters.
    
    @param field_name name of the field to be added to the query.

    @param field_value value of the field to be added to the query.
    
} {

    upvar $holder_name holder
    lappend holder $field_name $field_value
    
}

::tclwebtest::ad_proc -private ::tclwebtest::finish_form_post_query {
    holder_name
    file_holder_name
    form_name
} {

    <a href="#tclwebtest::form_submit">form_submit</a> helper for
    finishing post query operations, it will call
    <a href="#tclwebtest::do_request">do_request</a> after building the
    query correctly from the parameter list <code>holder_name</code>.

    @param holder_name name of the variable holding the temporary memory
    used to store all the query parameters.

    @param form_name name of the array containing all the form fields.
    
} {

    upvar $holder_name holder $file_holder_name file_holder $form_name a_form
    debug -lib "POSTING: $holder"
    do_request -enctype $a_form(enctype) -files $file_holder $a_form(action) $holder
    
}

::tclwebtest::ad_proc -private ::tclwebtest::add_value_to_form_get_query {
    holder_name
    field_name
    field_value
} {

    <a href="#tclwebtest::form_submit">form_submit</a> helper for
    get query operations.

    @param holder_name name of the variable holding the temporary memory
    used to store additional query parameters.
    
    @param field_name name of the field to be added to the query.

    @param field_value value of the field to be added to the query.
    
} {

    upvar $holder_name holder
    append holder &[http::formatQuery $field_name]=
    append holder [http::formatQuery $field_value]
    
}

::tclwebtest::ad_proc -private ::tclwebtest::finish_form_get_query {
    holder_name
    file_holder_name
    form_name
} {

    <a href="#tclwebtest::form_submit">form_submit</a> helper for
    finishing get query operations, it will call
    <a href="#tclwebtest::do_request">do_request</a> after building the
    query correctly from the parameter list <code>holder_name</code>.

    @param holder_name name of the variable holding the temporary memory
    used to store all the query parameters.

    @param form_name name of the array containing all the form fields.
    
} {

    upvar $holder_name holder $file_holder_name file_holder $form_name a_form
    
    if { [llength $file_holder] > 0 } {
        error "Trying to submit a form with a file using GET"
    }

    set url [absolute_link $a_form(action)]
    set query_string "$url?[string range $holder 1 end]"
    debug -lib "FORM GET: $query_string"
    do_request $query_string
    
}

::tclwebtest::ad_proc -private ::tclwebtest::form_current {
    -index:boolean
} {

    just return the current form

} {

    if {$index_p} {
        return $::tclwebtest::current_form
    } else {
        return [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::form_get {
    attribute_name
    args
} {

    return the specified attribute of a form. TODO write a
    selftest for this

} {

    array set a_form [form current]

    if { [lsearch [array names a_form] $attribute_name] == -1 } {
        error "In form $command: $attribute_name not found in array, we only have: [array names a_form]"
    }

    return $a_form($attribute_name)
}

::tclwebtest::ad_proc -private ::tclwebtest::form_all { } {
    return a list of all forms
} {
    return $::tclwebtest::forms
}



# ---------------------------------------------------------------------------
# Begin field procs

# We keep a pointer to the current field. It will initially (after
# first access to any form or field) be set to index 0. The command
# "field find" and all commands that call it will set that pointer to
# the index of the found field. Additionally we keep a flag
# field_modified_p, that will be set by all commands that modify the
# field value, and unset by a find operation.

# TODO add a ~i attribute for the index of the field.

::tclwebtest::ad_proc -public ::tclwebtest::field {
    command
    args
} {

    tclwebtest keeps an internal pointer, <b>current_form</b>.
    Operations that do not explicitely specify a target
    operate on the element of the current pointer. When such an
    operation is called before a current field is set, then
    the pointer will be set to the first possible value. As a result,
    the first (or the only) field is always the default.

    <p>
    
    Setting field values (via <code>field fill / check / uncheck /
                          select</code>) does the following: it searches for the first
    applicable field (e.g. a <code>field check</code> searches a
                      checkbox) starting from the current_field position, sets the
    value, and then advances the current_field pointer by one. Thus it
    is possible to handle a form of two text entries and a checkbox
    using this brief (and hopefully convenient) syntax:

    <blockquote>
    <code>field fill &#034;foo&#034;<br>
    field fill &#034;bar&#034; ~n fieldname<br>
    field fill -append &#034;baz&#034;<br>
    field check<br>
    form submit
    </code>
    </blockquote>
    
    This assumes that there are two text (or textarea or password)
    fields, followed by one checkbox. The commands would have to be
    reordered if the form items were in another order.

    @param command Specify one of the commands:
    <a href="#field_check">check / unckeck a single checkbox</a>,
    <a href="#field_check_multiple">check / unckeck a group of checkboxes with common name</a>,
    <a href="#field_current">current</a>,
    <a href="#field_fill">fill</a>,
    <a href="#field_find">find</a>,
    <a href="#field_select">select</a>,
    <a href="#field_multiselect">multiselect</a>,
    <a href="#field_deselect">deselect</a>.
    <a href="#field_get">get_*</a>,

    <blockquote><dl>
    <dt><b><a name="field_find">find</a></b></dt>
    <dd>
    Find the first field that matches <i>args</i> , or the
    first user modifyable field (e.g. not of type hidden nor submit)
    when no <i>args</i> are given, and set the current_field pointer
    to it. Valid modifiers for <i>args</i>:

    <blockquote>
    <code>~c</code> (default). <b>c</b>aption<br>
    <code>~t</code> the <b>t</b>ype, can be text, textarea, password,
    hidden, radio, checkbox, select or submit<br>
    <code>~v</code> current <b>v</b>alue <br>
    <code>~n</code> <b>n</b>ame<br>
    <code>~f</code> <b>f</b>ull html source
    </blockquote>
    
    Returns the field as a list suitable for <code>array set</code>.
    For a deeper explanation of the matching syntax, take a look
    at the documentation of <code><a href="#link_find">link find</a
    ></code>. Examples:
    <blockquote><pre>
    field find "title"
    field find "Start Time 6:00"
    field find "End Time"
    field find "Description"
    </pre></blockquote>
    
    </dd>

    <dt><b><a name="field_all">all</a></b></dt>
    <dd>
    Returns a list that contains all data of all fields.
    </dd>
    <dt><b><a name="field_current">current</a></b></dt>

    <dd>
    Used to set or get the value of the currently selected
    form field. This is a pointer value, with 0 being the first field,
    1 the second, etc. When no <i>?value?</i> is given, the pointer is
    returned, otherwise set. Usually you will prefer to use
    <tt>field find <i>args</i></tt> to select form fields.
    </dd>

    <dt><b><a name="field_fill">fill</a></b></dt>
    <dd>
    Fill <i>args</i> into a field that takes text as input
    - either text, textarea or password. It also moves the
    <b>current_field</b> pointer to the next field. By default
    tclwebtest will replace the content of the field, but you can
    specify the optional boolean parameter <b>-append</b> to append
    the selected text to the value the form currently contains. Example:

    <blockquote><pre>field fill -append { and some more options...}</pre
    ></blockquote>

    If you specify a pattern the first field that matches will be filled
    instead of the current_field. The pattern goes at the end of the command, 
    after the new value. Example:

    <blockquote><pre>field fill &#034;bar&#034; ~n fieldname<br></pre>
    </blockquote>

    If the field is of type file upload then you can enter a filename 
    relative to the test location, e.g. 'some_file.txt' or the full
    path like this: '/path/to/some_file.txt', and tclwebtest will try to
    upload the specified file.
    </dd>

    


    <dt><b><a name="field_check">check / uncheck</a></b></dt>
    <dd>Check or uncheck the currently selected checkbox field.</dd>

    <dt><b><a name="field_select">select</a></b></dt> <dd>Select a
    value of a radio button or a select field. If it is a multiple
    select then deselect the others. You can select a specific index
    (starting from 0) of the select field with the <tt>-index</tt>
    parameter. If you want to know the options of the select, use
    <a href="#field_get">field get_choices</a>. This returns a list
    of pairs in the form <tt>value/text</tt>, where <tt>value</tt>
    is equal to text if the HTML of the &lt;option&gt; tag doesn't
    have a <tt>value</tt> attribute.

    </dd>
    
    <dt><b><a name="field_multiselect">multiselect</a></b></dt>
    <dd>
    Add one or more values to the current selection of a multiple
    select field. If a value is not found in the selection box, you
    will get an assertion error indicating which values are available,
    and which were the ones you asked and weren't found.
    </dd>

    <dt><b><a name="field_deselect">deselect</a></b></dt>
    <dd>
    Delete the selection of a multiple select field. (Not
                                                      possible with drop-downs and radio buttons)
    </dd>

    <dt><b><a name="field_get">get_*</a></b></dt>
    <dd>
    Returns the specified attribute of a form field. Typical
    attributes you can retrieve from most fields are <tt>name</tt>,
    <tt>value</tt>, <tt>type</tt> and <tt>full</tt>. The availability
    of these and other attributes depends on the HTML code used by
    the field.
    </dd>

    </dl></blockquote>

} {
    extract_forms_if_necessary

    if { $::tclwebtest::current_form == -1 } {
        form find
    }

    if { [regexp {^get_(.+)$} $command match attribute_name] } {
        # some command like 'field get_value'
        eval field_get $attribute_name $args
    } else {
        # one of the other field commands
        eval field_$command $args
    }

} ;# end of field




::tclwebtest::ad_proc -private ::tclwebtest::field_fill {
    -append:boolean
    value
    args
} {

    @see field

} {

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    find_field_of_type { text textarea password file } $args
    
    set cf $::tclwebtest::current_field   ;# just a shortcut
    
    set field [lindex $a_form(fields) $cf]
    array set a_field $field
    if { $append_p } {
        set a_field(value) "$a_field(value)$value"
    } else {
        set a_field(value) $value
    }
    set field [array get a_field]
    set a_form(fields) [lreplace $a_form(fields) $cf $cf $field]
    set form [array get a_form]
    set ::tclwebtest::forms [lreplace $::tclwebtest::forms $::tclwebtest::current_form $::tclwebtest::current_form $form]
    
    set ::tclwebtest::field_modified_p 1
}

::tclwebtest::ad_proc -private ::tclwebtest::field_fill_hidden {
    value
    args
} {
    Fill the specified text in the first hidden field. 
    
    This just updates the field(value), not the actual html
    code in field(full) and is a copy of fill above
} {
    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    find_field_of_type { hidden } $args
    
    set cf $::tclwebtest::current_field   ;# just a shortcut
    
    set field [lindex $a_form(fields) $cf]
    array set a_field $field
    set a_field(value) $value
    set field [array get a_field]
    set a_form(fields) [lreplace $a_form(fields) $cf $cf $field]
    set form [array get a_form]
    set ::tclwebtest::forms [lreplace $::tclwebtest::forms $::tclwebtest::current_form $::tclwebtest::current_form $form]
    
    set ::tclwebtest::field_modified_p 1
}

::tclwebtest::ad_proc -private ::tclwebtest::field_select {
    -index:boolean
    search_arg
    args
} {
    field select ?-index? value ?search_args ...?
    
    To be used with radio buttons or select fields. Select
    the entry that contains the specified text in its
    caption or the nth entry by specifying -index and a
    number as value (starting from 0). If the field is a
    select with multiple selections, then the new value will
    replace previously selected ones.
} {
    
    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    find_field_of_type { radio select } $args
    
    array set a_field [lindex $a_form(fields) $::tclwebtest::current_field]
    if { $index_p } {
        # was called with -index
        if { $search_arg > [expr {[llength $a_field(choices)] - 1}] } {
            assertion_failed "This field (name: $a_field(name)) cannot be set to index $value. Its choices are: $a_field(choices)"
        }
        set a_field(value) [list [lindex [lindex $a_field(choices) $search_arg] 0]]
    } else {
        # not called with -index, e.g. an expression is given
        # for the desired caption to set
        
        # TODO we might allow for search args such as { ~v
        # some-explicit-value } instead of just searching in
        # caption
        
        debug -lib "SEARCHING FOR: $search_arg"
        set found_p 0
        foreach choice $a_field(choices) {
            set looped_value [lindex $choice 0]
            set looped_caption [lindex $choice 1]
            
            if { [regexp -nocase $search_arg $looped_caption] } {
                set found_p 1
                debug -lib "FOUND: $choice"
                set a_field(value) [list $looped_value]
                break
            }
        }
        
        if {!$found_p} {
            assertion_failed "This field has no choice $search_arg. It's only offerings are: $a_field(choices)"
        }
    }
    replace_current_field [array get a_field]

    set ::tclwebtest::field_modified_p 1
} ;# end of select

::tclwebtest::ad_proc -private ::tclwebtest::field_select2 {
    args
} {
    field select2 ~i index ~c caption ~v value ~d ID
    
    assumes you've found the form and the field first

} {
    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]

    array set a_form $form

    array set a_field [lindex $a_form(fields) $::tclwebtest::current_field]

    set found [find_in_array_list -index $a_field(choices2) { ~c caption ~v value ~i index ~d id } $args]

    if {$found eq ""} {
        assertion_failed "Select option not found. Args were: $search_arg $args"
    } else {
        set a_field(value) [list [lindex [lindex $a_field(choices) $found] 0]]
    }
    replace_current_field [array get a_field]

    set ::tclwebtest::field_modified_p 1
} ;# end of select

::tclwebtest::ad_proc -private ::tclwebtest::field_multiselect {
    value_list
    args
} {

} {

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    find_field_of_type select [concat ~m 1 $args]
    array set a_field [lindex $a_form(fields) $::tclwebtest::current_field]

    set missing_choices ""
    
    foreach subex $value_list {
        # loop through all search args (when this is not a
        # multiple select then there will only be one)
        debug -lib "SEARCHING FOR SUBEX: $subex"
        set found_p 0
        
        foreach choice $a_field(choices) {
            set looped_value [lindex $choice 0]
            set looped_caption [lindex $choice 1]
            
            if { [regexp -nocase $subex $looped_caption] } {
                set found_p 1
                if { $a_field(type) eq "select" && $a_field(multiple_p) } {
                    # a multiple selection - add the found
                    # value to the existing value list
                    lappend a_field(value) $looped_value
                } else {
                    # no multiple selection allowed - just set the value
                    set a_field(value) [list $looped_value]
                }
                break
            }
            
        } ;# next choice
        
        if {!$found_p} {
            if { $missing_choices eq "" } {
                set missing_choices "`$subex'"
            } else {
                append missing_choices ", `$subex'"
            }
        }
    } ;# next subex

    if { $missing_choices ne "" } {
        assertion_failed "This field doesn't contain the following choices: $missing_choices. It's only offerings are: $a_field(choices)"
    }
    
    replace_current_field [array get a_field]
    set ::tclwebtest::field_modified_p 1
} ;# end of multiselect

::tclwebtest::ad_proc -private ::tclwebtest::field_deselect args { 

} {
    # clear a multiple select field. TODO 
    find_field_of_type select [concat ~m 1 $args]

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form
    
    array set a_field [field current]
    
    if { ! ($a_field(type) eq "select" && $a_field(multiple_p)) } {
        assertion_failed "You cannot deselect the field $a_field(name) because it is not a multiple select field"
    }
    set a_field(value) [list]
    replace_current_field [array get a_field]
    set ::tclwebtest::field_modified_p 1
} ;# end of deselect

::tclwebtest::ad_proc -private ::tclwebtest::field_check args {
    field check ?search_args ...?
    
    Check a checkbox
} {
    
    find_field_of_type checkbox $args

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    array set a_field [field current]
    
    if { $a_field(type) ne "checkbox" } {
        assertion_failed "This field is not a checkbox"
    }
    
    set a_field(value) [lindex $a_field(choices) 1]
    replace_current_field [array get a_field]
    set ::tclwebtest::field_modified_p 1
} ;# end of select

::tclwebtest::ad_proc -private ::tclwebtest::field_check_multiple {
    checkbox_name
    checkbox_values
} {
    Loop over a group of checkboxes with a given name and select
    those with a value matching a list of values.

    @checkbox_name The name of the checkboxes to check
    @checkbox_values A list of values that indicate which checkboxes to check

    @autor Peter Marklund
} {
    while { 1 } {
        if { [catch {field find -next ~n $checkbox_name ~t checkbox}] } {
            # No more checkboxes
            break
        }
        
        array set current_field [::tclwebtest::field_current]

        set checkbox_value [lindex $current_field(choices) 1]
        if { [lsearch -exact $checkbox_values $checkbox_value] != -1 } {
            field check
        } else {
            # field_find -next will give us the current field eternally as
            # long as it hasn't been modified so increment current field manually
            incr ::tclwebtest::current_field
        }
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::field_uncheck args {

} {
    # opposite of field check
    find_field_of_type checkbox $args

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form
    
    array set a_field [field current]
    
    if { $a_field(type) ne "checkbox" } {
        assertion_failed "This field is not a checkbox"
    }
    
    set a_field(value) [lindex $a_field(choices) 0]
    replace_current_field [array get a_field]
    set ::tclwebtest::field_modified_p 1
} ;# end of uncheck


::tclwebtest::ad_proc -private ::tclwebtest::field_get {
    attribute_name
    args
} {
    return the specified attribute of a field. TODO write a
    selftest for this
} {
    
    if { [llength $args] > 0 } {
        eval "field find $args"
    }
    
    array set a_field [field current]

    if { [lsearch [array names a_field] $attribute_name] == -1 } {
        error "$attribute_name not found in array, we only have: [array names a_field]"
    }

    return $a_field($attribute_name)
}

::tclwebtest::ad_proc -private ::tclwebtest::field_current {
    -index:boolean
    {new_index ""}
} {
    @see field
} {

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form
    
    if { $::tclwebtest::current_field == -1 } {
        field find
    }

    if { $new_index ne "" } {
        # set the current field
        if { [expr {[llength $a_form(fields)] - 1}] < $new_index } {
            assertion_failed "field current: Cannot set current field to index $new_index, field count is: [llength $a_form(fields)]"
        }

        set ::tclwebtest::current_field $new_index
        set ::tclwebtest::field_modified_p 0

    } else {
        # return the current field
        if {$index_p} {
            return $::tclwebtest::current_field
        } else {
            return [lindex $a_form(fields) $::tclwebtest::current_field]
        }
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::field_all { } {
    @see field
} {
    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form

    return $a_form(fields)
}

::tclwebtest::ad_proc -private ::tclwebtest::field_find {
    -next:boolean
    args 
} {
    @see field
} {
    # TODO implement -fail

    set form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    array set a_form $form
    
    if { [llength $a_form(fields)] == 0 } {
        assertion_failed "there are no fields in the current form"
    }
    
    if { [llength $args] == 0 } {
        # no search criteria - set args to search for any
        # fillable field. Hidden fields cannot be manipulated
        # and thus cannot be found either. They are just
        # there.
        set args [list ~t (text|textarea|password|checkbox|radio|select)]
    }
    
    if { $next_p } {
        # search starts from the current field or from the one
        # after if the current has been modified already
        
        if { $::tclwebtest::field_modified_p } {
            set offset [expr {$::tclwebtest::current_field + 1}]
        } else {
            set offset $::tclwebtest::current_field
        }

        set list_to_search [lrange $a_form(fields) $offset end]
    } else {
        # search starts from the beginning
        set list_to_search $a_form(fields) 
        set offset 0
    }
    

    set found [find_in_array_list -index $list_to_search { ~c caption ~f full ~t type ~v value ~n name ~m multiple_p ~i index ~d id ~C choices } $args]
    if { $found eq "" } {
        assertion_failed "Field not found. Args were: $args"
    } else {
        set ::tclwebtest::current_field [expr {$offset + $found}]
        set ::tclwebtest::field_modified_p 0
        return [lindex $a_form(fields) $::tclwebtest::current_field]
    }
}



::tclwebtest::ad_proc -private ::tclwebtest::replace_current_field { new_field } {
    @see field
} {
    set cfo $::tclwebtest::current_form
    set cfi $::tclwebtest::current_field
    
    array set a_form [lindex $::tclwebtest::forms $cfo]
    set a_form(fields) [lreplace $a_form(fields) $cfi $cfi $new_field]
    
    set ::tclwebtest::forms [lreplace $::tclwebtest::forms $cfo $cfo [array get a_form]]

}

::tclwebtest::ad_proc -private ::tclwebtest::find_field_of_type { types search_args } {
    Set the current field accordingly (used by the "field xxx" procs)
} {    
    if { [string trim [join $search_args]] == "" } {
        set to_eval "field find -next ~t ([join $types "|"])"
    } else {
        set to_eval "field find ~t ([join $types "|"]) $search_args"
    }
    
    eval $to_eval
}


# End of field procs
# ---------------------------------------------------------------------------



# ------------------------------------------------------------------
# ---------------------- Cookies -----------------------------------

::tclwebtest::ad_proc -public ::tclwebtest::cookies {
    command
    {cookies_to_add ""}
} {

    @param command Specify one of the commands:
    <a href="#cookie_clientvalue">clientvalue</a>,
    <a href="#cookie_all">all</a>,
    <a href="#cookie_persistent">persistent</a>,
    <a href="#cookie_set">set</a>,
    <a href="#cookie_clear">clear</a>.
    
    <blockquote><dl>
    <dt><b><a name="cookie_clientvalue">clientvalue</a></b></dt>
    <dd>
    A string that is the concatenation of all cookies that
    this http client wants to set. E.g. the value of the
    "<b>Cookie: </b>" http header.
    </dd>

    <dt><b><a name="cookie_all">all</a></b></dt>
    <dd>
    Return all cookies that are currently used in this session.
    </dd>

    <dt><b><a name="cookie_persistent">persistent</a></b></dt>
    <dd>
    Return all persistent cookies, e.g. those that the browser
    would store on the harddisk, in a name/value paired list.
    </dd>

    <dt><b><a name="cookie_set">set</a></b></dt>
    <dd>
    Set the currently used cookies of this session to
    <i>args</i>.Typically used to test persistent cookies, for example
    those of a permanent login. <i>args</i> must be formatted
    like the output of <code>cookies persistent</code>.
    </dd>

    <dt><b><a name="cookie_clear">clear</a></b></dt>
    <dd>Clears all the cookies from memory.</dd>

    </dl></blockquote>

} {
    switch $command {
        
        clientvalue {
            set result_list [list]
            foreach { name cookie } $::tclwebtest::cookies {
                catch { unset a_cookie }
                array set a_cookie $cookie
                lappend result_list "$name=$a_cookie(value)"
            }
            return [join $result_list "; "]
        }
        
        all {
            # return all cookies
            return $::tclwebtest::cookies
        }
        
        persistent {
            # return persistent cookies
            set result [list]
            foreach { name cookie } $::tclwebtest::cookies {
                catch { unset a_cookie }
                array set a_cookie $cookie
                if { [info exists a_cookie(persistent_p)] && 
                     $a_cookie(persistent_p) } {
                    lappend result $name $cookie
                }
            }
            return $result
        }
        
        set {
            # TODO maybe let this only be called at the beginning of a
            # session.
            
            # TODO only correctly deals with the output of "cookie
            # all" or "cookie persistent". Does not even throw an
            # error if input is not correct. It should check and set
            # the few needed values, so that cookies can be manually
            # written in test cases too.

            if { [llength $cookies_to_add] == 0 } {
                log "'cookies set' was called with an empty list, so I assume we should clear the cookies"
                cookies clear
                return
            }

            array set a_cookies $::tclwebtest::cookies
            
            foreach { name cookie } $cookies_to_add {
                set a_cookies($name) $cookie
            }
            set ::tclwebtest::cookies [array get a_cookies]
        }

        clear {
            set ::tclwebtest::cookies [list]
        }

        default {
            error "the command \"cookies $command\" does not exist"
        }
    }
}


::tclwebtest::ad_proc -private ::tclwebtest::scan_cookie_expiration_time {
    time_string
} {

    Used to parse the different cookie time values thrown by servers.
    It tries iteratively different formats until one of them is parsed
    correctly, and then returns the cookie expiration time in seconds
    since the starting epoch. If unable to parse the time,
    assertion_failed is raised to abort the request.
    
} {

    if { [catch { set ret [clock scan $time_string]}] == 0 } {
        return $ret
    }

    # Try stripping trailing 'garbage' from time_string
    set ttime [string range $time_string 0 [string first $time_string ";"]]
    if { [catch { set ret [clock scan $ttime]}] == 0 } {
        return $ret
    }

    assertion_failed "scan_cookie_expiration_time unable to parse cookie time '$time_string'"

}

::tclwebtest::ad_proc -private ::tclwebtest::set_cookie {
    set_cookie_string 
} {

    Parses the value of the http "Set-cookie: " header into the global
    cookies list. Doesn't do anything with the path argument, e.g. if it
    is not / than this proc will behave wrongly.

    Also it currently depends on the Expires= information to be parsable
    by the tcl command <code>clock scan</code>. If that is not the
    case then it will throw an error.

} {

    # Cookies spec. is here:
    # http://wp.netscape.com/newsref/std/cookie_spec.html Some
    # examples of actual cookies seen on the web follow:
    # 'cookietest=1; expires=Mon, 09-May-2033 04:18:36 GMT; path=/'
    #
    # --atp@piskorski.com, 2003/05/09 00:22 EDT


    array set a_cookies $::tclwebtest::cookies
    
    if ![regexp {([^=]+)=([^;]*)} $set_cookie_string match name value] {
        error "I did not understand this Cookie value: \"$set_cookie_string\". Please improve me."
    }
    
    set a_cookie(full) $set_cookie_string
    
    if { [regexp -nocase {expires\s*=\s*([^;]*)} $set_cookie_string match expires] } {
        set a_cookie(persistent_p) 1
        set a_cookie(expires) $expires
        
        set expires_seconds [scan_cookie_expiration_time $expires]
        
        if { $expires_seconds > [clock seconds] } {
            # A persistent cookie that wants to be set
            
            set a_cookie(persistent_p) 1
        } else {
            # A cookie that wants to be unset (either persistent or
            # not)
            
            catch { unset a_cookies($name) }
            set ::tclwebtest::cookies [array get a_cookies]
            return
            
        }
        #debug -lib "expires: $expires"
        
    } else {
        # A non-persistent cookie
        set a_cookie(persistent_p) 0
        set a_cookie(expires) ""
    }
    
    set a_cookie(name) $name ;# Note: the name is also stored in the outer cookie array
    set a_cookie(value) $value
    
    #debug -lib "string: $cookie_string"
    #debug -lib "name: $cookie_name, value: $cookie_value"
    
    # append this cookie
    set a_cookies($name) [array get a_cookie]
    set ::tclwebtest::cookies [array get a_cookies]
    
}

# --- end of Cookies -----------------------------------------------
# ------------------------------------------------------------------



::tclwebtest::ad_proc -private ::tclwebtest::add_referer_header {
    header_list_name
    previous_url
} {

    Given the name of a list containing the headers of the next http
    request, adds to this list previous_url as referer depending on
    the value of previous_url and ::tclwebtest::referer_policy.
    
} {

    if { $previous_url ne "" } {

        upvar $header_list_name headers
        switch -- $::tclwebtest::referer_policy {
            0 {
                # do nothing
            }
            1 {
                # send correct referer
                lappend headers "Referer" $previous_url
                debug -lib "using referer $previous_url"
            }
            2 {
                # send fake referer
                if { $::tclwebtest::forged_referer ne "" } {
                    lappend headers "Referer" $::tclwebtest::forged_referer
                }
            }
        }
    }
}



::tclwebtest::ad_proc -public ::tclwebtest::referer {
    url_or_type
} {

    Use this command to modify the referer url field which will be
    sent by tclwebtest in the following http requests, or change
    the policy. Calling <code>reset_session</code> will reset the
    policy to the default value (1).

    @param url_or_type can be any of the following values:

    <blockquote><dl>
    <dt><b>0 (numerical) or emtpy string ("")</b></dt>
    <dd>Using one of these values will desactivate sending the referer
    field in subsequent http requests.</dd>

    <dt><b>1 (numerical)</b></dt>
    <dd>tclwebtest will send the real referer expected to be sent by
    a usual browser: if you are making the first request, no referer
    will be sent, otherwise, the location you are coming from will
    be sent as referer. Note that this applies to both
    <code>link</code> and <code>do_request</code> commands. You will
    have to call <code>reset_session</code> to clean the old referer
    url, as well as other session variables like cookies. This is
    the default value.</dd>

    <dt><b>string</b></dt>
    <dd>Any url you may want to specify, which means that all the
    following requests will use it in the referer http field.
    Calling <code>reset_session</code> will eliminate the forged
    url.</dd>
    </dl></blockquote>
    
} {

    if { $url_or_type == 1 } {
        set ::tclwebtest::referer_policy 1
    } elseif { $url_or_type == 0 || $url_or_type eq "" } {
        set ::tclwebtest::referer_policy 0
    } else {
        set ::tclwebtest::referer_policy 2
        set ::tclwebtest::forged_referer $url_or_type
    }
    
}



::tclwebtest::ad_proc -public ::tclwebtest::open_browser {
    html 
    {tmp_file ""}
} {

    Save the given html result in a temporary file and launch a browser. 
    Intended to be inserted into a test while writing it to give a more
    thorough feedback than with <code>debug</code>.

    <p>

    Currently not satisfying since some referenced files such as images
    and stylesheets are required for a pleasing display. Maybe it is
    sufficient to parse the html for all those links, download the files
    and save them in a temporary directory, and replace them in the
    parsed html for local references.

} {
    global tcl_platform
    
    if { $tmp_file eq "" } {
        set tmp_file "/tmp/test_lib_tcl/tmp.html"
    }
    
    file mkdir [file dirname $tmp_file]
    
    set file [open $tmp_file w]
    #puts $file $html
    close $file
    
    switch $tcl_platform(platform) {
        "unix" {
            exec "mozilla" "file://$tmp_file" "&"
        }
        "windows" {
            eval "exec [auto_execok start] [list "file://$tmp_file"] &"
        }
    }
}



::tclwebtest::ad_proc -public ::tclwebtest::do_request {
    {-followequiv:boolean 0}
    {-nocomplain:boolean 0}
    {-nocomplain_list {}}
    {-noredirect:boolean 0}
    {-files {}}
    {-enctype "application/x-www-form-urlencoded"}
    url
    { query_key_values "" }
} {

    Do an http request and store everything in the current session.
    Returns the URL it has reached, which <b>can</b> be different from your
    request if there were redirections.

    <p>

    Expects a sane reply from the server, e.g. no status "500 Internal
    Server Error" or 404's and throws an assertion_failed
    otherwise. Here you have a <a
    href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html">list
    of possible http error codes</a>.

    <p>

    If you have problems with URL's that are on another port than 
    at the standard http port 80, look at the tcl bug #452217 at
    sourceforge, related to duplicate Host: headers.

    @param url the url to be requested. Examples:
    <code>http://openacs.org/register/</code>,
    <code>/foo/bar/some_page.html</code>,
    <code>some_page.html</code>,
    <code>file:///tmp/my_test_file.html</code>.

    @param query_key_values list of query elements (in the format:
                                                    key value key value ...) for a POST request. If not set then the
    request will be a GET, otherwise a POST.

    @param followequiv follow redirects that are specified inside the
    html code with the http-equiv tag (for weird websites)
    
    @param nocomplain don't fail on 404's and other errors

    @param nocomplain_list a more specialised version of <b>-nocomplain</b>,
    this parameter accepts a list of the error codes you explicitly want to
    ignore, and it will fail with those error codes not included in your
    list. If <b>-nocomplain</b> is present in the request, this parameter
    is ignored completely. Example:

    <blockquote><pre>
    do_request -nocomplain {301 401} url
    </pre></blockquote>

    @param noredirect don't follow server redirections. This is useful
    for example if you want to verify the redirection chain of steps of
    a specific site and see the values of the cookies set at every new
    step. Also useful if you wan't to make sure the url you are getting
    is the one you requested. Example:

    <blockquote><pre>
    set original http://slashdot.org/
    set new [do_request $original]
    <a href="#tclwebtest::assert">assert</a> { $new == $original }
    </pre></blockquote>

} {

    variable regexp_script_before_html
    variable regexp_http_equiv_redirect

    if {$nocomplain_p} {
        set nocomplain_option "-nocomplain -nocomplain_list {$nocomplain_list}"
    } else {
        set nocomplain_option " -nocomplain_list {$nocomplain_list}"
    }

    # As a global option. Added this here because i needed it after a
    # "form submit", but thats suboptimal.
    if { $::tclwebtest::FOLLOWEQUIV } {
        set followequiv_p 1
    }

    if {$followequiv_p} {
        set followequiv_option "-followequiv"
    } else {
        set followequiv_option ""
    }

    # reset all parts of the session that have to be reset
    set ::tclwebtest::links_extracted_p 0
    set ::tclwebtest::links [list]
    
    set ::tclwebtest::forms_extracted_p 0
    set ::tclwebtest::forms [list]
    set ::tclwebtest::current_form -1
    

    # remove any bookmark reference from the end of the url TODO write
    # a selftest
    regsub {#[^#]*$} $url {} url
        
    # for emacs
    if {1} {}
    #"

    set url [post_process_url [absolute_link $url]]
    set previous_url $::tclwebtest::url
    set ::tclwebtest::url $url
    
    log "--- do_request for $url"
    set final_url $url

    # Kludge to deal with file:// urls. TODO implement this cleaner
    # into the do_request proc
    if { [string match "file://*" $url] } {
        return [do_request_file $url]
    }

    if { [string match "https://*" $url] } {
        require_https_support
    }
    
    ::http::config -useragent $::tclwebtest::user_agent
    
    set headers [list]
    if { [llength $::tclwebtest::cookies] > 0 } {
        lappend headers "Cookie" [cookies clientvalue]
    }

    # adding the referer http field if needed
    add_referer_header headers $previous_url

    # detect if we have to inject an http authorization
    set already_tried_http_authorization 0
    if { $::tclwebtest::http_auth_string ne "" } {
        lappend headers "Authorization" $::tclwebtest::http_auth_string
        set ::tclwebtest::http_auth_string ""
        set already_tried_http_authorization 1
    }
    
    set geturl_command [list ::http::geturl $url -headers $headers]

    # Decide if we add parameters for a POST operation
    if {$enctype eq "multipart/form-data"} {
        set query_content {}

        set boundary "-----NEXT_PART_[clock seconds].[pid]"
        foreach { elmname filename } $files {
            set fd [open $filename r]
            fconfigure $fd -translation binary
            if { [catch { read $fd [file size $filename] } data] } {
                return -code error $data
            }
            close $fd
            append query_content "--$boundary\r\nContent-Disposition: form-data;\
name=\"$elmname\"; filename=\"[file tail $filename]\"\r\n\r\n$data\r\n"
        }
        foreach { elmname data } $query_key_values {
            append query_content "--$boundary\r\nContent-Disposition: form-data;\
name=\"$elmname\"\r\n\r\n$data\r\n"
        }
        append query_content "--${boundary}"
        
        lappend geturl_command -type "$enctype; boundary=$boundary"
        lappend geturl_command -query $query_content
    } elseif { $query_key_values ne "" } {
        set query_content [eval "::http::formatQuery $query_key_values"]
        lappend geturl_command -query $query_content
    }

    set token [eval $geturl_command]
    upvar #0 $token http_result
    
    regexp { (\d\d\d) } $http_result(http) full_match http_status
    #[string range $http_result(http) 0 2]
    log "http status: >>$http_status<<"
    set ::tclwebtest::http_status $http_status
    
    set ::tclwebtest::headers $http_result(meta)
    
    # check if we received a Set-Cookie header, add to cookies if
    # necessary
    foreach { header header_value } $::tclwebtest::headers {
        if { [string compare -nocase $header "set-cookie"] == 0 } {
            set_cookie $header_value
        }
    }
    
    set ::tclwebtest::body $http_result(body)
    set ::tclwebtest::body_without_comments [strip_html_comments $http_result(body)]
    set ::tclwebtest::text [translate_entities [util_striphtml $::tclwebtest::body_without_comments]]


    set failure_treatement "debug -lib $nocomplain_p
        if { !$nocomplain_p && [lsearch $nocomplain_list $http_status] == -1 } {
            assertion_failed \"do_request did not return a page. HTTP status is $http_status\"
        } else {
            log \"Bad http answer ignored due to -nocomplain\"
        }"

    set avoid_tidy_p 0
    # is it a redirect ?
    if { $http_status == "302" || $http_status == "301" || $http_status == "307" } {
        set avoid_tidy_p 1
        for { set i 0 } { $i < [llength $::tclwebtest::headers] } { incr i 2 } {
            if { [string match -nocase [lindex $::tclwebtest::headers $i] "location"] } {
                set location [translate_entities [string trim [lindex $::tclwebtest::headers [expr {$i+1}]]]]
                break
            }
        }
        if { $location eq "" } {
            # when location is null after redirection, get relative directory
            set location "./"
        }
        if { $http_status == "301" } {
            if { $nocomplain_p || [lsearch $nocomplain_list "301"] != -1 } {
                log "Attention! Redirection 301 was ignored, but please update your test unit, it's a bug!"
            } else {
                assertion_failed "Permanent redirection (301) are considered a test unit bug\nUse -nocomplain if needed."
            }
        }
        if {$noredirect_p} {
            # debugging
            log "ignoring redirect to: $location"
            set final_url $location
        } else {
            log "following a redirect to: $location"
            eval [build_do_request_retry redirect]
        }
    } elseif { [regexp -expanded -nocase $regexp_script_before_html $http_result(body) match location] } {
        # a very silly form of redirect, with a <script> thingy before
        # the <html>
        set location [translate_entities $location]
        if {$noredirect_p} {
            log "ignoring stupid redirection to: $location"
            set final_url $location
        } else {
            # a very silly form of redirect, with a <script> thingy before
            # the <html>
            log "stupid redirection to: $location"
            eval [build_do_request_retry redirect]
        }
    } elseif { $followequiv_p && [regexp -expanded -nocase $regexp_http_equiv_redirect $http_result(body) match delay location] } {
        # the http-equiv sort of redirect. ugh.
        set location [translate_entities $location]
        log "stupid redir after $delay secondes to: $location"

        # optionally we could take the delay into account
        if {$noredirect_p} {
            log "ignoring stupid redir after $delay seconds to: $location"
            set final_url $location
        } else {
            # the http-equiv sort of redirect. ugh.
            log "stupid redir after $delay seconds to: $location"

            # optionally we could take the delay into account
            eval [build_do_request_retry redirect]
        }
    } elseif { $http_status == "401" } {
        set authentication_request 0
        for { set i 0 } { $i < [llength $::tclwebtest::headers] } { incr i 2 } {
            if { [string match -nocase [lindex $::tclwebtest::headers $i] "www-authenticate"] } {
                set authentication_request 1
                break
            }
        }
        if { $authentication_request } {
            if { $already_tried_http_authorization } {
                # a second time means we failed the first one
                log "Incorrect password"
                eval $failure_treatement
            } else {
                set inject_string [match_http_url_authorization $url]
                if { $inject_string ne "" } {
                    set ::tclwebtest::http_auth_string $inject_string
                    log "Retrying url with preset authentication"
                    eval [build_do_request_retry httpauth]
                } else {
                    log "This url requires http authentication set through the http_auth command"
                    eval $failure_treatement
                }
            }
        } else {
            # oh, treat this like the usual failure
            eval $failure_treatement
        }
    } elseif { $http_status != "200" } {
        set avoid_tidy_p 1
        eval $failure_treatement
    }
    
    ::http::cleanup $token

    if { !$avoid_tidy_p } {
        maybe_tidy
    }

    return $final_url
}

::tclwebtest::ad_proc -private ::tclwebtest::build_do_request_retry {
    type
} {
    
    do_request is a really complex function with lots of
    switches. When do_request has to be retried with a slight
    modification in it's parameters, like changing the url to
    follow a redirection or retry with an http password, there is
    a lot of code to type for each instance of the retry. To avoid
    cluttering do_request <em>even more</em>, this function parses
    the arguments for the eval and returns them in a list.

    <p>

    The problem is that the eval command has to be built carefully
    with a list instead of a quoted string. Otherwise, if for example
    the redirection location contained a few semicolons, the eval
    command would parse the semicolon and split the string in two
    individual commands, which is not what we were looking for,
    because the semicolon was part of the new location.
    
    <p>

    There are basically two different do_request retries, which are
    chosen with the <b>type</b> parameter: redirect or httpauth. The
    former will use the variable <b>location</b> as url, the second
    will use the variable <b>url</b> as url, appending later the
    query's key values if there were any.
    
} {

    upvar followequiv_p followequiv_p nocomplain_p nocomplain_p \
        nocomplain_list nocomplain_list noredirect_p noredirect_p \
        url url location location query_key_values query_key_values

    set retry_command [list do_request]
    if { $followequiv_p } {
        lappend retry_command "-followequiv"
    }
    if { $nocomplain_p } {
        lappend retry_command "-nocomplain"
    }
    if { [llength $nocomplain_list] != 0 } {
        lappend retry_command $nocomplain_list
    }
    if { $noredirect_p } {
        lappend retry_command "-noredirect"
    }
    switch -- $type {
        redirect {
            lappend retry_command $location
        }
        httpauth {
            lappend retry_command "$url"
            if { $query_key_values ne "" } {
                lappend retry_command "$query_key_values"
            }
        }
        default {
            error "Shouldn't have reached this..."
        }
    }
    return $retry_command
}

::tclwebtest::ad_proc -private ::tclwebtest::match_http_url_authorization {
    url_prefix
} {

    Searches in the user/pass http auth cache for the given url prefix
    If found, returns the string to be injected as http header. Otherwise
    returns the empty string.
    
} {

    foreach { temp } $::tclwebtest::http_authentication {
        set url [lindex $temp 0]
        set inject [lindex $temp 1]
        if { [expr {[string first $url $url_prefix] == 0}] } {
            return $inject
        }
    }
    return ""
    
}

::tclwebtest::ad_proc -public ::tclwebtest::http_auth {
    url_prefix
    username
    password
} {

    Registers in an internal global variable the username and password
    which should be used for pages requiring basic http autorization and
    which match url_prefix. You can assign only one username and password
    per url_prefix, although you can have register multiple url prefixes
    if each matches a different directory. Matches are ordered in length
    and descending order.
    <p>
    <b>Note:</b> This function depends on the availability of the base64
    tcl package in your working environment. If it can not be sourced, a
    fake version of base64::encode will be used instead, which doesn't
    work notifies the fake use in the final log during execution of the
    test units.

    @param url_prefix the part of the url which has to match the
    following do_request commands in order to use http authentication.

    @param username the username you would use to authenticate. Only one
    username is allowed per url_prefix. If username is the empty string,
    the url_prefix will be unregistered.

    @param password the associated password for the combination of
    url_prefix and username.

} {

    if { $username eq "" } {
        # delete this url prefix
        set counter -1
        foreach { temp } $::tclwebtest::http_authentication {
            incr counter
            set url [lindex $temp 0]
            set inject [lindex $temp 1]
            if { [string match $url $url_prefix] } {
                lreplace $::tclwebtest::http_authentication $counter $counter
                return
            }
        }
    } else {
        # register url prefix after deleting previous instance
        http_auth $url_prefix "" ""
        lappend ::tclwebtest::http_authentication [list $url_prefix \
                                                       "Basic [$::tclwebtest::base64_encode $username:$password]"]
        set ::tclwebtest::http_authentication [lsort -decreasing \
                                                   $::tclwebtest::http_authentication]
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::fake_base64_encode {
    args
} {

    This function substitutes base64::encode when the package can't be
    imported. It doesn't do anything at all, only log a message that
    we are using a fake version, and returns a constant string.

} {

    log "HTTP authentication not available due to lack of base64 package."
    return "fake_base64_encode was used!"

}

# open a file and load it. (Url expected to be file://)
::tclwebtest::ad_proc -private ::tclwebtest::do_request_file url {
    set path [string range $url [string length "file://"] end]
    
    set file [open $path]
    set ::tclwebtest::body [read $file]
    close $file
    
    set ::tclwebtest::body_without_comments [strip_html_comments $::tclwebtest::body]
    set ::tclwebtest::text [util_striphtml $::tclwebtest::body]
    
    # TODO think about what variables else have to be set here

    maybe_tidy
}


::tclwebtest::ad_proc -private ::tclwebtest::require_https_support { } {

    Configures https support if not already done. Throws an error 
    when not possible (most likely due to missing tls library).

} {
    package require tls
    http::register https 443 ::tls::socket
}


::tclwebtest::ad_proc -private ::tclwebtest::maybe_tidy {} {

    Runs tidy on the current result page if the option TIDY is
    set. Output is sent to log_channel

} {
    variable TIDY

    if { $TIDY } {
        variable log_channel "stdout"
        # TODO check if tidy is available at all

        debug -lib "tidying"

        set ret_val "(nix)"
        global errorInfo errorCode
        set errorInfo ""
        log "--- TIDY START                  ---"
        if [catch {exec tidy -e -q << [response full] >&@ $log_channel}] {
            # Get the return value of the exec call
            if { [llength $errorCode] == 3 } {
                set ret_val [lindex $errorCode 2]
            } else {
                log "warning: there is some error in tclwebtests code, can't determine return value of tidy"
            }
        } else {
            # exec did not throw an error
            set ret_val 0
        }
        set url "URL: [response url]"
        switch $ret_val {
            0 { log "--- TIDY FINISH. NO COMPLAINTS. $url ---" }
            1 { log "--- TIDY FINISH. WARNINGS. $url ---" }
            2 { log "--- TIDY FINISH. ERRORS. $url ---" }
            default { log "--- TIDY FINISH. RETURNS: $ret_val. $url ---" }
        }
    }
}

::tclwebtest::ad_proc -public ::tclwebtest::response {
    command
} {

    @param command Specify one of the commands:
    <a href="#response_text">text</a>,
    <a href="#response_body">body</a>,
    <a href="#response_full">full</a>,
    <a href="#response_body_without_comments">body_without_comments</a>,
    <a href="#response_status">status</a>,
    <a href="#response_url">url</a>,
    <a href="#response_headers">headers</a>.
    
    <blockquote><dl>
    <dt><b><a name="response_text">text</a></b></dt>
    <dd>
    Returns the user viewable part of the response page.
    </dd>

    <dt><b><a name="response_body">body</a></b></dt>
    <dd>
    Returns the full html source of the response page.
    </dd>

    <dt><b><a name="response_full">full</a></b></dt>
    <dd>
    Same as body.
    </dd>

    <dt><b><a name="response_body_without_comments">body_without_comments</a></b></dt>
    <dd>
    Like <code>response body</code> but stripping html comments.
    </dd>

    <dt><b><a name="response_status">status</a></b></dt>
    <dd>
    Returns the http status code of the last response (e.g. 200, 304,
                                                       404, ...). Note that <code>do_request</code> must be told explicitely
    to not complain about error http codes, e.g. 404 and 500.
    </dd>

    <dt><b><a name="response_url">url</a></b></dt>
    <dd>
    Returns the current url.
    </dd>

    <dt><b><a name="response_headers">headers</a></b></dt>
    <dd>
    Returns the http headers that the server sent in a list of alternating key/value pairs, suitable for initializing an array with 'array set headers [response headers]'.
    </dd>
    
    </dl></blockquote>

} {

    switch $command {
        text { return $::tclwebtest::text }
        
        body { return $::tclwebtest::body }
        
        full { return $::tclwebtest::body }
        
        body_without_comments { return $::tclwebtest::body_without_comments }

        status { return $::tclwebtest::http_status }
        
        url { return $::tclwebtest::url }

        headers { return $::tclwebtest::headers }
        
        default {
            error "The response subcommand \"response $command\" does not exist."
        }
    }
}



::tclwebtest::ad_proc -private ::tclwebtest::absolute_link { url } {

    Prepend host and context if either one is missing, derived from
    previously called url's.

} {
    
    # For some reason this proc is called with the url as a list
    # element sometimes. Instead of investigating why I'll remove the
    # symptom here for now.
    set url [lindex $url 0]

    # TODO deal with this stuff: "../foo/bla"

    debug -lib "absolute_link called with url: $url, previous url was: $::tclwebtest::url"
    
    if { [string range $url 0 6] eq "http://" || [string range $url 0 6] eq "file://" || [string range $url 0 7] eq "https://" } {
        return $url
    } else {
        if { $::tclwebtest::url eq "" } {
            error "absolute_link was called with the relative link $url but no calls have been made before, so I don't know how to resolve it."
        }
        if { [string trim $url] eq "" } {
            # We got a href="" -> same url again
            return $::tclwebtest::url
            
        } elseif { [string range $url 0 1] eq "//" } {
            # append protocol
            regexp {(https?:).*} $::tclwebtest::url match protocol
            return "$protocol$url"
        } elseif { [string range $url 0 0] eq "/" } {
            # Absolute path - append just host
            regexp {(https?://[^/]+)} $::tclwebtest::url match host_part
            return "$host_part$url"
            
        } elseif {$url eq "."} {
            # The dot means go to the current dir
            return [current_dir_url $::tclwebtest::url]
        } else {
            # Relative url - prepend current dir
            return "[current_dir_url $::tclwebtest::url]/$url"
        }
    }
}

::tclwebtest::ad_proc -private ::tclwebtest::current_dir_url { url } {
    Return the URL (without trailing slash) of the directory on the server of the given URL.
    Here are some examples:

    Last requested URL                                                   Proc returns
    http://peter.cph02.collaboraid.net                                   http://peter.cph02.collaboraid.net
    http://peter.cph02.collaboraid.net/                                  http://peter.cph02.collaboraid.net
    http://peter.cph02.collaboraid.net/simulation/                       http://peter.cph02.collaboraid.net/simulation
    http://peter.cph02.collaboraid.net/simulation?object_id=532          http://peter.cph02.collaboraid.net
    http://peter.cph02.collaboraid.net/simulation/index?object_id=423    http://peter.cph02.collaboraid.net/simulation
    
    @author Peter Marklund
} {        
    # Remove any query string
    if { [regexp {\?} $url] } {
        # URL has a question mark, get everything before it
        regexp {^([^?]+?)\?.*$} $url match current_dir_url            
    } else {
        # No question mark in URL
        set current_dir_url $url
    }

    if { [string range $current_dir_url end end] ne "/" } {
        # Last component of the path does not seem to be a directory - remove it
        # unless all we have is the domain
        if { [regexp {[^/]/[^/]} $current_dir_url] } {
            # We are in a subdirecory under root, or on a page directly under root
            # Strip off the page to get the directory
            regexp {^(.+)/+[^/]+$} $current_dir_url match current_dir_url
        }
    } else {
        # We are dealing with a directory, just strip of the trailing slash
        set current_dir_url [string trimright $current_dir_url "/"]
    }

    return $current_dir_url
}

::tclwebtest::ad_proc -private ::tclwebtest::post_process_url {
    url
} {

    Do some url cleanup, like substitution of '/./', '/..',
    etc. Before any path cleanup is done, separate any GET parameters
    from it searching for a `?' character. Otherwise, additional
    valid URLs passed as GET parameters could be incorrectly mangled.

} {
    
    # first translate html entities in url
    set url [translate_entities $url]

    # detect any GET parameters, and if yes, save them.
    set split_index [string first ? $url]
    if { $split_index != -1 } {
        set get_parameters [string range $url $split_index end]
        set url [string range $url 0 [expr {$split_index - 1}]]
    }

    # substitute /././
    regsub -all {/(\./)*(\.$)?} $url "/" url
    if { [regexp {([^:]+)://([^/]+)(.*)} $url match protocol domain path] } {
        if { $match ne "" } {
            # substitute 'folder/..'
            while { [regsub {/[^/]+(/\.\.(/|$))} $path "/" path] } { }
            # substitute '/////'
            regsub -all {//+} $path "/" path
            set url "$protocol://$domain$path"
        }
    }

    # if there were get_parameters, return them concatenated
    if { $split_index == -1 } {
        return $url
    } else {
        return "${url}${get_parameters}"
    }
}


::tclwebtest::ad_proc -private ::tclwebtest::extract_links_if_necessary { } {
    Extract all links from the body of this sessions request.
} {
    
    if {$::tclwebtest::links_extracted_p} {
        return
    }

    debug -lib "extracting links"
    
    set ::tclwebtest::links [list]
    
    set html_to_search $::tclwebtest::body_without_comments
    
    while { [regexp -nocase -indices {<a[^>]*href[^>]*>([^<]|<[^/]|</[^a])*</a>} $html_to_search match_html match_url] } {
        
        
        catch { unset a_link }
        array set a_link [list]
        
        set a_link(start_idx)  [lindex $match_html 0]
        set a_link(stop_idx)  [lindex $match_html 1]
        
        set a_link(full) [string range $html_to_search $a_link(start_idx) $a_link(stop_idx)]
        set a_link(url) [get_attribute $a_link(full) href]
        
        # this is way too simple
        regexp -nocase {>(.*)<} $a_link(full) match a_link(content)
        set a_link(content) [util_remove_html_tags [normalize_html $a_link(content)]]
        
        lappend ::tclwebtest::links [array get a_link]
        
        set html_to_search [string range $html_to_search [expr {[lindex $match_html 1]+1}] end]
    }
    
    set ::tclwebtest::current_link -1
    set ::tclwebtest::links_extracted_p 1
}


::tclwebtest::ad_proc -private ::tclwebtest::extract_forms_if_necessary { } {

} {
    
    if {$::tclwebtest::forms_extracted_p} {
        return
    }
    
    # We misuse this var here by incrementing it for each new form, to
    # inform deal_with_field about the current form. After parsing we
    # set it to 0, or -1 if no forms are present.
    set ::tclwebtest::current_form -1
    set ::tclwebtest::current_field -1
    set ::tclwebtest::field_modified_p 0
    
    set ::tclwebtest::forms [list]
    
    set body $::tclwebtest::body_without_comments
    
    set start_idx 0
    
    # note: had a weird error when using: {<form[^>]*>.*?</form>}, for
    # whatever reason.
    while { [regexp -expanded -indices -nocase {<form[^>]*?>.*?</form>} [string range $body $start_idx end] form_match] } {
        
        catch { unset a_form }
        array set a_form [list]
        
        # get this form's full html blurb 
        set a_form(full) [string range $body \
                              [expr {$start_idx + [lindex $form_match 0]}] \
                              [expr {$start_idx + [lindex $form_match 1]}] \
                             ]
        
        incr ::tclwebtest::current_form
        
        regexp -nocase {<form[^>]*>} $a_form(full) form_tag 
        #puts "WOOOOOPS: found a form_tag: $form_tag"
        
        # get the action url
        set a_form(action) [get_attribute $form_tag action]
        
        # get the method, default is get
        set a_form(method) [get_attribute $form_tag method "get"]
        set a_form(enctype) [get_attribute $form_tag enctype ""]
        
        set a_form(name) [get_attribute $form_tag name]
        append a_form(name) [get_attribute $form_tag id]
        set a_form(id) [get_attribute $form_tag id]

        # get the content - everything that is inside the form but not
        # in html tags
        set a_form(content) [util_striphtml $a_form(full)]
        set a_form(fields) [list]
        
        # append the harvested form, deal_with_field does the rest
        lappend ::tclwebtest::forms [array get a_form]
        
        # get all fields of this form
        set start_field_idx 0
        
        while { [regexp -expanded -indices -nocase {<input[^>]*?>|<option[^>]*?>|<textarea[^>]*?>((?!</textarea>).)*</textarea>|<select[^>]*?>((?!</select>).)*</select>} [string range $a_form(full) $start_field_idx end] field_match] } {
            
            set abs_start [expr {$start_idx + [lindex $form_match 0] + \
                               $start_field_idx + [lindex $field_match 0]}]
            
            set abs_end [expr {$start_idx + [lindex $form_match 0] + \
                             $start_field_idx + [lindex $field_match 1]}]
            
            
            
            # yakk
            deal_with_field $abs_start $abs_end
            
            set start_field_idx [expr {$start_field_idx + [lindex $field_match 1] + 1}]
        }
        
        
        set start_idx [expr {$start_idx + [lindex $form_match 1] + 1}]
    }
    
    set ::tclwebtest::forms_extracted_p 1
    
    if { [llength $::tclwebtest::forms] == 0 } {
        set ::tclwebtest::current_form -1
        set ::tclwebtest::current_field -1
    } else {
        set ::tclwebtest::current_form 0
        set ::tclwebtest::current_field 0
    }
}


::tclwebtest::ad_proc -private ::tclwebtest::deal_with_field { start_idx stop_idx } {
    Parse a field that is supposed to be on the specified position in
    the body. Add it to the fields list of the current_form - or modify
    the fields list if it is a radiobutton.
} {    
    catch { unset a_result }
    array set a_result [list]
    
    set full [string range $::tclwebtest::body_without_comments $start_idx $stop_idx]
    
    set a_result(full) $full
    set a_result(start_idx) $start_idx
    set a_result(stop_idx) $stop_idx
    set append_p 1
    
    array set a_form [lindex $::tclwebtest::forms $::tclwebtest::current_form]
    set fields $a_form(fields)
    
    if { [regexp -nocase {<input} $full] } {
        # an input field
        set a_result(type) [string tolower [get_attribute $full type "text"]]
        set type $a_result(type)
        set a_result(name) [get_attribute $full name]
        set a_result(value) [get_attribute $full value]
        set a_result(id) [get_attribute $full id]
        
        if { $type eq "text" || $type eq "hidden" || 
             $type eq "password" || $type eq "password" || $type eq "file" } {
            
            set a_result(caption) [parse_caption_before $start_idx]
            
        } elseif { $type eq "submit" } {
            
            
        } elseif { $type eq "checkbox" } {
            
            # TODO: The regex below produces trouble when the word
            # "checked" occurs in some javascript inside the tag
            # (e.g. in an onClick thingy). Some cleaner html parsing
            # capabilities would do this program good ...
            if { [regexp -nocase {<input[^>]* checked[^>]*>} $full] } {
                set a_result(value) [get_attribute $full value]
            } else {
                set a_result(value) ""
            }

            set a_result(caption) [parse_caption_after $stop_idx]
            set a_result(choices) [list "" [get_attribute $full value]]
            
        } elseif { $type eq "radio" } {
            
            # See if we have already a field of type radio
            # button with that name
            set name [get_attribute $full name]
            set value [get_attribute $a_result(full) value]           
            set id [get_attribute $a_result(full) id]           
            set caption [parse_caption_after $stop_idx]
            
            set found_idx [find_in_array_list -index $fields { ~n name } $name]
            
            if { $found_idx > -1 } {
                # This radiobutton is already here - add its value to
                # the existing choices.
                
                array set a_radio [lindex $fields $found_idx]
                lappend a_radio(choices) [list $value $caption $id]
                lappend a_radio(choices2) [list value $value caption $caption id $id index [expr {[llength $a_radio(choices2)]+1}]]
                
                if { [regexp -nocase "<input.*checked.*>" $full] } {
                    set a_radio(value) $value
                }
                
                # replace the new field with the old one
                set fields [lreplace $fields $found_idx $found_idx [array get a_radio]]
                set a_form(fields) $fields
                set ::tclwebtest::forms [lreplace $::tclwebtest::forms $::tclwebtest::current_form $::tclwebtest::current_form [array get a_form]]
                
                set append_p 0
                
            } else {
                # First occurence of this radio button
                set a_result(caption) [parse_caption_before $start_idx]
                if { [regexp -nocase "<input.*checked.*>" $full] } {
                    set a_result(value) [get_attribute $a_result(full) value]
                } else {
                    set a_result(value) ""
                }
                lappend a_result(choices) [list [get_attribute $a_result(full) value] $caption $id]
                lappend a_result(choices2) [list value [get_attribute $a_result(full) value] caption $caption id [get_attribute $a_result(full) id] index 1]
            }
        } elseif { $type eq "reset" } {
            log "Notice: there is no reason in the world to use a <input type=\"reset\"> field, yet this page does."
        } else {
            log "Notice: unimplemented input type: `$type'"
        }
        
    } elseif { [regexp -nocase -expanded {(<textarea[^>]*>)(.*?)</textarea>} $full bogus_match first_tag value] } {
        # a textarea
        set a_result(full) $full
        set a_result(type) textarea
        set a_result(name) [get_attribute $first_tag name]
        set a_result(value) $value
        set a_result(caption) [parse_caption_before $start_idx]
        
    } elseif { [regexp -nocase -expanded {(<select[^>]*>)(.*?)</select>} $full bogus_match first_tag body] } {
        # a select
        set a_result(full) $full
        set a_result(type) select
        set a_result(name) [get_attribute $first_tag name]
        set a_result(value) [list]
        set a_result(id) [get_attribute $first_tag id]
        set a_result(caption) [parse_caption_before $start_idx]
        
        # does this list allow multiple selections? TODO should not be
        # true if just the name attribute contains the word multiple
        set a_result(multiple_p) [expr {[string first "multiple" $first_tag] > -1}]
        
        # find all <option>... portions of the field, and stuff it
        # into the choices list. 

        # TODO at least mozilla seems to select the first option by
        # default, if the select is not multiple and no other option
        # is selected, this proc should do the same.
        set to_search $body
        set first_p 1
        while { [regexp -nocase {\s*(<option[^>]*?>.*?)\s*((<option[^>]*>|</option>|</select>).*?)?$} $to_search bogus_match full_option remaining] } {
            
            regexp -nocase {(<option[^>]*>)\s*(.*)$} $full_option bogus_match tag ch_caption
            
            
            # This is different wether value="" is given or nothing at
            # all. So there is this extremely_very ... kludge. TODO
            # should fix get_attribute to take a switch for that.
            set ch_value [get_attribute $tag value "extremely_veryunlikely_defaultname_01234567890333333"]
            debug -lib "SELECT ATT: $ch_value"
            if { $ch_value eq "" } {
                set ch_value ""
            } elseif { $ch_value ==  "extremely_veryunlikely_defaultname_01234567890333333" } {
                # The value attribute is not set in the option tag, so
                # the value becomes the text that is included in the
                # tag body.
                set ch_value $ch_caption
            }
            
            lappend a_result(choices) [list $ch_value $ch_caption]
            
            # TODO this is not a perfect regexp
            if { [regexp -nocase "selected" $tag] } {
                if {$a_result(multiple_p)} {
                    lappend a_result(value) $ch_value
                } else {
                    set a_result(value) [list $ch_value]
                }
            }

            if { $first_p && !$a_result(multiple_p) } {
                # In single selects the first one is selected per
                # default
                set a_result(value) [list $ch_value]
                set first_p 0
            }
            
            set to_search $remaining
            set remaining ""
        }
        
    } else {
        error "cannot deal with this field: $full"
    }
    
    # TODO. to ensure all expected array fields are set
    if {![info exists a_result(caption)]} {
        set a_result(caption) ""
    }
    
    # append this field to the current form
    if { $append_p } {
        set a_result(index) [llength $fields]

        set a_result(value) [translate_entities $a_result(value)]
        lappend fields [array get a_result]
        set a_form(fields) $fields
        set ::tclwebtest::forms [lreplace $::tclwebtest::forms $::tclwebtest::current_form $::tclwebtest::current_form [array get a_form]]
    }
    
} ;# end of deal_with_field



::tclwebtest::ad_proc -private ::tclwebtest::parse_caption_before position {
    Try to find a field's possible caption by scanning the text before
    it.
} {
    set body $::tclwebtest::body_without_comments
    
    if { [string index $body $position] != "<" } {
        error "parse_caption_before called, but position ($position) does not point to a <, but to [string index $body $position]"
    }
    
    if { $position < 4 } {
        error "parse_caption_before called with a position of $position - i consider this insane and refuse further processing."
    }
    
    debug -lib "parse_caption_before $position"

    set string [string range $body 0 $position]
    set last_1 [string last <tr $string]
    set last_2 [string last <TR $string]
    set last [expr {$last_1 > $last_2 ? $last_1 : $last_2}]
    if {$last > -1} {
        set string [string range $string $last end-1]
        regsub -all -nocase {<[/]?t[dr][^>]*>} $string "" string
        while {[regexp -nocase {<br>(.*)$} $string _ string]} {}
        return [string trim [normalize_html $string]]
    } else {

        # Not inside a table. Simply return everything from the left
        # of the <input> tag backwards till the first >.

        if [regexp {.*>\s*([^<]*?)\s*<$} $string nada match] {
            return [normalize_html $match]
        } else {
            return "not inside"
        }
    }

}

::tclwebtest::ad_proc -private ::tclwebtest::parse_caption_after position {
    Similar purpose to above, but simply parses till the first html element.
} {
    
    if { [string index $::tclwebtest::body_without_comments $position] != ">" } {
        error "parse_caption_after called, but position ($position) does not point to a >, but to [string index $::tclwebtest::body_without_comments $position]"
    }
    
    set position [expr {$position + 1}]
    
    if ![regexp {\s*([^<]+?)\s*<} [string range $::tclwebtest::body_without_comments $position end] match caption] {
        return ""
    }
    return [normalize_html $caption]
}


::tclwebtest::ad_proc -private ::tclwebtest::find_in_array_list {
    -index:boolean
    -return_matches:boolean
    array_list
    modifier_key_list
    expression
} {
    A wrapper around regexp that adds some functionality inspired by the
    limit function in the mutt mailclient: args can be more then one
    element and each will be interpreted as regexp against which string
    will be tested. Several lists with searchable content can be passed
    to this proc, and by default the first one will be searched. If an
    arg starts with ~ then the following character will identify which
    list to search. 

    TODO add example

    If an element of args is a single ! then the following regexp (with
                                                                   optional ~x) must not match.

    Always -nocase. Maybe it should be extended to be case sensitive
    when there is at least one upper case in the expression.

    @param return_matches if this is set to true, instead of stopping
    with the first match, the function will continue accumulating more
    matches and will return them in a list. Used with <b>index</b> will
    return a list of indices.

} {    
    array set a_keys $modifier_key_list
    # set the default case when nothing is found
    if { $return_matches_p } {
        set return_matches_list [list]
    } else {
        set return_matches_list ""
    }
    
    # The first key is the default
    set default_key [lindex $modifier_key_list 1]
    
    set idx -1
    foreach item $array_list {
        incr idx
        
        catch { unset a_item }
        array set a_item $item
        
        set key_to_search $default_key
        set not ""
        set found_p 0
        foreach subex $expression {
            
            # is it NOT?
            if { $subex == "!" } {
                set not "!"
                continue
            }
            
            # is it a modifier?
            if { [regexp {~.} $subex] } {
                if { ![info exists a_keys($subex)] } {
                    error "\"$subex\" is not a valid modifier. I got this modifier_key_list: $modifier_key_list"
                }
                set key_to_search $a_keys($subex)
                continue
            }
            
            set found_p 1
            
            
            # it is an expression - test the element at the current
            # index
            set element $a_item($key_to_search)
            
            # don't use -expanded! Had a weird error when " " did not
            # match anymore (maybe I have to read the re_syntax man
            # pages) like [regexp -expanded {adresse andern}
            # {Lieferadresse andern} nada] returns 0. Hmm.
            if $not[regexp -nocase $subex $element] {
                # matches, on with the inner loop

                # but before that, we reset the active modifier to the
                # default
                set key_to_search $default_key
                continue
            } else {
                # does not match, stop the inner loop
                set found_p 0
                break
            }
            
            # reset the key for the next subex
            set key_to_search $default_key
        }
        
        if {$found_p} {
            if { $index_p } {
                if { $return_matches_p } {
                    lappend return_matches_list $idx
                } else {
                    return $idx
                }
            } else {
                if { $return_matches_p } {
                    lappend return_matches_list $item
                } else {
                    return $item
                }
            }
        }
    }
    
    # either looped through all list items and didn't find matches, or
    # caller asked for a list of matches we accumulated
    return $return_matches_list
}


::tclwebtest::ad_proc -public ::tclwebtest::regsplit { rex string } {

    Utility proc to split the given string into elements that are matched by the first
    parentheses pair in the regular expression and returns a list of all
    matches.

} {
    set result [list]

    while { [regexp -indices -nocase $rex $string bogus_match match] } {
        set first [lindex $match 0]
        set last [lindex $match 1]

        lappend result [string range $string $first $last]
        
        set string [string range $string $last end]
    }

    return $result
}


::tclwebtest::ad_proc -public ::tclwebtest::known_bug {
    { -abort:boolean 0}
} {

    There should be something like this that can be wrapped around
    some asserts like this:

    <blockquote><pre>
    assert bla    # still good
    known_bug {
        assert bli
        assert blu
    }
    </pre></blockquote>

    which would mean bli and blu are known bugs. This proc could then
    include the wrapped code in some reporting.

    <p>

    It should also support aborting the whole test, so it can be put in
    the beginning of a test file (makes sense when several test files
                                  are run at once)
    
} {
    if { $abort } {
        error "known bug" "known bug" { NONE }
    }
}



::tclwebtest::ad_proc -private ::tclwebtest::get_attribute { string att_name { default_value "" } } {

    Extracts the value of the named attribute out of the given html
    fragment. E.g. the url of href="..."

} {
    if { [regexp -expanded -nocase "$att_name=\"(.*?)\"" $string match att_value] } {
    } elseif { [regexp -expanded -nocase "$att_name='(\[^>\]*?)'" $string match att_value] } {
    } elseif { [regexp -expanded -nocase "$att_name=(\[^ >\]*)(>| )" $string match att_value] } {
    } else {
        debug -lib "get_attribute: no attribute by that name: $att_name in $string"
        return $default_value
    }
    
    return $att_value

}


::tclwebtest::ad_proc -private ::tclwebtest::code_lines { filename linenumber } {

    loads a file an returns a few lines up to and including the
    linenumber

} {
    set STACKTRACE_LENGTH 5

    set result ""

    set file [open $filename r]
    for { set i 1 } { $i <= $linenumber } { incr i } {
        if { ![gets $file line] == -1 } {
            break
        }

        if { [expr {$linenumber - $i}] < $STACKTRACE_LENGTH } {
            append result "$line\n"
        }
    }
    close $file
    return $result
}


::tclwebtest::ad_proc -private ::tclwebtest::memory_lines { memory_string line_number } {

    Similar in spirit to code_lines, chops memory_string until it
    is reduced to a few lines, up to and including the line_number,
    then the chopped version is returned.

} {

    set STACKTRACE_LENGTH 5

    # first chop from beginning until we have at most $STACTRACE_LENGT lines
    while { [expr {$line_number > $STACKTRACE_LENGTH}] } {
        set index [string first "\n" $memory_string]
        set memory_string [string replace $memory_string 0 $index]
        incr line_number -1
    }

    # now find $line_number "\n" characters
    set index 0
    set last [string length $memory_string]
    while { [expr {$line_number > 0}] && [expr {$index < $last}] } {
        if { [string index $memory_string $index] eq "\n" } {
            incr line_number -1
        }
        incr index
    }
    # see if the loop ended because we ran out of the string or not
    if { [expr {$index < $last }] } {
        incr index -2
    }
    # chop up to the last \n character we wanted or end of string
    set memory_string [string range $memory_string 0 $index]

    return "\t... SOURCE CODE ...\n$memory_string\n\t^^^^^ ERROR ^^^^^"

}


::tclwebtest::ad_proc -private ::tclwebtest::normalize_html html {

    Yet another html-mangling proc. This one calls translate_entities
    and replaces all multiple occurences of whitespace with a single
    space. Thus it returns proper strings for text that e.g. spans
    several lines in the html source.

} {
    set html [translate_entities $html]
    regsub -all {([[:space:]]+)} $html { } html
    return $html
}

# the following three procs are ripped from and therefore (C)
# arsdigita

# Returns a best-guess plain text version of an HTML fragment.  Better
# than ns_striphtml because it doesn't replace & g t ; and & l t ;
# with empty string.
::tclwebtest::ad_proc -private ::tclwebtest::util_striphtml {html} {

} {
    return [util_expand_entities [util_remove_html_tags $html]]
}

::tclwebtest::ad_proc -private ::tclwebtest::util_remove_html_tags {html} {

} {
    regsub -all {<[^>]*>} $html {} html

    # also remove all occurences of multiple linefeeds, just because
    # it looks better when debugging (e.g. by calling debug [response
    # text])
    regsub -all {\n(\s*)\n(\s*)\n+} $html "\n\n" html

    return $html
}


::tclwebtest::ad_proc -private ::tclwebtest::strip_html_comments { html } {

} {
    regsub -all {<!--.*?-->} $html {} html
    return $html
}


::tclwebtest::ad_proc -private ::tclwebtest::count_lines {
    msg
} {

    Given a string, returns 1 + the number of line endings the string has.

} {

    set num 1
    while { [set index [string first "\n" $msg]] >= 0 } {
        incr num
        set msg [string replace $msg 0 $index]
    }
    return $num

}

::tclwebtest::ad_proc -private ::tclwebtest::run_test {
    -in_memory:boolean
    {-config_file ""}
    file_name 
} {
    Source the given file (must be a filename, not a directory). Return
    0 when successful, 1 when the test failed. Output is done via the
    log command, so it goes to wherever log_channel points to.

    @param in_memory If this switch is used, both <b>config_file</b>
    and <b>file_name</b> will be treated as strings which already
    contain the contents of the configuration and the script to run.
    Additionally, <code>::tclwebtest::log_channel</code> will be treated
    like a normal string instead of a file, and logs will be appended
    to it.
} {
    set start_time [clock seconds]

    if { $in_memory_p } {
        variable in_memory
        variable log_channel
        set in_memory 1
        set log_channel ""
        
        ::tclwebtest::log "\n----- START: in_memory string at \[[clock format $start_time -format "%d/%b/%Y:%H:%M:%S"]\] -----"
        reset_session

        set to_eval "$config_file
            $file_name"

        set memory_code "$file_name"
        set file_name "in_memory string"

        set res [evaluate_memory_string -log_end -in_memory $to_eval $start_time $file_name $config_file $memory_code]
    } else {
        ::tclwebtest::log "\n----- START: $file_name at \[[clock format $start_time -format "%d/%b/%Y:%H:%M:%S"]\] -----"
        reset_session

        if { $config_file ne "" } {
            set config_eval "source $config_file"
        } else {
            set config_eval ""
        }

        set to_eval "set TESTHOME [file dirname $file_name]
            $config_eval
            source $file_name"

        set res [evaluate_memory_string -log_end $to_eval $start_time $file_name $config_file ""]
    }

    if { $in_memory_p != 0} {
        catch { flush $::tclwebtest::log_channel }
    }

    return $res
}



::tclwebtest::ad_proc -private ::tclwebtest::evaluate_memory_string {
    {-in_memory:boolean 0}
    {-log_end:boolean 0}
    {-uplevel 0}
    to_eval
    start_time
    file_name
    config_file
    memory_code
} {

    Evaluates the given string and logs success or failure. Returns
    zero and 1 respectively.

    @param in_memory special mode which makes a difference for logging
    of error messages

    @param start_time clock seconds before calling this function

    @param to_eval code to evaluate, which is content of config_file
    plus contents of file_name.

    @param file_name name of the file which contains the code to
    evaluate, can be anything with when using <b>-in_memory</b>.

    @param config_file configuration code

    @param memory_code like to_eval but without config_file.

} {
    global errorInfo

    if {[catch { uplevel $uplevel $to_eval }]} {

        if { [string first "known bug" $errorInfo] == 0 } {
            ::tclwebtest::log "known bug"
            # TODO needs something else the failed

        } else {
            # not a known bug

            if {[regexp {(.*)\n--- end of assertionMsg ---\n} $errorInfo match assertionMsg]} {
                ::tclwebtest::log "\n$assertionMsg"
            } else {
                # for whatever reason there is no assertionMsg, so just
                # append the stacktrace
                ::tclwebtest::log "\n$errorInfo"
            }
            
            # find the test file's line number in the stack trace
            if { $in_memory_p } {
                if { [regexp ".+\\(\"eval\" body line (\\d+)\\)" $errorInfo match line] } {
                    set line [expr {$line - [::tclwebtest::count_lines "$config_file"]}]
                    ::tclwebtest::log "in script body line $line"
                    ::tclwebtest::log [::tclwebtest::memory_lines $memory_code $line]
                }
            } else {
                if { [regexp "\\(file \"$file_name\" line (\\d+)\\)" $errorInfo match line] } {
                    ::tclwebtest::log "in \"$file_name\" line $line:"
                    ::tclwebtest::log [::tclwebtest::code_lines $file_name $line]
                }
            }
        }
        set ret 1
        set end_log_message " FAILED"
    } else {
        set ret 0
        set end_log_message "SUCCESS"
    }
    
    if { $in_memory_p != 0} {
        catch { flush $::tclwebtest::log_channel }
    }
    if {$log_end_p} {
        ::tclwebtest::log "----- $end_log_message: $file_name (took [expr {[clock seconds] - $start_time}]s)               -----\n"
    }
    return $ret
}



# Grouped here because of the confusing effect of regexes on 
# the font-locking of emacs :-(.

::tclwebtest::ad_proc -private ::tclwebtest::util_expand_entities {html} {

} {
    regsub -all {&lt;} $html {<} html
    regsub -all {&gt;} $html {>} html
    regsub -all {&quot;} $html {"} html
    regsub -all {&amp;} $html {\&} html
    return $html
}

namespace eval ::tclwebtest:: {
    # TODO deal with value="Bla bla"
    variable regexp_form_action {<form[^>]+?action="?([^> "]+).*</form>}
    variable regexp_form_method {<form[^>]+?method="?([^> "]+).*</form>}
    variable regexp_input_name {<input[^>]+name="?([^" >]+)"?[^>]*>}
    variable regexp_input_value {<input[^>]+value="?([^" >]+)"?[^>]+>}
    variable regexp_script_before_html {<script\s*>\s*document.location.href\s*=\s*"?'?([^"'< ]+)"?'?\s*</script>}
                                                                                        # TODO should consider that this is inside a comment
    variable regexp_http_equiv_redirect {<meta\s+http-equiv\s*=\s*"?refresh"?\s*content="?(\d)+;url=([^">]+)"?\s*/?>}
}
###############################################################################
###############################################################################
#                               entity_lib.tcl
###############################################################################
###############################################################################
# In this file are implemented the procedures used to parse Html file links.
###############################################################################
###############################################################################
# Copyright 2000 Andrés García García  -- fandom@retemail.es
# Distributed under the terms of the GPL v2
###############################################################################
###############################################################################

# ripped from Getleft-0.10.6 by tils

###############################################################################
# SetEntities
#    Initializes the arrays with the translation for Html entities, something
#    like 'entity(lt)==>'
###############################################################################

package provide tclwebtest 1.0

namespace eval ::tclwebtest:: {

set entities(quot)      \"
set entities(amp)       \\&
set entities(lt)        <
set entities(gt)        >
set entities(nbsp)      { }
set entities(iexcl)     ¡
set entities(cent)      ¢
set entities(pound)     £
set entities(curren)    ¤
set entities(yen)       ¥
set entities(brvbar)    \|
set entities(sect)      §
set entities(uml)       ¨
set entities(copy)      ©
set entities(ordf)      ª
set entities(laquo)     «
set entities(not)       ¬
set entities(shy)       ­
set entities(reg)       ®
set entities(macr)      ¯
set entities(deg)       °
set entities(plusmn)    ±
set entities(sup2)      ²
set entities(sup3)      ³
set entities(acute)     ´
set entities(micro)     µ
set entities(para)      ¶
set entities(middot)    ·
set entities(cedil)     ¸
set entities(sup1)      ¹
set entities(ordm)      º
set entities(raquo)     »
set entities(frac14)    ¼
set entities(frac12)    ½

set entities(frac34)    ¾
set entities(iquest)    ¿
set entities(ntilde)    ñ
set entities(Agrave)    À
set entities(Aacute)    Á
set entities(Acirc)     Â
set entities(Atilde)    Ã
set entities(Auml)      Ä
set entities(Aring)     Å
set entities(AElig)     Æ
set entities(Ccedil)    Ç
set entities(Egrave)    È
set entities(Eacute)    É
set entities(Ecirc)     Ê
set entities(Euml)      Ë
set entities(Igrave)    Ì
set entities(Iacute)    Í
set entities(Icirc)     Î
set entities(Iuml)      Ï
set entities(ETH)       Ð
set entities(Ntilde)    Ñ
set entities(Ograve)    Ò
set entities(Oacute)    Ó
set entities(Ocirc)     Ô
set entities(Otilde)    Õ
set entities(Ouml)      Ö
set entities(times)     ×
set entities(Oslash)    Ø
set entities(Ugrave)    Ù
set entities(Uacute)    Ú
set entities(Ucirc)     Û
set entities(Uuml)      Ü
set entities(Yacute)    Ý
set entities(THORN)     Þ
set entities(szlig)     ß
set entities(agrave)    à
set entities(aacute)    á
set entities(acirc)     â
set entities(atilde)    ã
set entities(auml)      ä
set entities(aring)     å
set entities(aelig)     æ
set entities(ccedil)    ç
set entities(egrave)    è
set entities(eacute)    é
set entities(ecirc)     ê
set entities(euml)      ë
set entities(igrave)    ì
set entities(iacute)    í
set entities(icirc)     î
set entities(iuml)      ï
set entities(eth)       ð
set entities(ntilde)    ñ
set entities(ograve)    ò
set entities(oacute)    ó
set entities(ocirc)     ô
set entities(otilde)    õ
set entities(ouml)      ö
set entities(divide)    ÷
set entities(oslash)    ø
set entities(ugrave)    ù
set entities(uacute)    ú
set entities(ucirc)     û
set entities(uuml)      ü
set entities(yacute)    ý
set entities(thorn)     þ
set entities(yuml)      ÿ

}


::tclwebtest::ad_proc -public ::tclwebtest::translate_entities {
    string
} {

    Given a link or a link description, this procecedure subtitutes the
    Html character entities for the real thing, for example
    <b>&amp;amp;</b> gets changed to <b>&amp;</b>.

    @param string The string to process.

    @return The string processed.
    
} {
    variable entities

    while {[regexp {(?:&)([^ ;]+)(;)?} $string old entity]} {
        regsub {#} $entity {} entity
        # Eventually this should be replaced with "string is number"

        # added support for entities in the form &#039;  -til
        if {[regexp {^0*([1-9]+)$} $entity nada entity]} {
            set new [format %c $entity]
            regsub -all {([\\])} $new {\\\1} new
        } else {
            if {[catch {set ::tclwebtest::entities($entity)} new]} {
                break
            }
        }
        regsub -all $old $string $new string
    }
    return $string
}

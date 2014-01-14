###############################################################################
###############################################################################
#                               entity_lib.tcl
###############################################################################
###############################################################################
# In this file are implemented the procedures used to parse Html file links.
###############################################################################
###############################################################################
# Copyright 2000 Andr�s Garc�a Garc�a  -- fandom@retemail.es
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
set entities(iexcl)     �
set entities(cent)      �
set entities(pound)     �
set entities(curren)    �
set entities(yen)       �
set entities(brvbar)    \|
set entities(sect)      �
set entities(uml)       �
set entities(copy)      �
set entities(ordf)      �
set entities(laquo)     �
set entities(not)       �
set entities(shy)       �
set entities(reg)       �
set entities(macr)      �
set entities(deg)       �
set entities(plusmn)    �
set entities(sup2)      �
set entities(sup3)      �
set entities(acute)     �
set entities(micro)     �
set entities(para)      �
set entities(middot)    �
set entities(cedil)     �
set entities(sup1)      �
set entities(ordm)      �
set entities(raquo)     �
set entities(frac14)    �
set entities(frac12)    �

set entities(frac34)    �
set entities(iquest)    �
set entities(ntilde)    �
set entities(Agrave)    �
set entities(Aacute)    �
set entities(Acirc)     �
set entities(Atilde)    �
set entities(Auml)      �
set entities(Aring)     �
set entities(AElig)     �
set entities(Ccedil)    �
set entities(Egrave)    �
set entities(Eacute)    �
set entities(Ecirc)     �
set entities(Euml)      �
set entities(Igrave)    �
set entities(Iacute)    �
set entities(Icirc)     �
set entities(Iuml)      �
set entities(ETH)       �
set entities(Ntilde)    �
set entities(Ograve)    �
set entities(Oacute)    �
set entities(Ocirc)     �
set entities(Otilde)    �
set entities(Ouml)      �
set entities(times)     �
set entities(Oslash)    �
set entities(Ugrave)    �
set entities(Uacute)    �
set entities(Ucirc)     �
set entities(Uuml)      �
set entities(Yacute)    �
set entities(THORN)     �
set entities(szlig)     �
set entities(agrave)    �
set entities(aacute)    �
set entities(acirc)     �
set entities(atilde)    �
set entities(auml)      �
set entities(aring)     �
set entities(aelig)     �
set entities(ccedil)    �
set entities(egrave)    �
set entities(eacute)    �
set entities(ecirc)     �
set entities(euml)      �
set entities(igrave)    �
set entities(iacute)    �
set entities(icirc)     �
set entities(iuml)      �
set entities(eth)       �
set entities(ntilde)    �
set entities(ograve)    �
set entities(oacute)    �
set entities(ocirc)     �
set entities(otilde)    �
set entities(ouml)      �
set entities(divide)    �
set entities(oslash)    �
set entities(ugrave)    �
set entities(uacute)    �
set entities(ucirc)     �
set entities(uuml)      �
set entities(yacute)    �
set entities(thorn)     �
set entities(yuml)      �

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

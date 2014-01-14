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

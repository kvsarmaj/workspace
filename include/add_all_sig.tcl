# Script to automatically add all design signals to the wave window on startup;
set nsigs [ gtkwave::getNumFacs ]
set sigs [list]
lappend sigs "__bug_marker__" 
for {set i 0} {$i < $nsigs} {incr i} {
set name [ gtkwave::getFacName $i ] 
lappend sigs $name
}
set added [ gtkwave::addSignalsFromList $sigs ]

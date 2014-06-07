#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}
#package require Tk

proc send32bit {serial val} {
    # bits sent at a time
    set bps 5
    for {set i 6} {$i >= 0} {incr i -1} {
        set vts [expr (($val >> ($bps * $i)) & 0x1f) | (($i << $bps) & 0xe0)]
        puts [format 0x%02x $vts]
        puts -nonewline $serial [binary format c1 $vts]
        after 10
        flush $serial
    }
}

set serial [open /dev/ttyUSB0 r+]
fconfigure $serial -mode "115200,n,8,1" -translation binary -handshake none
fconfigure $serial -blocking 1 -buffering none

# write to lowest CONFIG_REG
send32bit $serial 0x0020aa56
send32bit $serial 0x0021a5a6
send32bit $serial 0x00225a5b
send32bit $serial 0x0023aa56
send32bit $serial 0x0024a5a6
# write to lowest PULSE_REG
send32bit $serial 0x000ba5a5

# set vts 0x00000000
# while {1} {
#     send32bit $serial $vts
#     set vts [expr $vts + 1]
# #    after 1000
# }

# while {1} {
#     set data [read $serial 1]
#     puts [format 0x%02X [scan $data %c]]
#     after 100
#     set val [expr $val + 1]
#     puts -nonewline $serial [binary format c1 $val]
# }

close $serial

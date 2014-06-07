#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

package require Thread

proc send32bit {channel val} {
    # bits sent at a time
    set bps 5
    for {set i 6} {$i >= 0} {incr i -1} {
        set vts [expr (($val >> ($bps * $i)) & 0x1f) | (($i << $bps) & 0xe0)]
        puts [format 0x%02x $vts]
        puts -nonewline $channel [binary format c1 $vts]
        flush $channel
    }
}

set readThread [thread::create {
    proc read_all {channel} {
        while 1 {
            set data [read $channel]
            if {[eof $channel]} break
        }
    }
    thread::wait
}]

set channel [socket 192.168.2.2 1024]
fconfigure $channel -blocking 1 -translation binary -buffersize 1024 -buffering full

fileevent $channel readable [subst {read $channel}]

while 1 {
    puts $channel {abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz}
    flush $channel
}

vwait forever;

# write to lowest CONFIG_REG
# send32bit $channel 0x0020aa56
# send32bit $channel 0x0021a5a6
# send32bit $channel 0x00225a5b
# send32bit $channel 0x0023aa56
# send32bit $channel 0x0024a5a6
# write to lowest PULSE_REG
# send32bit $channel 0x000ba5a5

close $channel

# Local Variables:
# mode: tcl
# End:

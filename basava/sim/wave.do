onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group PORTA /top/PORTA_RD_CHECK
add wave -noupdate -expand -group PORTA /top/inf/clkA
add wave -noupdate -expand -group PORTA /top/inf/enA
add wave -noupdate -expand -group PORTA /top/inf/weA
add wave -noupdate -expand -group PORTA /top/inf/AddA
add wave -noupdate -expand -group PORTA /top/inf/DinA
add wave -noupdate -expand -group PORTA /top/inf/DoutA
add wave -noupdate -expand -group PORTA {/top/ref_dout[0]}
add wave -noupdate -expand -group PORTA /top/inf/errorA
add wave -noupdate -expand -group PORTB /top/PORTB_RD_CHECK
add wave -noupdate -expand -group PORTB /top/inf/clkB
add wave -noupdate -expand -group PORTB /top/inf/enB
add wave -noupdate -expand -group PORTB /top/inf/weB
add wave -noupdate -expand -group PORTB /top/inf/AddB
add wave -noupdate -expand -group PORTB /top/inf/DinB
add wave -noupdate -expand -group PORTB {/top/ref_dout[1]}
add wave -noupdate -expand -group PORTB /top/inf/DoutB
add wave -noupdate -expand -group PORTB /top/inf/errorB
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {42 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 205
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {188 ns}

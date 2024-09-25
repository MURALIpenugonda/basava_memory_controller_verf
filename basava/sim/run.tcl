vlog -sv ../rtl/* +cover
vlog -sv ../tb/top.sv
vsim -gui -voptargs=+acc work.top -coverage -assertdebug
atv log -asserts -enable top
do wave.do
run -all

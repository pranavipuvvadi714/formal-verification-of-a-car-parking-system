clear -all

analyze -sv09 parking_system_modified.v
elaborate -top parking_system

clock clk
reset ~reset_n


#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.



# Clock constraints

create_clock -name "clock" -period 39.722ns [get_ports {clk}]
create_clock -name "clock_vin" -period 39.722ns
create_clock -name "clock_vout" -period 39.722ns
create_clock -name "Q3" -period 490.000ns [get_ports {pAq3}] -waveform {0.000 280.000}

set_clock_groups -asynchronous -group {clock} -group {Q3}
set_clock_groups -asynchronous -group {clock_vin} -group {Q3}
set_clock_groups -asynchronous -group {clock_vout} -group {Q3}

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
#derive_clock_uncertainty
# Not supported for family MAX7000S

# tsu/th constraints
set_input_delay -clock "clock_vin" -max 1ns [get_ports {pVdata[*]}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {pVdata[*]}]
set_input_delay -clock "clock_vin" -max 1ns [get_ports {pAaddr[*]}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {pAaddr[*]}]
set_input_delay -clock "clock_vin" -max 1ns [get_ports {pAdata[*]}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {pAdata[*]}]
set_input_delay -clock "clock_vin" -max 1ns [get_ports {pArw}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {pArw}]
set_input_delay -clock "clock_vin" -max 1ns [get_ports {pAphi0}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {pAphi0}]
set_input_delay -clock "clock_vin" -max 1ns [get_ports {reset}]
set_input_delay -clock "clock_vin" -min 1ns [get_ports {reset}]

# tco constraints
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pVaddr[*]}]
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pVaddr[*]}]
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pVdata[*]}]
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pVdata[*]}]
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pVwrite}] -clock_fall
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pVwrite}] -clock_fall
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pVSYNC}]
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pVSYNC}]
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pHSYNC}]
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pHSYNC}]
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pR}] 
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pR}] 
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pG}] 
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pG}] 
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pB}] 
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pB}] 
set_output_delay -clock "clock_vout" -max 1ns [get_ports {pI}] 
set_output_delay -clock "clock_vout" -min 1ns [get_ports {pI}] 


# tpd constraints

set_max_delay 20.000ns -from [get_ports {pAaddr[*]}] -to [get_ports {pVaddr[*]}]
set_max_delay 20.000ns -from [get_ports {pAdata[*]}] -to [get_ports {pVdata[*]}]

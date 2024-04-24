//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4 Education
//Created Time: 2024-04-18 09:03:24
create_clock -name crystal -period 37.037 -waveform {0 18.518} [get_ports {clkin}]
create_generated_clock -name pll -source [get_ports {clkin}] -master_clock crystal -divide_by 5 -multiply_by 37 [get_nets {clkin_pll}]
set_operating_conditions -grade c -model fast -speed 6 -setup -hold -max_min

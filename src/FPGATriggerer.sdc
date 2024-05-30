//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4 Education
//Created Time: 2024-05-17 16:36:47
create_clock -name crystal -period 37.037 -waveform {0 18.518} [get_ports {clkin}]
create_generated_clock -name pll -source [get_ports {clkin}] -master_clock crystal -divide_by 6 -multiply_by 37 [get_nets {clkin_pll}]
set_false_path -from [get_regs {delayer/reg_delay_cycles_0_s0 delayer/reg_delay_cycles_10_s0 delayer/reg_delay_cycles_11_s0 delayer/reg_delay_cycles_12_s0 delayer/reg_delay_cycles_13_s0 delayer/reg_delay_cycles_14_s0 delayer/reg_delay_cycles_15_s0 delayer/reg_delay_cycles_16_s0 delayer/reg_delay_cycles_17_s0 delayer/reg_delay_cycles_18_s0 delayer/reg_delay_cycles_19_s0 delayer/reg_delay_cycles_1_s0 delayer/reg_delay_cycles_20_s0 delayer/reg_delay_cycles_21_s0 delayer/reg_delay_cycles_22_s0 delayer/reg_delay_cycles_23_s0 delayer/reg_delay_cycles_2_s0 delayer/reg_delay_cycles_3_s0 delayer/reg_delay_cycles_4_s0 delayer/reg_delay_cycles_5_s0 delayer/reg_delay_cycles_6_s0 delayer/reg_delay_cycles_7_s0 delayer/reg_delay_cycles_8_s0 delayer/reg_delay_cycles_9_s0}] -to [get_regs {delayer/fsm_state_1_s5 delayer/fsm_state_0_s3}] 
set_false_path -from [get_regs {delayer/armed_s0}] -to [get_regs {delayer/fsm_state_0_s3 delayer/fsm_state_1_s5}] 
set_operating_conditions -grade c -model fast -speed 6 -setup -hold -max_min

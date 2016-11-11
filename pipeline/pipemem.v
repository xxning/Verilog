module pipemem (mwmem, malu, mb, clock, memclock, mmo);
	input mwmem;
	input [31:0] malu, mb;
	input clock, memclock;
	output [31:0] mmo;
	
	wire write_enable = mwmem & ~clock;
	lpm_ram_dq_dram dmem (malu[6:2], memclock, mb, write_enable, mmo);
endmodule

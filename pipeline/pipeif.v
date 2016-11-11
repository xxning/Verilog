module pipeif (pcsource, pc, bpc, da, jpc, npc, pc4, ins, memclock);
	input [1:0] pcsource;
	input [31:0] pc, bpc, da, jpc;
	input memclock;
	output [31:0] npc, pc4, ins;
	
	assign pc4 = pc + 32'h4;
	mux4x32 next_pc (pc4, bpc, da, jpc, pcsource, npc);
	lpm_rom_irom imem (pc[7:2], memclock, ins);
endmodule

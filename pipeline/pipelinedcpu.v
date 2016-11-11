module pipelinedcpu (resetn, clock, memclock, pc, inst, ealu, malu, walu);
	input resetn, clock, memclock;
	output [31:0] pc, inst, ealu, malu, walu;
	wire [31:0] npc, bpc, jpc, pc4, dpc4, epc4, ins, inst, da, db, dimm, ea, eb, mb, eimm, mmo, wmo, wdi;
	wire [4:0] drn, ern0, ern, mrn, wrn;
	wire [3:0] daluc, ealuc;
	wire [1:0] pcsource;
	wire wpcir;
	wire dwreg, dm2reg, dwmem, djal, daluimm, dshift, ewreg, em2reg, ewmem, ejal, ealuimm, eshift, mwreg, mm2reg, mwmem, wwreg, wm2reg;
	pipepc prog_cnt (npc, wpcir, clock, resetn, pc);
	pipeif if_stage (pcsource, pc, bpc, da, jpc, npc, pc4, ins, memclock);
	pipeir inst_reg (pc4, ins, wpcir, clock, resetn, dpc4, inst);
	pipeid id_stage (mrn, mm2reg, mwreg, ern, em2reg, ewreg,
	                 dpc4, inst, wrn, wdi, wwreg, ealu, malu, mmo,
	                 clock, resetn,
	                 bpc, jpc, pcsource, wpcir, dwreg, dm2reg, dwmem, djal, daluc, daluimm, dshift,
	                 da, db, dimm, drn);
	pipedereg de_reg (dwreg, dm2reg, dwmem, djal, daluc, daluimm, dshift, dpc4, da, db, dimm, drn,
	                  clock, resetn,
	                  ewreg, em2reg, ewmem, ejal, ealuc, ealuimm, eshift, epc4, ea, eb, eimm, ern0);
	pipeexe exe_stage (ejal, ealuc, ealuimm, eshift, epc4, ea, eb, eimm, ern0, ealu, ern);
	pipeemreg em_reg (ewreg, em2reg, ewmem, ealu, eb, ern, clock, resetn, mwreg, mm2reg, mwmem, malu, mb, mrn);
	pipemem mem_stage (mwmem, malu, mb, clock, memclock, mmo);
	pipemwreg mw_reg (mwreg, mm2reg, malu, mmo, mrn, clock, resetn, wwreg, wm2reg, walu, wmo, wrn);
	mux2x32 wb_stage (walu, wmo, wm2reg, wdi);
endmodule

module pipeid (mrn, mm2reg, mwreg, ern, em2reg, ewreg, dpc4, inst, wrn, wdi, wwreg, ealu, malu, mmo, clock, resetn, bpc, jpc, pcsource, wpcir, dwreg, dm2reg, dwmem, djal, daluc, daluimm, dshift, da, db, dimm, drn);
	input [31:0] dpc4, inst, ealu, malu, mmo, wdi;
	input [4:0] ern, mrn, wrn;
	input clock, resetn, em2reg, ewreg, mm2reg, mwreg, wwreg;
	output [31:0] bpc, jpc, da, db, dimm;
	output [4:0] drn;
	output [3:0] daluc;
	output [1:0] pcsource;
	output wpcir, dwreg, dm2reg, dwmem, djal, daluimm, dshift;
	
	wire [31:0] offset, q1, q2;
	wire [15:0] imm, ext_16;
	wire [5:0] op, func;
	wire [4:0] rs, rt, rd;
	wire [1:0] fwda, fwdb;
	wire rsrtequ, regrt, sext, e;
		
	assign op = inst[31:26];
	assign func = inst[5:0];
	assign rs = inst[25:21];
	assign rt = inst[20:16];
	assign rd = inst[15:11];
	assign imm = inst[15:0];
	assign e = sext & inst[15];
	assign ext_16 = {16{e}};
	assign offset = {ext_16[13:0], imm, 2'b00};
	assign bpc = dpc4 + offset;
	assign jpc = {dpc4[31:28], inst[25:0], 2'b00};
	assign rsrtequ = (da == db);
	assign dimm = {ext_16, imm};
	
	pipeidcu control_unit (mrn, mm2reg, mwreg, ern, em2reg, ewreg, rsrtequ, op, func, rs, rt, dwreg, dm2reg, dwmem, djal, daluc, daluimm, dshift, regrt, sext, fwdb, fwda, pcsource, wpcir);
	regfile rf (rs, rt, wdi, wrn, wwreg, ~clock, resetn, q1, q2);
	mux4x32 alu_a (q1, ealu, malu, mmo, fwda, da);
	mux4x32 alu_b (q2, ealu, malu, mmo, fwdb, db);
	mux2x5 des_reg_no (rd, rt, regrt, drn);
endmodule

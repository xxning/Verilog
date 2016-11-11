module pipeexe (ejal, ealuc, ealuimm, eshift, epc4, ea, eb, eimm, ern0, ealu, ern);
	input ejal;
	input [3:0] ealuc;
	input ealuimm, eshift;
	input [31:0] epc4, ea, eb, eimm;
	input [4:0] ern0;
	output [31:0] ealu;
	output [4:0] ern;
	
	wire [31:0] epc8, alua, alub, sa, r;
	assign epc8 = epc4 + 32'h4;
	assign sa = {27'b0, eimm[10:6]};
	mux2x32 alu_ina (ea, sa, eshift, alua);
	mux2x32 alu_inb (eb, eimm, ealuimm, alub);
	alu alu_unit (alua, alub, ealuc, r);
	mux2x32 save_pc8 (r, epc8, ejal, ealu);
	assign ern = ern0 | {5{ejal}};
endmodule

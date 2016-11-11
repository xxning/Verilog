module pipedereg (dwreg, dm2reg, dwmem, djal, daluc, daluimm, dshift, dpc4, da, db, dimm, drn,
	              clock, resetn,
	              ewreg, em2reg, ewmem, ejal, ealuc, ealuimm, eshift, epc4, ea, eb, eimm, ern0);
	input dwreg, dm2reg, dwmem, djal, daluimm, dshift;
	input [3:0] daluc;
	input [31:0] dpc4, da, db, dimm;
	input [4:0] drn;
	input clock, resetn;
	output ewreg, em2reg, ewmem, ejal, ealuimm, eshift;
	output [3:0] ealuc;
	output [31:0] epc4, ea, eb, eimm;
	output [4:0] ern0;
	reg ewreg, em2reg, ewmem, ejal, ealuimm, eshift;
	reg [3:0] ealuc;
	reg [31:0] epc4, ea, eb, eimm;
	reg [4:0] ern0;
	
	always @ (posedge clock or negedge resetn) begin
		if (resetn == 0) begin
			ewreg <= 0;
			em2reg <= 0;
			ewmem <= 0;
			ejal <= 0;
			ealuimm <= 0;
			eshift <= 0;
			ealuc <= 0;
			epc4 <= 0;
			ea <= 0;
			eb <= 0;
			eimm <= 0;
			ern0 <= 0;
		end else begin
			ewreg <= dwreg;
			em2reg <= dm2reg;
			ewmem <= dwmem;
			ejal <= djal;
			ealuimm <= daluimm;
			eshift <= dshift;
			ealuc <= daluc;
			epc4 <= dpc4;
			ea <= da;
			eb <= db;
			eimm <= dimm;
			ern0 <= drn;
		end
	end
endmodule

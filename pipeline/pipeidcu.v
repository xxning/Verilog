module pipeidcu (mrn, mm2reg, mwreg, ern, em2reg, ewreg, rsrtequ, op, func, rs, rt, wreg, m2reg, wmem, jal, aluc, aluimm, shift, regrt, sext, fwdb, fwda, pcsource, wpcir);
	input [5:0] op, func;
	input [4:0] rs, rt, ern, mrn;
	input ewreg, em2reg, mwreg, mm2reg, rsrtequ;	
	output [3:0] aluc;
	output [1:0] fwda, fwdb, pcsource;
	output wreg, m2reg, wmem, jal, aluimm, shift, regrt, sext, wpcir;	
	reg [1:0] fwda, fwdb;
	
	wire r_type = ~|op;
	wire i_add = r_type & func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];
	wire i_sub = r_type & func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0];
	wire i_and = r_type & func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & ~func[0];
	wire i_or = r_type & func[5] & ~func[4] & ~func[3] & func[2] & ~func[1] & func[0];
	wire i_xor = r_type & func[5] & ~func[4] & ~func[3] & func[2] & func[1] & ~func[0];
	wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];
	wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & ~func[0];
	wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] & func[1] & func[0];
	wire i_jr = r_type & ~func[5] & ~func[4] & func[3] & ~func[2] & ~func[1] & ~func[0];
	wire i_addi = ~op[5] & ~op[4] & op[3] & ~op[2] & ~op[1] & ~op[0];
	wire i_andi = ~op[5] & ~op[4] & op[3] & op[2] & ~op[1] & ~op[0];
	wire i_ori = ~op[5] & ~op[4] & op[3] & op[2] & ~op[1] & op[0];
	wire i_xori = ~op[5] & ~op[4] & op[3] & op[2] & op[1] & ~op[0];
	wire i_lw = op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0];
	wire i_sw = op[5] & ~op[4] & op[3] & ~op[2] & op[1] & op[0];
	wire i_beq = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0];
	wire i_bne = ~op[5] & ~op[4] & ~op[3] & op[2] & ~op[1] & op[0];
	wire i_lui = ~op[5] & ~op[4] & op[3] & op[2] & op[1] & op[0];
	wire i_j = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & ~op[0];
	wire i_jal = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0];
	wire i_rs = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_beq | i_bne;
	wire i_rt = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | i_sw | i_beq | i_bne;
	assign wpcir = ~(ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | i_rt & (ern == rt)));
	assign wreg = (i_xori | i_andi | i_ori | i_addi | i_lw | i_add | i_sub | i_xor | i_and | i_or | i_sll | i_srl | i_sra | i_lui | i_jal) & wpcir;
	assign m2reg = i_lw;
	assign wmem = i_sw & wpcir;
	assign jal = i_jal;
	assign aluc[3] = i_sra;
	assign aluc[2] = i_srl | i_sra | i_beq | i_bne | i_sub | i_or | i_ori | i_lui;
	assign aluc[1] = i_sll | i_xor | i_xori | i_srl | i_sra | i_lui;
	assign aluc[0] = i_and | i_andi | i_or | i_ori | i_sll | i_srl | i_sra;
	assign aluimm = i_addi | i_lw | i_sw | i_xori | i_lui | i_andi | i_ori;
	assign shift = i_sll | i_srl | i_sra;
	assign regrt = i_xori | i_andi | i_ori | i_addi | i_lui | i_lw;
	assign sext = i_beq | i_bne | i_addi | i_lw | i_sw;
	assign pcsource[1] = i_jr | i_j | i_jal;
	assign pcsource[0] = (i_bne & ~rsrtequ) | (i_beq & rsrtequ) | i_j | i_jal;
	
	always @ * begin
		fwda = 2'b00;
		if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) begin
			fwda = 2'b01;
		end else begin
			if (mwreg & (mrn != 0) & (ern != rs) & (mrn == rs) & ~mm2reg) begin
				fwda = 2'b10;
			end else begin
				if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg) begin
					fwda = 2'b11;
				end
			end
		end
		fwdb = 2'b00;
		if (ewreg & (ern != 0) & (ern == rt) & ~em2reg) begin
			fwdb = 2'b01;
		end else begin
			if (mwreg & (mrn != 0) & (ern != rt) & (mrn == rt) & ~mm2reg) begin
				fwdb = 2'b10;
			end else begin
				if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg) begin
					fwdb = 2'b11;
				end
			end
		end
	end
endmodule

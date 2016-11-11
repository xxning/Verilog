module pipepc (npc, wpcir, clock, resetn, pc);
	input [31:0] npc;
	input wpcir, clock, resetn;
	output [31:0] pc;
	
	//dffe32 program_counter (npc, clock, resetn, wpcir, pc);
	reg [31:0] pc;
	always @ (posedge clock or negedge resetn) begin
		if (resetn == 0) begin
			pc <= 0;
		end else if (~wpcir) begin
			pc <= npc;
		end
	end
endmodule

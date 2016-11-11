module mux2x32 (a0, a1, s, y);
	input [31:0] a0, a1;
	input s;
	output [31:0] y;
	
	reg [31:0] y;	
	always @ * begin
		case (s)
			1'b0: y = a0;
			1'b1: y = a1;
		endcase
	end
endmodule

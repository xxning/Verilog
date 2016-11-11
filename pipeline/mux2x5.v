module mux2x5 (a0, a1, s, y);
	input [4:0] a0, a1;
	input s;
	output [4:0] y;
	
	reg [4:0] y;	
	always @ * begin
		case (s)
			1'b0: y = a0;
			1'b1: y = a1;
		endcase
	end
endmodule

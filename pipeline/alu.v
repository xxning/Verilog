module alu (a, b, aluc, s);
	input [31:0] a, b;
	input [3:0] aluc;
	output [31:0] s;
	
	reg [31:0] s;
	always @ * begin
		casex (aluc)
			4'bx000: s = a + b;
			4'bx100: s = a - b;
			4'bx001: s = a & b;
			4'bx101: s = a | b;
			4'bx010: s = a ^ b;
			4'bx110: s = b << 16;
			4'b0011: s = b << a;
			4'b0111: s = b >> a;
			4'b1111: s = $signed(b) >>> a;
			default: s = 0;
		endcase
	end
endmodule

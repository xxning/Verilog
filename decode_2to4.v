
module 	decode_2to4(
input				E_n,
input		[1:0]	A,
output	reg	[3:0]	Y_n
);
always@(*)
begin
	if(E_n==1'b1)
		Y_n	= 4'b1111;
	else
		case(A)
			2'b00:	Y_n	= 4'b1110;
			2'b01:	Y_n	= 4'b1101;
			2'b10:	Y_n	= 4'b1011;
			2'b11:	Y_n	= 4'b0111;
			default:Y_n = 4'b1111;
		endcase
end
endmodule

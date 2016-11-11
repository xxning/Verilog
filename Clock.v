`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:31:50 12/03/2014 
// Design Name: 
// Module Name:    Clock 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:31:50 12/03/2014 
// Design Name: 
// Module Name:    Clock 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Clock(
	input CP,nCR,EN,Adj_Min,
	input C,
	input[3:0] data,
	output wire[6:0] digital,
	output wire[3:0] sel
);


wire[7:0] Minute,Second;
supply1 Vdd;
wire SecH_EN,MinL_EN,MinH_EN;
wire clock,Show_Clk;

assign SecH_EN=(Second[3:0]==4'h9);

ShowClk(
.clk(CP),
.clock(Show_Clk),
.nCR(nCR)
);


DivClk S1(
.clk(CP),
.clock(clock),
.nCR(nCR)
);
//second
counter10 U1(
.Q(Second[3:0]),
.CP(clock),
.nCR(nCR),
.EN(EN)
);

counter6 U2(
.Q(Second[7:4]),
.CP(clock),
.nCR(nCR),
.EN(SecH_EN),
.C(C),
.data(data)
);
//min
assign MinL_EN=Adj_Min?Vdd:(Second==8'h59);
assign MinH_EN=(Adj_Min&&(Minute[3:0]==4'h9))||(Minute[3:0]==4'h9)&&(Second==8'h59);

counter10 U3(
.Q(Minute[3:0]),
.CP(clock),
.nCR(nCR),
.EN(MinL_EN)
);

counter6 U4(
.Q(Minute[7:4]),
.CP(clock),
.nCR(nCR),
.EN(MinH_EN),
.C(C),
.data(data)
);

show S2(
.second(Second),
.minute(Minute),
.sel(sel),
.digital(digital), 
.clk(Show_Clk),
.rst_n(nCR)
);


endmodule


module counter10(
	input CP,nCR,EN,
	output reg[3:0]Q
);
always@(posedge CP,negedge nCR)
begin
	if(~nCR) 			Q<=4'b0000;
	else if(~EN)  		Q<=Q;
	else if(Q==4'b1001) Q<=4'b0000;
	else				Q<=Q+1'b1;
end
endmodule

module counter6(
	input CP,nCR,EN,
	input C,
	input[3:0] data,
	output reg[3:0]Q
);
always@(posedge CP,negedge nCR)
begin
	if(C)
		Q<=data;
	else
		begin
		if(~nCR) 			Q<=4'b0000;
		else if(~EN)  		Q<=Q;
		else if(Q==4'b0101) Q<=4'b0000;
		else				Q<=Q+1'b1;
	end
end
endmodule

module show(
	input clk,rst_n,EN,
	input[7:0] second,minute,
	input[2:0] data,
	input[1:0] control,
	output reg[6:0] digital,
	output reg[3:0] sel
	
);

reg[1:0]	cnt;	

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)
		cnt<=2'b0;
	else
		cnt<=cnt+2'b1;
end

always@(cnt)
begin
	case(cnt)
		2'b00:sel=4'b1110;
		2'b01:sel=4'b1101;
		2'b10:sel=4'b1011;
		2'b11:sel=4'b0111;
		default:sel=4'b1111;
	endcase
end

always@(posedge clk or negedge rst_n)
begin
	case(cnt)
		2'b00:
			begin
			case(second[3:0])
			4'b0000:digital<=7'b0000001;
			4'b0001:digital<=7'b1001111;
			4'b0010:digital<=7'b0010010;
			4'b0011:digital<=7'b0000110;
			4'b0100:digital<=7'b1001100;
			4'b0101:digital<=7'b0100100;
			4'b0110:digital<=7'b0100000;
			4'b0111:digital<=7'b0001111;
			4'b1000:digital<=7'b0000000;
			4'b1001:digital<=7'b0000100;
			default:digital<=7'b1111111;
			endcase
			end
		2'b01:
			begin
			case(second[7:4])
			4'b0000:digital<=7'b0000001;
			4'b0001:digital<=7'b1001111;
			4'b0010:digital<=7'b0010010;
			4'b0011:digital<=7'b0000110;
			4'b0100:digital<=7'b1001100;
			4'b0101:digital<=7'b0100100;
			4'b0110:digital<=7'b0100000;
			default:digital<=7'b1111111;
			endcase
			end
		2'b10:
			begin
			case(minute[3:0])
			4'b0000:digital<=7'b0000001;
			4'b0001:digital<=7'b1001111;
			4'b0010:digital<=7'b0010010;
			4'b0011:digital<=7'b0000110;
			4'b0100:digital<=7'b1001100;
			4'b0101:digital<=7'b0100100;
			4'b0110:digital<=7'b0100000;
			4'b0111:digital<=7'b0001111;
			4'b1000:digital<=7'b0000000;
			4'b1001:digital<=7'b0000100;
			default:digital<=7'b1111111;
			endcase
			end
		2'b11:
			begin
			case(minute[7:4])
			4'b0000:digital<=7'b0000001;
			4'b0001:digital<=7'b1001111;
			4'b0010:digital<=7'b0010010;
			4'b0011:digital<=7'b0000110;
			4'b0100:digital<=7'b1001100;
			4'b0101:digital<=7'b0100100;
			4'b0110:digital<=7'b0100000;
			default:digital<=7'b1111111;
			endcase
			end	
		default:digital<=7'b1111111;	
	endcase
end
endmodule

module DivClk(
	input clk,nCR,
	output reg clock
);

reg[26:0] count;

always@(posedge clk or negedge nCR)
begin 
	if(~nCR)	count<=27'h0;
	else if(count[26]==1'b1&&count[25]==1'b1)
		begin
		clock<=1'b1;
		count<=27'h0;
		end
	else 
		begin
		clock<=1'b0;
		count<=count+1'b1;
		end
end
endmodule

module ShowClk(
	input clk,nCR,
	output reg clock
);

reg[15:0] count;

always@(posedge clk or negedge nCR)
begin 
	if(~nCR)	count<=16'h0;
	else if(count[15]==1'b1)
		begin
		clock<=1'b1;
		count<=count+1'b1;
		end
	else 
		begin
		clock<=1'b0;
		count<=count+1'b1;
		end
end
endmodule


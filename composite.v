module composite(
	input clk,nCR,EN,
	input[1:0] FUN, //选择功能
	input wire[7:0] Data,//输入8位数据
	input Left,Right,LA,RA,CL,//LED操作
	output wire[6:0] hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7,//数码显示
	output reg[17:0] LED,  //LED显示
	output LED_Left,LED_Right,LED_LA,LED_RA,LED_nCR,LED_EN,LED_CL
);

wire[7:0] data;
wire[3:0] Count;
wire[3:0] show0,show1,show2,show3,show4,show5,show6,show7;

wire[3:0] MsecL,MsecH,SecL,SecH,MinL,MinH,HouL,HouH;
wire MsecL_EN,MsecH_EN,SecL_EN,SecH_EN,MinL_EN,MinH_EN,HouL_EN,HouH_EN;
wire clock,CP;
//wire Key_reset,Key_EN;

assign LED_Left=Left;
assign LED_Right=Right;
assign LED_LA=LA;
assign LED_RA=RA;
assign LED_CL=CL;
assign LED_EN=EN;
assign LED_nCR=nCR;

/***************************************************/
/***************************************************/

WatchClk N1(.clk(clk),.nCR(nCR),.clock(clock));
ShowClk N2(.clk(clk),.nCR(nCR),.clock(CP));
/*Key M1(.clk(clk),.Key_In(nCR),.Key_Out(Key_reset));
Key M2(.clk(clk),.Key_In(EN),.Key_Out(Key_EN));

assign Key_reset_now=Key_reset;
assign Key_EN_now=Key_EN;*/
/***************************************************/
/***************************************************/
//COUNTER
//m_second
assign MsecL_EN=EN;
assign MsecH_EN=(MsecL==4'h9);
counter10 U1(.Q(MsecL),.CP(clock),.nCR(nCR),.EN(MsecL_EN));
counter10 U2(.Q(MsecH),.CP(clock),.nCR(nCR),.EN(MsecH_EN));
//second
assign SecL_EN=(MsecL==4'h9&&MsecH==4'h9);
assign SecH_EN=(SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U3(.Q(SecL),.CP(clock),.nCR(nCR),.EN(SecL_EN));
counter6  U4(.Q(SecH),.CP(clock),.nCR(nCR),.EN(SecH_EN));
//minute
assign MinL_EN=(SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
assign MinH_EN=(MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U5(.Q(MinL),.CP(clock),.nCR(nCR),.EN(MinL_EN));
counter6  U6(.Q(MinH),.CP(clock),.nCR(nCR),.EN(MinH_EN));
//hour
assign HouL_EN=(MinH==4'h5&&MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
assign HouH_EN=(HouL==4'h9&&MinH==4'h5&&MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U7(.Q(HouL),.CP(clock),.nCR(nCR),.EN(HouL_EN));
counter10 U8(.Q(HouH),.CP(clock),.nCR(nCR),.EN(HouH_EN));
/***************************************************/
/***************************************************/

show_count Q1(.CP(CP),.nCR(nCR),.EN(EN),.c0(show0),.c1(show1),.c2(show2),.c3(show3),
				  .c4(show4),.c5(show5),.c6(show6),.c7(show7));			  				  
Shift Q2(.Clk(CP),.Data(Data),.data(data),.En(EN));
Count_play Q3(.EN(EN),.Count(Count),.Clk(CP),.nCR(nCR));

show SHOW(.clk(CP),.rst_n(nCR),.show0(show0),.show1(show1),.show2(show2),.show3(show3),
			 .show4(show4),.show5(show5),.show6(show6),.show7(show7),.MsecL(MsecL),.MsecH(MsecH),
			 .SecL(SecL),.SecH(SecH),.MinL(MinL),.MinH(MinH),.HouL(HouL),.HouH(HouH),
			 .Data(data),.Fun(FUN),.count(Count),.hex0(hex0),.hex1(hex1),.hex2(hex2),
			 .hex3(hex3),.hex4(hex4),.hex5(hex5),.hex6(hex6),.hex7(hex7)
);

//LED灯操作
reg [17:0] light1,light2;
always@(posedge CP)
begin
	if(CL) LED <= 18'b000000010000000000;
	else
	begin
	light1<=LED<<1;
	light2<=LED>>1;
	case({Left,Right,LA,RA})
	4'b0111:
		begin
		LED <= {LED[16:0],LED[17]};
		end
	4'b1011:
		begin
		LED <= {LED[0],LED[17:1]};
		end
	4'b1101:
		begin
		if(LED[17]==1'b1&&LED[0]==1'b0)
			LED <= LED | 18'b000000000000000001;
		else 
			LED <= LED | light1;	
		end
	4'b1110:
		begin
		if(LED[0]==1'b1&&LED[17]==1'b0)
			LED <= LED | 18'b100000000000000000;
		else
			LED <= LED | light2;		
		end
	default:LED <= LED;
	endcase	
	end
end	

endmodule

//show
module show_count(
	input CP,nCR,EN,
	output reg[3:0] c0,c1,c2,c3,c4,c5,c6,c7
);

always@(posedge CP,negedge nCR,negedge EN)
begin
	if(~nCR) 			
		begin
		c0<=4'b1111;
		c1<=4'b1111;
		c2<=4'b1111;
		c3<=4'b1111;
		c4<=4'b1111;
		c5<=4'b1111;
		c6<=4'b1111;
		c7<=4'b1111;		
		end
	else if(~EN)  
		begin
		c0<=c0;
		c1<=c1;
		c2<=c2;
		c3<=c3;
		c4<=c4;
		c5<=c5;
		c6<=c6;
		c7<=c7;
		end
	else 
		begin
		c0<=c0+4'b1;
		c1<=c0;
		c2<=c1;
		c3<=c2;
		c4<=c3;
		c5<=c4;
		c6<=c5;
		c7<=c6;
		end
end
endmodule

//show
module show(
	input clk,rst_n,
	input[3:0] show0,show1,show2,show3,show4,show5,show6,show7,
	input [3:0] MsecL,MsecH,SecL,SecH,MinL,MinH,HouL,HouH,
	input [7:0] Data,
	input[1:0] Fun,
	input[4:0] count,
	output reg[6:0] hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7
);

always@(posedge clk or negedge rst_n)
begin
	case(Fun)
		2'b00:
		begin
			case(show0)
				4'b0000: hex0 <= 7'b0010010;
				4'b0001: hex0 <= 7'b1110001;
				4'b0010: hex0 <= 7'b1001110;
				4'b0011: hex0 <= 7'b1000001;
				4'b0100: hex0 <= 7'b1110111;
				4'b0101: hex0 <= 7'b1111000;
				4'b0110: hex0 <= 7'b1111001;
				4'b0111: hex0 <= 7'b0110000;
				4'b1000: hex0 <= 7'b1000000;
				4'b1001: hex0 <= 7'b0110000;
				4'b1010: hex0 <= 7'b1000000;
				4'b1011: hex0 <= 7'b0010000;
				4'b1100: hex0 <= 7'b1000000;
				4'b1101: hex0 <= 7'b1000000;
				4'b1110: hex0 <= 7'b0000000;
				4'b1111: hex0 <= 7'b1111111;
				default: hex0 <= 7'b1111111;
			endcase
			
			case(show1)
				4'b0000: hex1 <= 7'b0010010;
				4'b0001: hex1 <= 7'b1110001;
				4'b0010: hex1 <= 7'b1001110;
				4'b0011: hex1 <= 7'b1000001;
				4'b0100: hex1 <= 7'b1110111;
				4'b0101: hex1 <= 7'b1111000;
				4'b0110: hex1 <= 7'b1111001;
				4'b0111: hex1 <= 7'b0110000;
				4'b1000: hex1 <= 7'b1000000;
				4'b1001: hex1 <= 7'b0110000;
				4'b1010: hex1 <= 7'b1000000;
				4'b1011: hex1 <= 7'b0010000;
				4'b1100: hex1 <= 7'b1000000;
				4'b1101: hex1 <= 7'b1000000;
				4'b1110: hex1 <= 7'b0000000;
				4'b1111: hex1 <= 7'b1111111;
				default: hex1 <= 7'b1111111;
			endcase
			
			case(show2)
				4'b0000: hex2 <= 7'b0010010;
				4'b0001: hex2 <= 7'b1110001;
				4'b0010: hex2 <= 7'b1001110;
				4'b0011: hex2 <= 7'b1000001;
				4'b0100: hex2 <= 7'b1110111;
				4'b0101: hex2 <= 7'b1111000;
				4'b0110: hex2 <= 7'b1111001;
				4'b0111: hex2 <= 7'b0110000;
				4'b1000: hex2 <= 7'b1000000;
				4'b1001: hex2 <= 7'b0110000;
				4'b1010: hex2 <= 7'b1000000;
				4'b1011: hex2 <= 7'b0010000;
				4'b1100: hex2 <= 7'b1000000;
				4'b1101: hex2 <= 7'b1000000;
				4'b1110: hex2 <= 7'b0000000;
				4'b1111: hex2 <= 7'b1111111;
				default: hex2 <= 7'b1111111;
			endcase
			
			case(show3)
				4'b0000: hex3 <= 7'b0010010;
				4'b0001: hex3 <= 7'b1110001;
				4'b0010: hex3 <= 7'b1001110;
				4'b0011: hex3 <= 7'b1000001;
				4'b0100: hex3 <= 7'b1110111;
				4'b0101: hex3 <= 7'b1111000;
				4'b0110: hex3 <= 7'b1111001;
				4'b0111: hex3 <= 7'b0110000;
				4'b1000: hex3 <= 7'b1000000;
				4'b1001: hex3 <= 7'b0110000;
				4'b1010: hex3 <= 7'b1000000;
				4'b1011: hex3 <= 7'b0010000;
				4'b1100: hex3 <= 7'b1000000;
				4'b1101: hex3 <= 7'b1000000;
				4'b1110: hex3 <= 7'b0000000;
				4'b1111: hex3 <= 7'b1111111;
				default: hex3 <= 7'b1111111;
			endcase
			
			case(show4)
				4'b0000: hex4 <= 7'b0010010;
				4'b0001: hex4 <= 7'b1110001;
				4'b0010: hex4 <= 7'b1001110;
				4'b0011: hex4 <= 7'b1000001;
				4'b0100: hex4 <= 7'b1110111;
				4'b0101: hex4 <= 7'b1111000;
				4'b0110: hex4 <= 7'b1111001;
				4'b0111: hex4 <= 7'b0110000;
				4'b1000: hex4 <= 7'b1000000;
				4'b1001: hex4 <= 7'b0110000;
				4'b1010: hex4 <= 7'b1000000;
				4'b1011: hex4 <= 7'b0010000;
				4'b1100: hex4 <= 7'b1000000;
				4'b1101: hex4 <= 7'b1000000;
				4'b1110: hex4 <= 7'b0000000;
				4'b1111: hex4 <= 7'b1111111;
				default: hex4 <= 7'b1111111;
			endcase
			
			case(show5)
				4'b0000: hex5 <= 7'b0010010;
				4'b0001: hex5 <= 7'b1110001;
				4'b0010: hex5 <= 7'b1001110;
				4'b0011: hex5 <= 7'b1000001;
				4'b0100: hex5 <= 7'b1110111;
				4'b0101: hex5 <= 7'b1111000;
				4'b0110: hex5 <= 7'b1111001;
				4'b0111: hex5 <= 7'b0110000;
				4'b1000: hex5 <= 7'b1000000;
				4'b1001: hex5 <= 7'b0110000;
				4'b1010: hex5 <= 7'b1000000;
				4'b1011: hex5 <= 7'b0010000;
				4'b1100: hex5 <= 7'b1000000;
				4'b1101: hex5 <= 7'b1000000;
				4'b1110: hex5 <= 7'b0000000;
				4'b1111: hex5 <= 7'b1111111;
				default: hex5 <= 7'b1111111;
			endcase
			
			case(show6)
				4'b0000: hex6 <= 7'b0010010;
				4'b0001: hex6 <= 7'b1110001;
				4'b0010: hex6 <= 7'b1001110;
				4'b0011: hex6 <= 7'b1000001;
				4'b0100: hex6 <= 7'b1110111;
				4'b0101: hex6 <= 7'b1111000;
				4'b0110: hex6 <= 7'b1111001;
				4'b0111: hex6 <= 7'b0110000;
				4'b1000: hex6 <= 7'b1000000;
				4'b1001: hex6 <= 7'b0110000;
				4'b1010: hex6 <= 7'b1000000;
				4'b1011: hex6 <= 7'b0010000;
				4'b1100: hex6 <= 7'b1000000;
				4'b1101: hex6 <= 7'b1000000;
				4'b1110: hex6 <= 7'b0000000;
				4'b1111: hex6 <= 7'b1111111;
				default: hex6 <= 7'b1111111;
			endcase
			
			case(show7)
				4'b0000: hex7 <= 7'b0010010;
				4'b0001: hex7 <= 7'b1110001;
				4'b0010: hex7 <= 7'b1001110;
				4'b0011: hex7 <= 7'b1000001;
				4'b0100: hex7 <= 7'b1110111;
				4'b0101: hex7 <= 7'b1111000;
				4'b0110: hex7 <= 7'b1111001;
				4'b0111: hex7 <= 7'b0110000;
				4'b1000: hex7 <= 7'b1000000;
				4'b1001: hex7 <= 7'b0110000;
				4'b1010: hex7 <= 7'b1000000;
				4'b1011: hex7 <= 7'b0010000;
				4'b1100: hex7 <= 7'b1000000;
				4'b1101: hex7 <= 7'b1000000;
				4'b1110: hex7 <= 7'b0000000;
				4'b1111: hex7 <= 7'b1111111;
				default: hex7 <= 7'b1111111;
			endcase
		end
		
		2'b01:
		begin	
			//m_sec
			case(MsecL)
			4'b0000: hex0 <= 7'b1000000;
			4'b0001: hex0 <= 7'b1111001;
			4'b0010: hex0 <= 7'b0100100;
			4'b0011: hex0 <= 7'b0110000;
			4'b0100: hex0 <= 7'b0011001;
			4'b0101: hex0 <= 7'b0010010;
			4'b0110: hex0 <= 7'b0000010;
			4'b0111: hex0 <= 7'b1111000;
			4'b1000: hex0 <= 7'b0000000;
			4'b1001: hex0 <= 7'b0010000;
			default: hex0 <= 7'b1111111;
			endcase
			
			case(MsecH)
			4'b0000: hex1 <= 7'b1000000;
			4'b0001: hex1 <= 7'b1111001;
			4'b0010: hex1 <= 7'b0100100;
			4'b0011: hex1 <= 7'b0110000;
			4'b0100: hex1 <= 7'b0011001;
			4'b0101: hex1 <= 7'b0010010;
			4'b0110: hex1 <= 7'b0000010;
			4'b0111: hex1 <= 7'b1111000;
			4'b1000: hex1 <= 7'b0000000;
			4'b1001: hex1 <= 7'b0010000;
			default: hex1 <= 7'b1111111;
			endcase
			
			//second
			case(SecL)
			4'b0000: hex2 <= 7'b1000000;
			4'b0001: hex2 <= 7'b1111001;
			4'b0010: hex2 <= 7'b0100100;
			4'b0011: hex2 <= 7'b0110000;
			4'b0100: hex2 <= 7'b0011001;
			4'b0101: hex2 <= 7'b0010010;
			4'b0110: hex2 <= 7'b0000010;
			4'b0111: hex2 <= 7'b1111000;
			4'b1000: hex2 <= 7'b0000000;
			4'b1001: hex2 <= 7'b0010000;
			default: hex2 <= 7'b1111111;
			endcase
			
			case(SecH)
			4'b0000: hex3 <= 7'b1000000;
			4'b0001: hex3 <= 7'b1111001;
			4'b0010: hex3 <= 7'b0100100;
			4'b0011: hex3 <= 7'b0110000;
			4'b0100: hex3 <= 7'b0011001;
			4'b0101: hex3 <= 7'b0010010;
			4'b0110: hex3 <= 7'b0000010;
			4'b0111: hex3 <= 7'b1111000;
			4'b1000: hex3 <= 7'b0000000;
			4'b1001: hex3 <= 7'b0010000;
			default: hex3 <= 7'b1111111;
			endcase
			
			//minute
			case(MinL)
			4'b0000: hex4 <= 7'b1000000;
			4'b0001: hex4 <= 7'b1111001;
			4'b0010: hex4 <= 7'b0100100;
			4'b0011: hex4 <= 7'b0110000;
			4'b0100: hex4 <= 7'b0011001;
			4'b0101: hex4 <= 7'b0010010;
			4'b0110: hex4 <= 7'b0000010;
			4'b0111: hex4 <= 7'b1111000;
			4'b1000: hex4 <= 7'b0000000;
			4'b1001: hex4 <= 7'b0010000;
			default: hex4 <= 7'b1111111;
			endcase
			
			case(MinH)
			4'b0000: hex5 <= 7'b1000000;
			4'b0001: hex5 <= 7'b1111001;
			4'b0010: hex5 <= 7'b0100100;
			4'b0011: hex5 <= 7'b0110000;
			4'b0100: hex5 <= 7'b0011001;
			4'b0101: hex5 <= 7'b0010010;
			4'b0110: hex5 <= 7'b0000010;
			4'b0111: hex5 <= 7'b1111000;
			4'b1000: hex5 <= 7'b0000000;
			4'b1001: hex5 <= 7'b0010000;
			default: hex5 <= 7'b1111111;
			endcase
			
			//hour
			case(HouL)
			4'b0000: hex6 <= 7'b1000000;
			4'b0001: hex6 <= 7'b1111001;
			4'b0010: hex6 <= 7'b0100100;
			4'b0011: hex6 <= 7'b0110000;
			4'b0100: hex6 <= 7'b0011001;
			4'b0101: hex6 <= 7'b0010010;
			4'b0110: hex6 <= 7'b0000010;
			4'b0111: hex6 <= 7'b1111000;
			4'b1000: hex6 <= 7'b0000000;
			4'b1001: hex6 <= 7'b0010000;
			default: hex6 <= 7'b1111111;
			endcase
			
			case(HouH)
			4'b0000: hex7 <= 7'b1000000;
			4'b0001: hex7 <= 7'b1111001;
			4'b0010: hex7 <= 7'b0100100;
			4'b0011: hex7 <= 7'b0110000;
			4'b0100: hex7 <= 7'b0011001;
			4'b0101: hex7 <= 7'b0010010;
			4'b0110: hex7 <= 7'b0000010;
			4'b0111: hex7 <= 7'b1111000;
			4'b1000: hex7 <= 7'b0000000;
			4'b1001: hex7 <= 7'b0010000;
			default: hex7 <= 7'b1111111;	
			endcase
		end		
		
		2'b10:
		begin
			case(Data[0])
			1'b0: hex0 <= 7'b1000000;
			1'b1: hex0 <= 7'b1111001;
			default: hex0 <= 7'b1111111;
			endcase
			
			case(Data[1])
			1'b0: hex1 <= 7'b1000000;
			1'b1: hex1 <= 7'b1111001;
			default: hex1 <= 7'b1111111;
			endcase
			
			case(Data[2])
			1'b0: hex2 <= 7'b1000000;
			1'b1: hex2 <= 7'b1111001;
			default: hex2 <= 7'b1111111;
			endcase
			
			case(Data[3])
			1'b0: hex3 <= 7'b1000000;
			1'b1: hex3 <= 7'b1111001;
			default: hex3 <= 7'b1111111;
			endcase
			
			case(Data[4])
			1'b0: hex4 <= 7'b1000000;
			1'b1: hex4 <= 7'b1111001;
			default: hex4 <= 7'b1111111;
			endcase
			
			case(Data[5])
			1'b0: hex5 <= 7'b1000000;
			1'b1: hex5 <= 7'b1111001;
			default: hex5 <= 7'b1111111;
			endcase
			
			case(Data[6])
			1'b0: hex6 <= 7'b1000000;
			1'b1: hex6 <= 7'b1111001;
			default: hex6 <= 7'b1111111;
			endcase
			
			case(Data[7])
			1'b0: hex7 <= 7'b1000000;
			1'b1: hex7 <= 7'b1111001;
			default: hex7 <= 7'b1111111;
			endcase
		end
		
		2'b11:
		begin
			case(count)
			4'b0000:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111110;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0001:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111110;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0010:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1111110;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0011:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1110110;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0100:
				begin
				hex0 <= 7'b1111110;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0101:
				begin
				hex0 <= 7'b1111101;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0110:
				begin
				hex0 <= 7'b1111011;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b0111:
				begin
				hex0 <= 7'b1110111;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b1000:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1110111;
				hex2 <= 7'b1110111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b1001:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1110111;
				hex3 <= 7'b1110111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b1010:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1100111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b0111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b1011:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1101111;
				hex4 <= 7'b0111111;
				hex5 <= 7'b0111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			4'b1100:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b0111111;
				hex5 <= 7'b0101111;
				hex6 <= 7'b1110111;
				hex7 <= 7'b1111111;	
				end
			4'b1101:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b0101111;
				hex6 <= 7'b1110111;
				hex7 <= 7'b1110110;	
				end
			4'b1110:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1101111;
				hex6 <= 7'b1110111;
				hex7 <= 7'b1100110;	
				end
			4'b1111:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1110111;
				hex7 <= 7'b1000110;	
				end
			default:
				begin
				hex0 <= 7'b1111111;
				hex1 <= 7'b1111111;
				hex2 <= 7'b1111111;
				hex3 <= 7'b1111111;
				hex4 <= 7'b1111111;
				hex5 <= 7'b1111111;
				hex6 <= 7'b1111111;
				hex7 <= 7'b1111111;	
				end
			endcase
		end
		
	default: 
		begin
		hex0 <= 7'b1111111;
		hex1 <= 7'b1111111;
		hex2 <= 7'b1111111;
		hex3 <= 7'b1111111;
		hex4 <= 7'b1111111;
		hex5 <= 7'b1111111;
		hex6 <= 7'b1111111;
		hex7 <= 7'b1111111;	
		end
	endcase
end
		
endmodule

//秒表时钟
module WatchClk(
	input clk,nCR,
	output reg clock
);

reg[18:0] count;

always@(posedge clk or negedge nCR)
begin 
	if(~nCR)	count<=19'h0;
	else if(count[18]==1'b1)
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

//显示时钟
module ShowClk(
	input clk,nCR,
	output reg clock
);

reg[24:0] count;

always@(posedge clk or negedge nCR)
begin 
	if(~nCR)	count<=25'h0;
	else if(count[24]==1'b1)
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

//10进制计数器
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

//the counter of 6
module counter6(
	input CP,nCR,EN,
	output reg[3:0]Q
);
always@(posedge CP,negedge nCR)
begin
	if(~nCR) 					Q<=4'b0000;
	else if(~EN)  				Q<=Q;
	else if(Q==4'b0101) 		Q<=4'b0000;
	else							Q<=Q+1'b1;
end
endmodule

//用于显示左移
module Shift(
	input Clk,En,
	input[7:0] Data,
	output reg[7:0] data
);

reg[2:0] cnt;

always@(posedge Clk)
begin
	if(~En)
	cnt<=2'b00;
	else
	cnt<=cnt+2'b1;
end

always@(posedge Clk)
begin
	case(cnt)
	3'b000:data<=Data;		
	3'b001:data<={Data[6:0],Data[7]};
	3'b010:data<={Data[5:0],Data[7:6]};
	3'b011:data<={Data[4:0],Data[7:5]};	
	3'b100:data<={Data[3:0],Data[7:4]};
	3'b101:data<={Data[2:0],Data[7:3]};	
	3'b110:data<={Data[1:0],Data[7:2]};
	3'b111:data<={Data[0],Data[7:1]};
	endcase	
end
endmodule	

//16进制计数器
module Count_play(
	input EN,Clk,nCR,
	output reg[3:0] Count
);
always@(posedge Clk)
begin
if(~nCR)
	Count<=4'b0000;
else if(~EN)
	Count=Count;
else
	Count=Count+4'b1;
end
endmodule


//消抖动模块
module Key(
	input clk,
	input Key_In,
	output reg Key_Out
);

/*always@(posedge clk)
begin
	if(~Key_In) Key_Out<=~Key_Out;
	else			Key_Out<=Key_Out;
end
endmodule*/

reg[20:0] count;
reg flag;

always@(posedge clk)
begin
	if(~Key_In)	
		begin
		if(~flag)
			begin
			flag<=1'b1;
			count<=21'b0;
			end
		else if(count[20]==1'b1)
			begin
			Key_Out<=~Key_Out;
			count<=21'b0;		
			flag<=1'b0;
			end
		else
			begin
			Key_Out<=Key_Out;
			count<=count+1'b1;
			end
		end
	else 
		begin
		if(count[20]==1'b1) 
			begin
			if(flag)	flag<=1'b0;
			count<=21'b0;
			Key_Out<=Key_Out;
			end
		else
			begin
			Key_Out<=Key_Out;
			count<=count+1'b1;
			end
		end
end
endmodule

/*
//功能00显示模块
module show_fun0 ( 
	input [3:0] show,
	output reg [6:0] hex
);
	
always@(*)
begin
	case(show)
	4'b0000: hex <= 7'b0010010;
	4'b0001: hex <= 7'b1110001;
	4'b0010: hex <= 7'b1001110;
	4'b0011: hex <= 7'b1000001;
	4'b0100: hex <= 7'b1110111;
	4'b0101: hex <= 7'b1111000;
	4'b0110: hex <= 7'b1111001;
	4'b0111: hex <= 7'b0110000;
	4'b1000: hex <= 7'b1000000;
	4'b1001: hex <= 7'b0110000;
	4'b1010: hex <= 7'b1000000;
	4'b1011: hex <= 7'b0010000;
	4'b1100: hex <= 7'b1000000;
	4'b1101: hex <= 7'b1000000;
	4'b1110: hex <= 7'b0000000;
	4'b1111: hex <= 7'b1111111;
	default: hex <= 7'b1111111;
	endcase
end

endmodule

//功能01显示模块
module show_fun1(
		input[3:0] data,
		output reg[6:0] digital
);

always@(*)
	case(data)
		4'b0000:digital<=7'b1000000;
		4'b0001:digital<=7'b1111001;
		4'b0010:digital<=7'b0100100;
		4'b0011:digital<=7'b0110000;
		4'b0100:digital<=7'b0011001;
		4'b0101:digital<=7'b0010010;
		4'b0110:digital<=7'b0000010;
		4'b0111:digital<=7'b1111000;
		4'b1000:digital<=7'b0000000;
		4'b1001:digital<=7'b0010000;
		default:digital<=7'b1111111;
	endcase
endmodule

//功能10显示模块	
module show_fun2(
	input data,
	output reg [6:0] digital
)	

always@(*)
begin
	case(data)
	1'b0:digital<=7'b1000000;
	1'b1:digital<=7'b1111001;
	default: hex0 <= 7'b1111111;
	endcase
end

endmodule

//功能11显示模块
module show_fun3_hex0(
	input [4:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(Count[4:0])
	4'b0100: digital <= 7'b1111110;
	4'b0101: digital <= 7'b1111101;
	4'b0110: digital <= 7'b1111011;
	4'b0111: digital <= 7'b1110111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex1(
	input [3:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b0010: digital <= 7'b1110111;
	4'b0100: digital <= 7'b1110111;
	4'b0101: digital <= 7'b1110111;
	4'b0110: digital <= 7'b1110111;
	4'b0111: digital <= 7'b1110111;
	4'b1000: digital <= 7'b1110111;
	4'b0011: digital <= 7'b1110110;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex2(
	input [4:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b0010: digital <= 7'b1111110;
	4'b1000: digital <= 7'b1110111; 
	4'b1001: digital <= 7'b1110111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex3(
	input [4:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b0001: digital <= 7'b1111110;
	4'b1001: digital <= 7'b1110111;
	4'b1010: digital <= 7'b1100111;
	4'b1011: digital <= 7'b1101111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex4(
	input [4:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b0000: digital <= 7'b1111110;
	4'b1011: digital <= 7'b0111111;
	4'b1100: digital <= 7'b0111111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex5(
	input [4:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b1101: digital <= 7'b1111110;
	4'b1100: digital <= 7'b0101111;
	4'b1101: digital <= 7'b0101111;
	4'b1110: digital <= 7'b1101111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex6(
	input [3:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b1001: digital <= 7'b1110111;
	4'b1100: digital <= 7'b1110111;
	4'b1101: digital <= 7'b1110111;
	4'b1110: digital <= 7'b1110111;
	4'b1111: digital <= 7'b1110111;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	

module show_fun3_hex7(
	input [3:0] count,
	output reg[6:0] digital
);

always@(*)
begin
	case(count)
	4'b1101: digital <= 7'b1110110;
	4'b1110: digital <= 7'b1100110;
	4'b1111: digital <= 7'b1000110;
	default: digital <= 7'b1111111;
	endcase
end

endmodule	
*/

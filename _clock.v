//multifunctional stopwatch
//designed by XiaoNing(7130309008)
//May,2015

module clock(
	input clk,reset,EN,
	output wire[6:0] hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7,
	output LED0,LED1
);

wire[3:0] MsecL,MsecH,SecL,SecH,MinL,MinH,HouL,HouH;
wire MsecL_EN,MsecH_EN,SecL_EN,SecH_EN,MinL_EN,MinH_EN,HouL_EN,HouH_EN;
wire clock;
wire Key_reset,Key_EN;


/***************************************************/
/***************************************************/

DivClk S(.clk(clk),.clock(clock));

assign LED0=Key_EN;
assign LED1=Key_reset;
Key M1(.clk(clk),.Key_In(reset),.Key_Out(Key_reset));
Key M2(.clk(clk),.Key_In(EN),.Key_Out(Key_EN));


assign Key_reset_now=Key_reset;
assign Key_EN_now=Key_EN;
/***************************************************/
/***************************************************/
//COUNTER
//m_second
assign MsecL_EN=Key_EN;
assign MsecH_EN=(MsecL==4'h9);
counter10 U1(.Q(MsecL),.CP(clock),.nCR(Key_reset),.EN(MsecL_EN));
counter10 U2(.Q(MsecH),.CP(clock),.nCR(Key_reset),.EN(MsecH_EN));
//second
assign SecL_EN=(MsecL==4'h9&&MsecH==4'h9);
assign SecH_EN=(SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U3(.Q(SecL),.CP(clock),.nCR(Key_reset),.EN(SecL_EN));
counter6  U4(.Q(SecH),.CP(clock),.nCR(Key_reset),.EN(SecH_EN));
//minute
assign MinL_EN=(SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
assign MinH_EN=(MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U5(.Q(MinL),.CP(clock),.nCR(Key_reset),.EN(MinL_EN));
counter6  U6(.Q(MinH),.CP(clock),.nCR(Key_reset),.EN(MinH_EN));
//hour
assign HouL_EN=(MinH==4'h5&&MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
assign HouH_EN=(HouL==4'h9&&MinH==4'h5&&MinL==4'h9&&SecH==4'h5&&SecL==4'h9&&MsecL==4'h9&&MsecH==4'h9);
counter10 U7(.Q(HouL),.CP(clock),.nCR(Key_reset),.EN(HouL_EN));
counter10 U8(.Q(HouH),.CP(clock),.nCR(Key_reset),.EN(HouH_EN));
/***************************************************/
/***************************************************/
//SHOW
//m_sec
show S1(.data(MsecL),.digital(hex0));
show S2(.data(MsecH),.digital(hex1));
//second
show S3(.data(SecL),.digital(hex2));
show S4(.data(SecH),.digital(hex3));
//minute
show S5(.data(MinL),.digital(hex4));
show S6(.data(MinH),.digital(hex5));
//hour
show S7(.data(HouL),.digital(hex6));
show S8(.data(HouH),.digital(hex7));

endmodule


//the counter of 10
module counter10(
	input CP,nCR,EN,
	output reg[3:0]Q
);
always@(posedge CP,negedge nCR)
begin
	if(~nCR) 					Q<=4'b0000;
	else if(~EN)  				Q<=Q;
	else if(Q==4'b1001)		Q<=4'b0000;
	else							Q<=Q+1'b1;
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

//the module of show number
module show(
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

//the clock of count
module DivClk(
	input clk,
	output reg clock
);

reg[18:0] count;

always@(posedge clk)
begin 
	if(count[18]==1'b1)
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
	
	
	
	
	
	
	

//computer architecture
module sc_computer (resetn,mem_clk,io_mem0,io_mem1,operand1_L,operand1_H,operand2_L,operand2_H,result_L,result_H);
   
   input resetn,mem_clk;
	input  [4:0] io_mem0,io_mem1;
   wire [31:0] pc,inst,aluout,memout; //
   wire        imem_clk,dmem_clk;   //
	output wire [6:0]  operand1_L,operand1_H,operand2_L,operand2_H,result_L,result_H;
   wire   [31:0] data;
   wire          wmem; // all these "wire"s are used to connect or interface the cpu,dmem,imem and so on.
   wire   clock;
	wire   [31:0] result;
	
	
	DivClk  V1(mem_clk,resetn,clock);
	show_operand_L  S1(io_mem0,operand1_L);
	show_operand_H  S2(io_mem0,operand1_H);
	show_operand_L  S3(io_mem1,operand2_L);
	show_operand_H	 S4(io_mem1,operand2_H);
	show_result_L   S5(result[5:0],result_L);
	show_result_H	 S6(result[5:0],result_H);
	
   sc_cpu cpu (clock,resetn,inst,memout,pc,wmem,aluout,data);          // CPU module.
   sc_instmem  imem (pc,inst,clock,mem_clk,imem_clk);                  // instruction memory.
   sc_datamem  dmem (aluout,data,memout,wmem,clock,mem_clk,dmem_clk,io_mem0,io_mem1,result); // data memory.

endmodule
 
//sc_cpu
module sc_cpu (clock,resetn,inst,mem,pc,wmem,alu,data);
   input [31:0] inst,mem;
   input clock,resetn;
   output [31:0] pc,alu,data;
   output wmem;
   
   wire [31:0]   p4,bpc,npc,adr,ra,alua,alub,res,alu_mem;
   wire [3:0]    aluc;
   wire [4:0]    reg_dest,wn;
   wire [1:0]    pcsource;
   wire          zero,wmem,wreg,regrt,m2reg,shift,aluimm,jal,sext;
   wire [31:0]   sa = { 27'b0, inst[10:6] }; // extend to 32 bits from sa for shift instruction
   wire [31:0]   offset = {imm[13:0],inst[15:0],1'b0,1'b0};   //offset(include sign extend)
   wire          e = sext & inst[15];          // positive or negative sign at sext signal
   wire [15:0]   imm = {16{e}};                // high 16 sign bit
   wire [31:0]   immediate = {imm,inst[15:0]}; // sign extend to high 16
   
   dff32 ip (npc,clock,resetn,pc);  // define a D-register for PC
									// make sure this is a single-cycle machine
   assign p4 = pc + 32'h4;       // modified
   assign adr = p4 + offset;     // modified
   
   wire [31:0] jpc = {p4[31:28],inst[25:0],1'b0,1'b0}; // j address 
   
   sc_cu cu (inst[31:26],inst[5:0],zero,wmem,wreg,regrt,m2reg,
                        aluc,shift,aluimm,pcsource,jal,sext);
                        
                        
   mux2x32 alu_b (data,immediate,aluimm,alub);
   mux2x32 alu_a (ra,sa,shift,alua);
   mux2x32 result(alu,mem,m2reg,alu_mem);
   mux2x32 link (alu_mem,p4,jal,res);
   mux2x5  reg_wn (inst[15:11],inst[20:16],regrt,reg_dest);
   assign  wn = reg_dest | {5{jal}}; // jal: r31 <-- p4;      // 31 or reg_dest
   mux4x32 nextpc(p4,adr,ra,jpc,pcsource,npc);
   regfile rf (inst[25:21],inst[20:16],res,wn,wreg,clock,resetn,ra,data);
   alu     al_unit (alua,alub,aluc,alu,zero);
endmodule 

//instruction memory
module sc_instmem (addr,inst,clock,mem_clk,imem_clk);
   input  [31:0] addr;//pc
   input         clock;
   input         mem_clk;
   output [31:0] inst;
   output        imem_clk;
   
   wire          imem_clk;

   assign  imem_clk = clock & ( ~ mem_clk );      
   
   lpm_rom_irom irom (addr[7:2],imem_clk,inst); 
   

endmodule 

//data memory
module sc_datamem (addr,datain,dataout,we,clock,mem_clk,dmem_clk,io_mem0,io_mem1,result);
 
   input  [31:0]  addr;
   input  [31:0]  datain;
	input  [4:0]	io_mem0,io_mem1;
   
   input          we, clock,mem_clk;
   output [31:0]  dataout;
   output         dmem_clk;
	output reg[31:0]  result;
	wire   [31:0]  dataout1;
	reg    [31:0]  dataout2;
   
   wire           dmem_clk;    
   wire           write_enable; 
   assign         write_enable = we & ~clock; 
   
   assign         dmem_clk = mem_clk & ( ~ clock) ; 
   assign 			dataout=addr[7]?dataout2:dataout1;
	
   lpm_ram_dq_dram  dram(addr[6:2],dmem_clk,datain,write_enable,dataout1 );

always@(*)	
begin
	if(write_enable)
		begin
		if(addr[7]==1'b1&&addr[3:2]==2'b10) result=datain;
		end
	else
		begin
		if(addr[7]==1'b1)
			begin
			if(addr[2]==1'b0) dataout2={27'b0,io_mem0};
			else					dataout2={27'b0,io_mem1};
			end
		end
end

endmodule 

//lpm_ram_dq_dram
module lpm_ram_dq_dram (
	address,
	clock,
	data,
	wren,
	q);

	input	[4:0]  address;
	input	  clock;
	input	[31:0]  data;
	input	  wren;
	output	[31:0]  q;

	wire [31:0] sub_wire0;
	wire [31:0] q = sub_wire0[31:0];

	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (address),
				.data_a (data),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "C:/Users/Administrator.6V3ICFXODYJ485K/Desktop/sc_computer_student/source/sc_datamem.mif",
		altsyncram_component.intended_device_family = "Stratix II",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.width_a = 32,
		altsyncram_component.width_byteena_a = 1;


endmodule

//lpm_rom_irom
module lpm_rom_irom (
	address,
	clock,
	q);

	input	[5:0]  address;
	input	  clock;
	output	[31:0]  q;

	wire [31:0] sub_wire0;
	wire [31:0] q = sub_wire0[31:0];

	altsyncram	altsyncram_component (
				.clock0 (clock),
				.address_a (address),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_a ({32{1'b1}}),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_a (1'b0),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.init_file = "C:/Users/Administrator.6V3ICFXODYJ485K/Desktop/sc_computer_student/source/sc_instmem.mif",
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 64,
		altsyncram_component.operation_mode = "ROM",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 32,
		altsyncram_component.width_byteena_a = 1;


endmodule

//sc_cu
module sc_cu (op, func, z, wmem, wreg, regrt, m2reg, aluc, shift,
              aluimm, pcsource, jal, sext);
   input  [5:0] op,func;
   input        z;
   output       wreg,regrt,jal,m2reg,shift,aluimm,sext,wmem;
   output [3:0] aluc;
   output [1:0] pcsource;
   wire r_type = ~|op;
   wire i_add = r_type &  func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //100000
   wire i_sub = r_type &  func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //100010 
   wire i_and = r_type &  func[5] & ~func[4] & ~func[3] &
                 func[2] & ~func[1] & ~func[0];          //100100
   wire i_or  = r_type &  func[5] & ~func[4] & ~func[3] &
                 func[2] & ~func[1] &  func[0];         //100101
   wire i_xor = r_type &  func[5] & ~func[4] & ~func[3] &
                 func[2] &  func[1] & ~func[0];          //100110
   wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //000000
   wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //000010
   wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] &  func[0];          //000011
   wire i_jr  = r_type & ~func[5] & ~func[4] &  func[3] &
                ~func[2] & ~func[1] & ~func[0];          //001000
                
   wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0]; //001000
   wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0]; //001100
   wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] &  op[0]; //001101         
   wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] & ~op[0]; //001110   
   wire i_lw   =  op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //100011  
   wire i_sw   =  op[5] & ~op[4] &  op[3] & ~op[2] &  op[1] &  op[0]; //101011
   wire i_beq  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & ~op[0]; //000100
   wire i_bne  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] &  op[0]; //000101
   wire i_lui  = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] &  op[0]; //001111
   wire i_j    = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] & ~op[0]; //000010
   wire i_jal  = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //000011
   
  
   assign pcsource[1] = i_jr | i_j | i_jal;
   assign pcsource[0] = ( i_beq & z ) | (i_bne & ~z) | i_j | i_jal ;
   
   assign wreg = i_add | i_sub | i_and | i_or   | i_xor  |
                 i_sll | i_srl | i_sra | i_addi | i_andi |
                 i_ori | i_xori | i_lw | i_lui  | i_jal;
   
   assign aluc[3] = i_sra;  
   assign aluc[2] = i_sub | i_or | i_srl | i_sra | i_ori | i_lui;
   assign aluc[1] = i_xor | i_sll | i_srl | i_sra | i_xori | i_lui;
   assign aluc[0] = i_and | i_or |  i_sll | i_srl | i_sra | i_andi | i_ori;
   assign shift   = i_sll | i_srl | i_sra ;

   assign aluimm  = i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_lui;
   assign sext    = i_addi | i_ori | i_xori | i_lw | i_sw | i_beq | i_bne | i_lui;
   assign wmem    = i_sw;
   assign m2reg   = i_lw | i_sw;
   assign regrt   = i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_lui;
   assign jal     = i_jal;

endmodule

//mux2x32
module mux2x32 (a0,a1,s,y);

   input [31:0] a0,a1;
   input        s;
   
   output [31:0] y;
   
   assign y = s ? a1 : a0;
   
endmodule

//mux2x5
module mux2x5 (a0,a1,s,y);

   input [4:0] a0,a1;
   input        s;
   
   output [4:0] y;
   
   assign y = s ? a1 : a0;
   
endmodule


//mux4x32 
module mux4x32 (a0,a1,a2,a3,s,y);

   input [31:0]  a0,a1,a2,a3;
   input [ 1:0]  s;
   
   output [31:0] y;
   reg [31:0] y;
   always @ *
   case (s)
   
      2'b00: y = a0;
      2'b01: y = a1;
      2'b10: y = a2;
      2'b11: y = a3;
   
   endcase
endmodule 

//regfile
module regfile (rna,rnb,d,wn,we,clk,clrn,qa,qb);
   input [4:0] rna,rnb,wn;
   input [31:0] d;
   input we,clk,clrn;
   
   output [31:0] qa,qb;
   
   reg [31:0] register [1:31]; // r1 - r31
   
   assign qa = (rna == 0)? 0 : register[rna]; // read
   assign qb = (rnb == 0)? 0 : register[rnb]; // read

   always @(posedge clk or negedge clrn) begin
      if (clrn == 0) begin // reset
         integer i;
         for (i=1; i<32; i=i+1)
            register[i] <= 0;
      end else begin
         if ((wn != 0) && (we == 1))          // write
            register[wn] <= d;
      end
   end
endmodule

//alu
module alu (a,b,aluc,s,z);
   input [31:0] a,b;
   input [3:0] aluc;
   output [31:0] s;
   output        z;
   reg [31:0] s;
   reg        z;
   always @ (a or b or aluc) 
      begin                                   // event
         casex (aluc)
             4'bx000: s = a + b;              //x000 ADD
             4'bx100: s	= a - b;              //x100 SUB
             4'bx001: s = a & b;          	  //x001 AND
             4'bx101: s = a | b;              //x101 OR
             4'bx101: s = a ^ b;              //x010 XOR
             4'bx110: s = a << 16;            //x110 LUI: imm << 16bit             
             4'b0011: s = b << a;             //0011 SLL: rd <- (rt << sa)
             4'b1111: s = b >> a;             //0111 SRL: rd <- (rt >> sa) (logical)
             4'b1111: s = $signed(b) >>> a;   //1111 SRA: rd <- (rt >> sa) (arithmetic)
             default: s = 0;
         endcase
         if (s == 0 )  z = 1;
         else 		   z = 0;         
      end      
endmodule 

//dff32
module dff32 (d,clk,clrn,q);
   input  [31:0] d;
   input  clk,clrn;
   output [31:0] q;
   reg 	 [31:0] q;
   always @ (negedge clrn or posedge clk)
      if (clrn == 0) begin
          // q <=0;
          q <= -4;
      end else begin
          q <= d;
      end
endmodule

module show_operand_L(
		input[4:0] data,
		output reg[6:0] digital
);

always@(*)
	case(data%4'b1010)
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

module show_operand_H(
		input[4:0] data,
		output reg[6:0] digital
);

always@(*)
	case(data/4'b1010)
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

module show_result_L(
		input[5:0] data,
		output reg[6:0] digital
);

always@(*)
	case(data%4'b1010)
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

module show_result_H(
		input[5:0] data,
		output reg[6:0] digital
);

always@(*)
	case(data/4'b1010)
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

module DivClk(
	input clk,nCR,
	output reg clock
);

reg count;

always@(posedge clk or negedge nCR)
begin 
	if(~nCR)	count<=1'b0;
	else if(count==1'b1)
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
module cpu_pipeline (resetn,clk,io_mem0,io_mem1,operand1_L,
							operand1_H,operand2_L,operand2_H,result_L,result_H
							,result);
							
	input resetn, clk;
//定义整个计算机 module 和外界交互的输入信号，包括复位信号 resetn、时钟信号 clock、
//以及一个和 clock 同频率但反相的 mem_clock 信号。 mem_clock 用于指令同步 ROM 和
//数据同步 RAM 使用，其波形需要有别于实验一。
//这些信号可以用作仿真验证时的输出观察信号。
	input  [4:0] io_mem0,io_mem1;
	output [31:0] result;//test
	wire [31:0] pc,ealu;//用来测试的变量
	output wire [6:0]  operand1_L,operand1_H,operand2_L,operand2_H,result_L,result_H;
//模块用于仿真输出的观察信号。缺省为 wire 型。
	wire [31:0] bpc,jpc,npc,pc4,ins, inst;
//模块间互联传递数据或控制信息的信号线,均为 32 位宽信号。 IF 取指令阶段。
	wire [31:0] dpc4,da,db,dim;
//模块间互联传递数据或控制信息的信号线,均为 32 位宽信号。 ID 指令译码阶段。
	wire [31:0] epc4,ea,eb,eimm;
//模块间互联传递数据或控制信息的信号线,均为 32 位宽信号。 EXE 指令运算阶段。
	wire [31:0] mb,mmo;
//模块间互联传递数据或控制信息的信号线,均为 32 位宽信号。 MEM 访问数据阶段。
	wire [31:0] wmo,wdi;
//模块间互联传递数据或控制信息的信号线,均为 32 位宽信号。 WB 回写寄存器阶段。
	wire [4:0] drn,ern0,ern,mrn,wrn;
//模块间互联，通过流水线寄存器传递结果寄存器号的信号线，寄存器号（ 32 个）为 5bit。
	wire [3:0] daluc,ealuc;
//ID 阶段向 EXE 阶段通过流水线寄存器传递的 aluc 控制信号， 4bit。
	wire [1:0] pcsource;
//CU 模块向 IF 阶段模块传递的 PC 选择信号， 2bit。
	wire wpcir;
// CU 模块发出的控制流水线停顿的控制信号，使 PC 和 IF/ID 流水线寄存器保持不变。
	wire dwreg,dm2reg,dwmem,daluimm,dshift,djal; // id stage
// ID 阶段产生，需往后续流水级传播的信号。
	wire ewreg,em2reg,ewmem,ealuimm,eshift,ejal; // exe stage
//来自于 ID/EXE 流水线寄存器， EXE 阶段使用，或需要往后续流水级传播的信号。
	wire mwreg,mm2reg,mwmem; // mem stage
//来自于 EXE/MEM 流水线寄存器， MEM 阶段使用，或需要往后续流水级传播的信号。
	wire wwreg,wm2reg; // wb stage
//来自于 MEM/WB 流水线寄存器， WB 阶段使用的信号。
	wire [31:0] malu,dimm,walu;
	
	wire [31:0] result;
	wire clock;
	wire mem_clock;
	assign mem_clock=~clock;
	
	DivClk  V1(clk,resetn,clock);
	show_operand_L  S1(io_mem0,operand1_L);
	show_operand_H  S2(io_mem0,operand1_H);
	show_operand_L  S3(io_mem1,operand2_L);
	show_operand_H	 S4(io_mem1,operand2_H);
	show_result_L   S5(result[5:0],result_L);
	show_result_H	 S6(result[5:0],result_H);
	
//内存时钟是时钟的反向
	pipepc prog_cnt ( npc,wpcir,clock,resetn,pc );
//程序计数器模块，是最前面一级 IF 流水段的输入。
	pipeif if_stage ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,mem_clock ); // IF stage
//IF 取指令模块，注意其中包含的指令同步 ROM 存储器的同步信号，
//即输入给该模块的 mem_clock 信号，模块内定义为 rom_clk。 // 注意 mem_clock。
//实验中可采用系统 clock 的反相信号作为 mem_clock（亦即 rom_clock） ,
//即留给信号半个节拍的传输时间。
	pipeir inst_reg ( pc4,ins,wpcir,clock,resetn,dpc4,inst ); // IF/ID 流水线寄存器
//IF/ID 流水线寄存器模块，起承接 IF 阶段和 ID 阶段的流水任务。
//在 clock 上升沿时，将 IF 阶段需传递给 ID 阶段的信息，锁存在 IF/ID 流水线寄存器
//中，并呈现在 ID 阶段。
	pipeid id_stage ( mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,
							wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
						bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
									daluimm,da,db,dimm,drn,dshift,djal ); // ID stage
//ID 指令译码模块。注意其中包含控制器 CU、寄存器堆、及多个多路器等。
//其中的寄存器堆，会在系统 clock 的下沿进行寄存器写入，也就是给信号从 WB 阶段
//传输过来留有半个 clock 的延迟时间，亦即确保信号稳定。
//该阶段 CU 产生的、要传播到流水线后级的信号较多。
	pipedereg de_reg ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,dshift,
						djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,ealuc,ealuimm,
							ea,eb,eimm,ern0,eshift,ejal,epc4 ); // ID/EXE 流水线寄存器
//ID/EXE 流水线寄存器模块，起承接 ID 阶段和 EXE 阶段的流水任务。
//在 clock 上升沿时，将 ID 阶段需传递给 EXE 阶段的信息，锁存在 ID/EXE 流水线
//寄存器中，并呈现在 EXE 阶段。
	pipeexe exe_stage ( ealuc,ealuimm,ea,eb,eimm,eshift,ern0,epc4,ejal,ern,ealu ); // EXE stage
//EXE 运算模块。其中包含 ALU 及多个多路器等。 
	pipeemreg em_reg ( ewreg,em2reg,ewmem,ealu,eb,ern,clock,resetn,
	mwreg,mm2reg,mwmem,malu,mb,mrn); // EXE/MEM 流水线寄存器

//EXE/MEM 流水线寄存器模块，起承接 EXE 阶段和 MEM 阶段的流水任务。
//在 clock 上升沿时，将 EXE 阶段需传递给 MEM 阶段的信息，锁存在 EXE/MEM
//流水线寄存器中，并呈现在 MEM 阶段。
	pipemem mem_stage ( mwmem,malu,mb,clock,mem_clock,mmo,io_mem0,io_mem1,result); // MEM stage
//MEM 数据存取模块。其中包含对数据同步 RAM 的读写访问。 // 注意 mem_clock。
//输入给该同步 RAM 的 mem_clock 信号，模块内定义为 ram_clk。
//实验中可采用系统 clock 的反相信号作为 mem_clock 信号（亦即 ram_clk） ,
//即留给信号半个节拍的传输时间，然后在 mem_clock 上沿时，读输出、或写输入。
	pipemwreg mw_reg ( mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
								wwreg,wm2reg,wmo,walu,wrn); // MEM/WB 流水线寄存器
//MEM/WB 流水线寄存器模块，起承接 MEM 阶段和 WB 阶段的流水任务。
//在 clock 上升沿时，将 MEM 阶段需传递给 WB 阶段的信息，锁存在 MEM/WB
//流水线寄存器中，并呈现在 WB 阶段。
	mux2x32 wb_stage ( walu,wmo,wm2reg,wdi ); // WB stage
//WB 写回阶段模块。事实上，从设计原理图上可以看出，该阶段的逻辑功能部件只
//包含一个多路器，所以可以仅用一个多路器的实例即可实现该部分。
//当然，如果专门写一个完整的模块也是很好的。
endmodule


//pipepc
module pipepc(npc,wpcir,clock,resetn,pc);

	input	[31:0]npc;
	input wpcir,clock,resetn;
	output reg[31:0] pc;
	
always @ (negedge resetn or posedge clock)
begin
	if(~resetn)
		pc <= 0;
	else if(~wpcir)
		pc <= pc ;
	else	
		pc <= npc;
end

endmodule


//pipeif
module pipeif( pcsource,pc,bpc,da,jpc,npc,pc4,ins,mem_clock);

	input [1:0] pcsource;
	input mem_clock;
	input [31:0] jpc,bpc,pc,da;
	output [31:0] npc,pc4,ins;
	
	assign pc4 = pc + 4;
	mux4x32 nextpc(pc4,bpc,da,jpc,pcsource,npc);
	lpm_rom_irom irom (pc[7:2],mem_clock,ins);
		
endmodule

//pipeir  IF/ID
module pipeir (pc4,ins,wpcir,clock,resetn,dpc4,inst );

	input [31:0] pc4,ins;
	input wpcir,clock,resetn;
	output reg[31:0] dpc4,inst;
	
always @(posedge clock)
begin
	if(~resetn)
		begin
			dpc4 <= 0;
			inst <= 0;
		end
	else if(~wpcir)
		begin
			dpc4 <= dpc4;
			inst <= inst;
		end
	else 
	   begin
			dpc4 <= pc4;
			inst <= ins;
		end
end
	
endmodule
		
//pipeid  decode
module pipeid(mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,
						wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
					bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
						daluimm,da,db,dimm,drn,dshift,djal);		
						
	input [31:0] dpc4, inst, ealu, malu, mmo, wdi;
	input [4:0] ern, mrn, wrn;
	input clock, resetn, em2reg, ewreg, mm2reg, mwreg, wwreg;
	output [31:0] bpc, jpc, da, db, dimm;
	output [4:0] drn;
	output [3:0] daluc;
	output [1:0] pcsource;
	output wpcir, dwreg, dm2reg, dwmem, djal, daluimm, dshift;
	
	wire [31:0] offset, q1, q2;
	wire [15:0] imm, ext_16;
	wire [5:0] op, func;
	wire [4:0] rs, rt, rd;
	wire [1:0] fwda, fwdb;
	wire rsrtequ, regrt, sext, e;
		
	assign op = inst[31:26];
	assign func = inst[5:0];
	assign rs = inst[25:21];
	assign rt = inst[20:16];
	assign rd = inst[15:11];
	assign imm = inst[15:0];
	assign e = sext & inst[15];
	assign ext_16 = {16{e}};
	assign offset = {ext_16[13:0], imm, 2'b00};
	assign bpc = dpc4 + offset;
	assign jpc = {dpc4[31:28], inst[25:0], 2'b00};
	assign rsrtequ = (da == db);
	assign dimm = {ext_16, imm};
	
	pipe_cu control_unit (mrn, mm2reg, mwreg, ern, em2reg, ewreg, rsrtequ, op, 
								func, rs, rt, dwreg, dm2reg, dwmem, djal, daluc, daluimm, 
								dshift, regrt, sext, fwdb, fwda, pcsource, wpcir);
	regfile rf (rs, rt, wdi, wrn, wwreg, ~clock, resetn, q1, q2);
	mux4x32 alu_a (q1, ealu, malu, mmo, fwda, da);
	mux4x32 alu_b (q2, ealu, malu, mmo, fwdb, db);
	mux2x5 des_reg_no (rd, rt, regrt, drn);
	
endmodule
				
//pipedereg     ID/EXE
module pipedereg (dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,dshift,
						djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,ealuc,ealuimm,
						ea,eb,eimm,ern0,eshift,ejal,epc4);	

	input dwreg, dm2reg, dwmem, djal, daluimm, dshift;
	input [3:0] daluc;
	input [31:0] dpc4, da, db, dimm;
	input [4:0] drn;
	input clock, resetn;
	output ewreg, em2reg, ewmem, ejal, ealuimm, eshift;
	output [3:0] ealuc;
	output [31:0] epc4, ea, eb, eimm;
	output [4:0] ern0;
	reg ewreg, em2reg, ewmem, ejal, ealuimm, eshift;
	reg [3:0] ealuc;
	reg [31:0] epc4, ea, eb, eimm;
	reg [4:0] ern0;
	
always @(posedge clock)
begin
	if (~resetn)
		begin
		ewreg <= 0;
		em2reg <= 0;
		ewmem <= 0;
		ealuc <= 0;
		ealuimm <= 0;
		ea <= 0;
		eb <= 0;
		eimm <= 0; 
		ern0 <= 0;
		eshift <= 0;
		ejal <= 0; 		
		epc4 <= 0;
		end
	else
		begin
		ewreg <= dwreg;
		em2reg <= dm2reg;
		ewmem <= dwmem;
		ealuc <= daluc;
		ealuimm <= daluimm;
		ea <= da;
		eb <= db;
		eimm <= dimm; 
		ern0 <= drn;
		eshift <= dshift;
		ejal <= djal; 		
		epc4 <= dpc4;
		end
end

endmodule	

//pipemwreg     EXE/MEM
module pipeemreg (ewreg,em2reg,ewmem,ealu,eb,ern,clock,resetn,
							mwreg,mm2reg,mwmem,malu,mb,mrn);	
							
	input ewreg, em2reg, ewmem;
	input [31:0] ealu, eb;
	input [4:0] ern;
	input clock, resetn;
	output mwreg, mm2reg, mwmem;
	output [31:0] malu, mb;
	output [4:0] mrn;
	reg mwreg, mm2reg, mwmem;
	reg [31:0] malu, mb;
	reg [4:0] mrn;
	
always @(posedge clock)
begin
	if (~resetn)
		begin
		mwreg <= 0;
		mm2reg <= 0;
		mwmem <= 0;
		malu <= 0;
		mb <= 0;
		mrn <= 0;
		end
	else
		begin
		mwreg <= ewreg;
		mm2reg <= em2reg;
		mwmem <= ewmem;
		malu <= ealu;
		mb <= eb;
		mrn <= ern;
		end
end	
					
endmodule

//pipeexe
module pipeexe (ealuc,ealuimm,ea,eb,eimm,eshift,ern0,epc4,ejal,ern,ealu);			
				
	input ejal;
	input [3:0] ealuc;
	input ealuimm, eshift;
	input [31:0] epc4, ea, eb, eimm;
	input [4:0] ern0;
	output [31:0] ealu;
	output [4:0] ern;
	
	wire [31:0] epc8, alua, alub, sa, r;
	assign epc8 = epc4 + 32'h4;
	assign sa = {27'b0, eimm[10:6]};
	mux2x32 alu_ina (ea, sa, eshift, alua);
	mux2x32 alu_inb (eb, eimm, ealuimm, alub);
	alu alu_unit (alua, alub, ealuc, r);
	mux2x32 save_pc8 (r, epc8, ejal, ealu);
	assign ern = ern0 | {5{ejal}};
	
endmodule

//pipemem
module pipemem (mwmem, malu, mb, clock, memclock, mmo,io_mem0,io_mem1,result);
	input mwmem;
	input [31:0] malu, mb;
	input clock, memclock;
	input  [4:0]	io_mem0,io_mem1;
	output [31:0] mmo;
	output reg[31:0]  result;
	
	wire   [31:0]  dataout1;
	reg    [31:0]  dataout2;
	
	wire write_enable = mwmem & ~clock;
	assign mmo=malu[7]?dataout2:dataout1;
	lpm_ram_dq_dram dmem (malu[6:2], memclock, mb, write_enable, dataout1);
	
always@(clock)	
begin
	if(write_enable)
		begin
		if(malu[7]==1'b1&&malu[3:2]==2'b10) result <= mb;
		end
	else
		begin
		result <= result;
		if(malu[7]==1'b1)
			begin
			if(malu[2]==1'b0) dataout2 <= {27'b0,io_mem0};
			else 					dataout2 <= {27'b0,io_mem1};
			end
		end
end
	
endmodule


//pipemwreg			MEM/WB		
module pipemwreg (mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
						wwreg,wm2reg,wmo,walu,wrn);		
	input clock,resetn;
	input mwreg,mm2reg;
	input [4:0] mrn;
	input [31:0] mmo,malu;
	output reg wwreg,wm2reg;
	output reg [31:0] wmo,walu;
	output reg [4:0] wrn;
	
always @(posedge clock)
begin
	if (~resetn)
		begin
		wwreg <= 0;
		wm2reg <= 0;
		wmo <= 0;
		walu <= 0;
		wrn <= 0;
		end
	else
		begin
		wwreg <= mwreg;
		wm2reg <= mm2reg;
		wmo <= mmo;
		walu <= malu;
		wrn <= mrn;	
		end
end

endmodule		
		
					
//mux2x32
module mux2x32 (a0,a1,s,y);

   input [31:0]  a0,a1;
   input 	 	  s; 
   output reg[31:0] y;

always @(*) 
begin
   case (s)
      1'b0: y = a0;
      1'b1: y = a1;
	endcase	
end
	
endmodule 

//mux4x32 
module mux4x32 (a0,a1,a2,a3,s,y);

   input [31:0]  a0,a1,a2,a3;
   input [ 1:0]  s;
   output reg[31:0] y;

always @(*)
begin
   case (s)  
      2'b00: y = a0;
      2'b01: y = a1;
      2'b10: y = a2;
      2'b11: y = a3;  
   endcase
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
module pipe_cu (mrn, mm2reg, mwreg, ern, em2reg, ewreg, rsrtequ, op, func, 
					rs, rt, wreg, m2reg, wmem, jal, aluc, aluimm, shift, 
					regrt, sext, fwdb, fwda, pcsource, wpcir);
					
   input [5:0] op, func;
	input [4:0] rs, rt, ern, mrn;
	input ewreg, em2reg, mwreg, mm2reg, rsrtequ;	
	output [3:0] aluc;
	output [1:0] fwda, fwdb, pcsource;
	output wreg, m2reg, wmem, jal, aluimm, shift, regrt, sext, wpcir;	
	reg [1:0] fwda, fwdb;
	
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
	//	
	wire i_rs = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi 
					| i_ori | i_xori | i_lw | i_sw | i_beq | i_bne;  //含有rs的指令
	wire i_rt = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | i_sw | i_beq | i_bne;//含有rt的指令
	//
	assign wpcir = ~(ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | i_rt & (ern == rt)));//
	
	assign wreg = (i_xori | i_andi | i_ori | i_addi | i_lw | i_add | i_sub | i_xor 
						| i_and | i_or | i_sll | i_srl | i_sra | i_lui | i_jal) & wpcir;
	assign m2reg = i_lw;
	assign wmem = i_sw& wpcir;//
	assign jal = i_jal;
	assign aluc[3] = i_sra;
	assign aluc[2] = i_sub | i_or | i_srl | i_sra | i_ori | i_lui;
	assign aluc[1] = i_sll | i_xor | i_xori | i_srl | i_sra | i_lui;
	assign aluc[0] = i_and | i_andi | i_or | i_ori | i_sll | i_srl | i_sra;
	assign aluimm  = i_addi | i_lw | i_sw | i_xori | i_lui | i_andi | i_ori;
	assign shift   = i_sll | i_srl | i_sra;
	assign regrt   = i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_lui;
	assign sext    = i_addi | i_ori | i_xori | i_lw | i_sw | i_beq | i_bne | i_lui;
	
	assign pcsource[1] = i_jr | i_j | i_jal;
	assign pcsource[0] = (i_bne & ~rsrtequ) | (i_beq & rsrtequ) | i_j | i_jal;
	
always @(*)  
begin
	fwda = 2'b00;
	if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) 
	begin
		fwda = 2'b01;
	end 
	else 
	begin
		if (mwreg & (mrn != 0) & (ern != rs) & (mrn == rs) & ~mm2reg) 
		begin
			fwda = 2'b10;
		end 
		else 
		begin
			if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg) 
			begin
				fwda = 2'b11;
			end
		end
	end
	
	fwdb = 2'b00;
	if (ewreg & (ern != 0) & (ern == rt) & ~em2reg) 
	begin
		fwdb = 2'b01;
	end 
	else 
	begin
		if (mwreg & (mrn != 0) & (ern != rt) & (mrn == rt) & ~mm2reg) 
		begin
			fwdb = 2'b10;
		end 
		else 
		begin
			if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg) 
			begin
				fwdb = 2'b11;
			end
		end
	end
end
	
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

always @(posedge clk or negedge clrn) 
begin
	if (clrn == 0) 
	begin // reset
		integer i;
		for (i=1; i<32; i=i+1)
         register[i] <= 0;
   end 
	else begin
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
       4'bx010: s = a ^ b;              //x010 XOR
       4'bx110: s = a << 16;            //x110 LUI: imm << 16bit             
       4'b0011: s = b << a;             //0011 SLL: rd <- (rt << sa)
       4'b0111: s = b >> a;             //0111 SRL: rd <- (rt >> sa) (logical)
       4'b1111: s = $signed(b) >>> a;   //1111 SRA: rd <- (rt >> sa) (arithmetic)
       default: s = 0;
   endcase
   if (s == 0 )  z = 1;
   else 		   z = 0;         
end    
  
endmodule 

//mux2x5
module mux2x5 (a0,a1,s,y);

   input [4:0] a0,a1;
   input        s;
   
   output [4:0] y;
   
   assign y = s ? a1 : a0;
   
endmodule

module show_operand_L(
		input[4:0] data,
		output reg[6:0] digital
);

always@(*)
begin
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
end

endmodule

module show_operand_H(
		input[4:0] data,
		output reg[6:0] digital
);

always@(*)
begin
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
end

endmodule

module show_result_L(
		input[5:0] data,
		output reg[6:0] digital
);

always@(*)
begin
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
end

endmodule

module show_result_H(
		input[5:0] data,
		output reg[6:0] digital
);

always@(*)
begin
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
end

endmodule

//DivClk
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
		count<=0;
		end	
	else 
		begin
		clock<=1'b0;
		count<=count+1'b1;
		end
end
endmodule


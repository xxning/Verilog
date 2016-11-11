module alu(A,B,F,S,CN,CO,M);         
input[3:0]		A,B;
input[3:0]		S;
input		M,CN;
output 		CO;
output[3:0]	F;
reg[3:0]		F;
reg[3:0]	    ta,tb;                        
reg 			CO;                         
always @(S)
begin
	ta=~A;
	tb=~B;
	case(S)
		'b0000:
			begin
				if(M) F=ta;
				else
					begin
						if(CN){CO,F}=A;
						else {CO,F}=A+1;
					end 
			end
		'b0001:
			begin
				if(M) F=~(A|B);
				else
					begin
						if(CN){CO,F}=A|B;
						else {CO,F}=(A|B)+1;
					end 
			end
		'b0010:
			begin
				if(M) F=(ta)&B;
				else
					begin
						if(CN){CO,F}=A|(tb);
						else {CO,F}=A|(tb)+1;
					end 
			end
		'b0011:
			begin
				if(M) F=0;
				else
					begin
						if(CN){CO,F}=-1;
						else {CO,F}=0;
					end 
			end
		'b0100:
			begin
				if(M) F=~(A&B);
				else
					begin
						if(CN){CO,F}=A+(A&(tb));
						else {CO,F}=A+(A&(tb))+1;
					end 
			end
		'b0101:
			begin
				if(M) F=tb;
				else
					begin
						if(CN){CO,F}=A&(tb)+(A|B);
						else {CO,F}=A&(tb)+(A|B)+1;
					end 
			end
		'b0110:
			begin
				if(M) F=A^B;
				else
					begin
						if(CN){CO,F}=(A-B)-1;
						else {CO,F}=A-B;
					end 
			end
		'b0111:
			begin
				if(M) F=A&(tb);
				else
					begin
						if(CN){CO,F}=(A&(tb))-1;
						else {CO,F}=A&(tb);
					end 
			end
		'b1000:
			begin
				if(M) F=(ta)|B;
				else
					begin
						if(CN){CO,F}=A+(A&B);
						else {CO,F}=A+(A&B)+1;
					end 
			end
		'b1001:
			begin
				if(M) F=~(A^B);
				else
					begin
						if(CN){CO,F}=A+B;
						else {CO,F}=A+B+1;
					end 
			end
		'b1010:
			begin
				if(M) F=B;
				else
					begin
						if(CN){CO,F}=(A|(tb))+(A&B);
						else F=(A|(tb))+(A&B)+1;
					end 
			end
		'b1011:
			begin
				if(M) F=A&B;
				else
					begin
						if(CN){CO,F}=(A&B)-1;
						else {CO,F}=A&B;
					end 
			end
		'b1100:
			begin
				if(M) F =1;
				else
					begin
						if(CN){CO,F}=A+A;
						else {CO,F}=A+A+1;
					end 
			end
		'b1101:
			begin
				if(M) F=A|(tb);
				else
					begin
						if(CN){CO,F}=(A|B)+A;
						else {CO,F}=(A|B)+A+1;
					end 
			end
		'b1110:
			begin
				if(M) F=A|B;
				else
					begin
						if(CN){CO,F}=(A|(tb))+A;
						else {CO,F}=(A|(tb))+A+1;
					end 
			end
		'b1111:
			begin
				if(M) F=A;
		        else
					begin
						if(CN){CO,F}=A-1;
						else {CO,F}=A;
					end 
			end
			
			

	endcase
end
endmodule

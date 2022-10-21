module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);

    parameter load=7'b0000011,
    store=7'b0100011,
    ALU=7'b0110011;

    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [4:0] rd, rs1, rs2;
    wire [6:0] imm;
    reg [31:0] RF[0:31]

    always @(posedge clk) begin

        if (reset) begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
        end else begin 
            iaddr <= iaddr + 4;

            opcode=idata[6:0];
            rd=idata[11:7];
            funct3=idata[14:12];
            rs1=idata[19:13];
            rs2=idata[24:20];
            imm=idata[31:25];

                if(opcode==load)
                    begin
                        daddr<=x[rs1] + {20{imm[11],imm, rs2};
                        x[rd]<=drdata;
                        dwdata <= 0;
                        dwe <= 0;
                    end

                if(opcode==store)
                    begin
                       x[rs2]<= x[rs1] + {25{imm[11],imm};
                    end



        end
    end

endmodule
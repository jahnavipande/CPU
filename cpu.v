module regfile ( input [4:0] rs1,     // address of first operand to read - 5 bits
                 input [4:0] rs2,     // address of second operand
                 input [4:0] rd,      // address of value to write
                 input we,            // should write update occur
                 input [31:0] wdata,  // value to be written
                 output [31:0] rv1,   // First read value
                 output [31:0] rv2,   // Second read value
                 input clk,            // Clock signal - all changes at clock posedge
                 output [32*32-1:0] registers  // EXTRA PORT
            
            );

    // Desired function
    // rv1, rv2 are combinational outputs - they will update whenever rs1, rs2 change
    // on clock edge, if we=1, regfile entry for rd will be updated

    // 32, 32-bit internal registers
    reg [31:0] internalRegisters [0:31];
    reg [31:0] rv1_r, rv2_r;

    // initialising registers to 0
    integer i;
    initial begin
        for (i=0;i<32;i=i+1)
            internalRegisters[i] = 32'b0;
    end
    
     assign registers = {internalRegisters[31], internalRegisters[30], internalRegisters[29], internalRegisters[28], internalRegisters[27], internalRegisters[26], internalRegisters[25], internalRegisters[24], internalRegisters[23], internalRegisters[22], internalRegisters[21], internalRegisters[20], internalRegisters[19], internalRegisters[18], internalRegisters[17], internalRegisters[16], internalRegisters[15], internalRegisters[14], internalRegisters[13], internalRegisters[12], internalRegisters[11], internalRegisters[10], internalRegisters[9], internalRegisters[8], internalRegisters[7], internalRegisters[6], internalRegisters[5], internalRegisters[4], internalRegisters[3], internalRegisters[2], internalRegisters[1], internalRegisters[0]};

    // synchronous write operations
    always @(posedge clk) begin
        if (we == 1'b1) begin
            if(rd == 5'd0)
                internalRegisters[rd] <= 32'd0;
            else
                internalRegisters[rd] <= wdata;
        end
    end

    // combinational read operations
    always @(*) begin
        rv1_r = internalRegisters[rs1];
        rv2_r = internalRegisters[rs2];
    end

    // assigning outputs
    assign rv1 = rv1_r;
    assign rv2 = rv2_r;

endmodule


module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe,
    output [32*32-1:0] registers

);


    parameter load= 7'b0000011,                                                     
    store= 7'b0100011,
    ALU= 7'b0110011,
    ALUI= 7'b0010011,
    LUI= 7'b0110111,
    AUIPC= 7'b0010111,
    JAL= 7'b1101111,
    JALR= 7'b1100111,
    BRANCH= 7'b1100011;

    reg [31:0] iaddr, new_iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata, wdata;
    reg [3:0]  dwe;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [4:0] rd, rs1, rs2;
    reg [0:0] we;
    reg [6:0] imm;
    reg [0:0] flag;


        // RegFile ports

    wire [31:0] rv1, rv2;

        // Instantiate Register File
    regfile rf(
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .we(we),
        .wdata(wdata),
        .rv1(rv1),
        .rv2(rv2),
        .registers(registers)
    );


    always @(posedge clk) begin

        if (reset) begin
            iaddr <= 0;
        end else begin 
            if(flag==1) begin
                iaddr <= new_iaddr;
            end
            else begin
                iaddr <= iaddr + 32'd4;
            end
            
        end
    end

            always @(*) begin

                opcode=idata[6:0];
                rd=idata[11:7];
                funct3=idata[14:12];
                rs1=idata[19:15];
                rs2=idata[24:20];
                imm=idata[31:25];

                if(reset) begin
                    daddr = 0;
                    dwdata = 0;
                    dwe = 0;
                    we=0;
                    new_iaddr=0;
                    flag= 1'b0;
                    wdata=0;
                end else begin

                        case(opcode)

                            load: begin
                                new_iaddr=iaddr;
                                flag= 1'b0;
                                dwdata = 0;
                                dwe = 0;
                                daddr= rv1+{{20{imm[6]}}, imm, rs2};
                                we =1;
                                wdata=0;
                                case(funct3)
                                    3'b000: begin
                                        
                                        case(daddr[1:0])
                                            2'b00: wdata= {{24{drdata[7]}}, drdata[7:0]} ;
                                            2'b01: wdata= {{24{drdata[15]}}, drdata[15:8]} ;
                                            2'b10: wdata=  {{24{drdata[23]}}, drdata[23:16]} ;
                                            2'b11: wdata= {{24{drdata[31]}}, drdata[31:24]} ;
                                            default: begin
                                                wdata = 32'b0;
                                                dwdata=0;
                                                dwe = 4'b0;
                                                we =0;
                                                end
                                        endcase
                                    end

                                    3'b001: begin

                                        //daddr= rv1+{{20{imm[6]}}, imm, rs2};

                                        case(daddr[1:0])
                                            2'b00: wdata= {{16{drdata[15]}}, drdata[15:0]} ;
                                            2'b10: wdata= {{16{drdata[31]}}, drdata[31:16]} ;
                                            default: begin
                                                wdata = 0;
                                                dwe = 4'b0;
                                                we =0;
                                                end
                                        endcase
                                    end

                                    3'b010:wdata=drdata ;
                                    3'b100: begin
                                         case(daddr[1:0])
                                            2'b00: wdata= {24'b0,drdata[7:0]};
                                            2'b01: wdata= {24'b0,drdata[15:8]} ;
                                            2'b10: wdata= {24'b0,drdata[23:16]} ;
                                            2'b11: wdata= {24'b0,drdata[31:24]} ;
                                            default: begin
                                                //daddr = 0;
                                                wdata = 0;
                                                dwe = 0;
                                                we =0;
                                            end
                                        endcase
                                    end

                                    3'b101: begin
                                        case(daddr[1:0])
                                            2'b00: wdata= {16'b0, drdata[15:0]} ;
                                            2'b10: wdata= {16'b0, drdata[31:16]} ;
                                            default: begin
                                                //daddr = 0;
                                                wdata = 0;
                                                dwe = 0;
                                                we =0;
                                                end
                                        endcase
                                    end
                                    default: begin
                                            dwe =0;
                                            we =0;
                                            wdata =0;
                                    end
                                endcase
                            end

                            store: begin
                                new_iaddr=iaddr;
                                flag= 1'b0;
                                daddr= rv1+{{20{imm[6]}}, imm, rd};
                                we = 0;
                                wdata = 0;
                                dwdata=0;

                                case(funct3)
                                    3'b000: begin
                                    dwdata={4{rv2[7:0]}};
                                    case(daddr[1:0])
                                            2'b00: dwe= 4'b0001 ;
                                            2'b01: dwe= 4'b0010 ;
                                            2'b10: dwe= 4'b0100 ;
                                            2'b11: dwe= 4'b1000 ;
                                            default: begin
                                                //daddr = 0;
                                                dwdata = 0;
                                                dwe = 0;
                                                we =0;
                                            end
                                        endcase
                                    end
                                    3'b001: begin
                                        dwdata={2{rv2[15:0]}};
                                        case(daddr[1:0])
                                                2'b00: dwe= 4'b0011 ;
                                                2'b10: dwe= 4'b1100 ;
                                                default: begin
                                                    //daddr = 0;
                                                    dwdata = 0;
                                                    dwe = 0;
                                                    we =0;
                                                end
                                            endcase
                                    end
                                    3'b010: begin
                                        dwdata=rv2;
                                        case(daddr[1:0])
                                                2'b00: dwe= 4'b1111 ;
                                                default: begin
                                                    dwdata = 0;
                                                    dwe = 0;
                                                    we =0;
                                                end
                                            endcase
                                    end
                                    default: begin
                                        dwdata = 0;
                                        dwe = 0;
                                        we =0;
                                    end
                                endcase                        
                            end

                            ALU: begin
                                new_iaddr=iaddr;
                                flag= 1'b0;
                                daddr = 0;
                                dwdata = 0;
                                dwe = 0;
                                we=1;
                                case(funct3)
                                3'b000:begin
                                    case(imm)
                                        7'b0000000: wdata= rv1+rv2;
                                        7'b0100000: wdata= rv1-rv2;
                                        default: begin
                                            //daddr = 0;
                                            wdata = 32'b0;                                   
                                            dwe = 0;
                                            we =0;
                                        end
                                    endcase
                                end 
                                3'b001: wdata= rv1<<rv2[4:0];
                                3'b010: begin
                                    if($signed(rv1)<$signed(rv2)) wdata=32'd1;
                                    else wdata=0;
                                end
                                3'b011: begin
                                    if($unsigned(rv1)<$unsigned(rv2)) wdata=32'd1;
                                    else wdata=0;
                                end
                                3'b100: wdata= rv1^rv2;
                                3'b101:begin
                                    case(imm)
                                        7'b0000000: wdata= rv1>>rv2[4:0];
                                        7'b0100000: wdata= rv1>>>rv2[4:0];
                                        default: begin
                                            //daddr = 0;
                                            wdata = 0;
                                            dwe = 0;
                                            we =0;
                                        end
                                    endcase
                                end
                                3'b110: wdata= rv1 | rv2;
                                3'b111: wdata= rv1 & rv2;
                                default: begin
                                        //daddr = 0;
                                        wdata = 0;
                                        dwe = 0;
                                        we =0;         
                                end
                                endcase
                            end

                            ALUI: begin

                                daddr = 0;
                                dwdata = 0;
                                dwe = 0;
                                we= 1;
                                new_iaddr=iaddr;
                                flag= 1'b0;
                                case(funct3)
                                    3'b000: wdata= rv1+{{20{idata[31]}}, idata[31:20]}; //addi
                                    3'b001: wdata= rv1<<rs2;
                                    3'b010: begin
                                        if($signed(rv1)<$signed({{20{idata[31]}}, idata[31:20]})) wdata=32'd1;
                                        else wdata=0;
                                    end
                                    3'b011: begin
                                        if($unsigned(rv1)<$unsigned({{20{idata[31]}}, idata[31:20]})) wdata=32'd1;
                                        else wdata=0;
                                    end
                                    3'b100: wdata= rv1^{{20{idata[31]}}, idata[31:20]};
                                    3'b101:begin
                                        case(imm[6:1])
                                            6'b000000: wdata= rv1>>rs2;
                                            6'b010000: wdata= rv1>>>rs2;
                                            default: begin
                                                //daddr = 0;
                                                wdata = 0;
                                                dwe = 0;
                                                we =0;
                                            end
                                        endcase
                                    end
                                    3'b110: wdata= rv1 | {{20{idata[31]}}, idata[31:20]};
                                    3'b111: wdata= rv1 & {{20{idata[31]}}, idata[31:20]};
                                    default: begin
                                        //daddr = 0;
                                        wdata = 0;
                                        dwe = 0;
                                        we =0;
                                    end
                                endcase
                            end

                            LUI: begin
                                dwdata = 0;
                                dwe = 0;
                                daddr= 0;
                                we =1;
                                wdata= {idata[31:12], 12'b0};
                                new_iaddr=iaddr;
                                flag= 1'b0;

                            end

                            AUIPC: begin
                                dwdata = 0;
                                dwe = 0;
                                daddr= 0;
                                we =1;
                                wdata= iaddr+{idata[31:12], 12'b0};
                                new_iaddr=iaddr;
                                flag= 1'b0;
                            end

                            JAL: begin
                                dwdata = 0;
                                dwe = 0;
                                daddr= 0;
                                we =1;
                                wdata= iaddr+32'd4;
                                new_iaddr=iaddr+{{12{imm[6]}}, rs1, funct3, rs2[0], imm[5:0], rs2[4:1], 1'b0};
                                flag= 1'b1;
                            end

                            JALR: begin
                                case(funct3)
                                    3'b000: begin
                                        dwdata = 0;
                                        dwe = 0;
                                        daddr= 0;
                                        we =1;
                                        wdata= iaddr+32'd4;
                                        new_iaddr = (rv1+ {{20{imm[6]}}, imm, rs2}) & 32'b11111111111111111111111111111110;
                                        flag= 1'b1;
                                    end
                                    default: begin
                                        dwdata = 0;
                                        dwe = 0;
                                        daddr= 0;
                                        we =0;
                                        wdata= 0;
                                        new_iaddr = iaddr+32'd4;
                                        flag= 1'b0;
                                    end
                                endcase
                            end

                            BRANCH: begin
                                dwdata = 0;
                                dwe = 0;
                                daddr= 0;
                                we =0;
                                wdata=0;
                                flag= 1'b1;
                                case(funct3)
                                    3'b000: begin
                                        if(rv1==rv2) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    3'b001: begin
                                        if(rv1!=rv2) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    3'b100: begin
                                        if($signed(rv1)<$signed(rv2)) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    3'b101: begin
                                        if($signed(rv1)>=$signed(rv2)) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    3'b110: begin
                                        if($unsigned(rv1)<$unsigned(rv2)) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    3'b111:  begin
                                        if($unsigned(rv1)>=$unsigned(rv2)) new_iaddr=iaddr+ {{20{imm[6]}}, rd[0], imm[5:0], rd[4:1], 1'b0};
                                        else new_iaddr= iaddr+32'd4;
                                    end
                                    default: new_iaddr= iaddr+32'd4;
                                endcase
                            end

                            default: begin
                                dwdata = 0;
                                dwe = 0;
                                daddr= 0;
                                we =0;
                                wdata=0;
                                flag= 1'b0;
                                new_iaddr= iaddr;

                            end

                        endcase
                end
            end

endmodule



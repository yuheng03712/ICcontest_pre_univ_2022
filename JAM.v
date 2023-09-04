module JAM (
    input CLK,
    input RST,
    output reg [2:0] W,
    output reg [2:0] J,
    input [6:0] Cost,
    output reg [3:0] MatchCount,
    output reg [9:0] MinCost,
    output Valid
);
reg [2:0] state_cs;
reg [2:0] state_ns;
reg [6:0] CostTable[7:0][7:0]; //(W,J)
reg [2:0] JOBS[7:0];//工作項目 初始[0,1,2,3,4,5,6,7]
reg [3:0] changePoint;
reg [3:0] checkPoint;//交換點
reg [3:0] counter;
reg [3:0] minIndex;
reg match;

localparam READ = 3'd0,WK = 3'd1,WK1 = 3'd2 ,WK2 = 3'd3,WK3 = 3'd4,WK4=3'd5,DONE = 3'd6,MATCHING = 3'd7; //WK 計算 WK1 找替換點 WK2找最小index WK3交換交換點 WK4反轉右邊;
always @(posedge CLK ) begin
    if(RST)  state_cs <=READ;
    else state_cs <=state_ns;
end
//state logic
always @(*) begin
    case (state_cs)
        READ:begin
            if(W==3'd7&&J==3'd7)
                state_ns = WK;
            else state_ns =READ;
        end
        WK:begin
            if(JOBS[7] > JOBS[6] ||JOBS[6] > JOBS[5] ||JOBS[5] > JOBS[4] ||JOBS[4] > JOBS[3] ||JOBS[3] > JOBS[2] ||JOBS[2] > JOBS[1] ||JOBS[1] > JOBS[0])
                state_ns = WK1;
            else if(match)state_ns = DONE;
            else state_ns = MATCHING;
        end
        WK1: state_ns = WK2;
        WK2:begin
            if(counter==3'd7)
                state_ns = WK3;
            else state_ns = WK2;
        end
        WK3: state_ns = WK4;
        WK4: state_ns = WK;
        MATCHING: state_ns = WK;
        DONE: state_ns = DONE;
        default: state_ns = READ;
    endcase
end
//control signal
assign Valid = (state_cs==DONE)?1'b1:1'b0;
//W J counter
always @(posedge CLK) begin
    if (RST) begin
        W <= 3'd0;
        J <= 3'd0;
    end else if(state_cs==READ) begin
        if(J==3'd7)begin
            W <= W + 3'd1;
            J <= 3'd0;
        end   
        else J <= J + 3'd1;  
    end  
end
//function
wire [7:0] tmp1 = CostTable[0][JOBS[0]] + CostTable[1][JOBS[1]];
wire [7:0] tmp2 = CostTable[2][JOBS[2]] + CostTable[3][JOBS[3]];
wire [7:0] tmp3 = CostTable[4][JOBS[4]] + CostTable[5][JOBS[5]];
wire [7:0] tmp4 = CostTable[6][JOBS[6]] + CostTable[7][JOBS[7]];
wire [8:0] tmp2_1 = tmp1 + tmp2;
wire [8:0] tmp2_2 = tmp3 + tmp4;
wire [9:0] sum = tmp2_1 + tmp2_2;
always @(posedge CLK ) begin
    if(RST)begin 
        MinCost <= 10'd1023;
        MatchCount <= 4'd0;
    end
    else if(state_cs==WK)begin
        if(!match)
            MinCost <= (sum < MinCost) ?sum:MinCost;
        else 
            MatchCount <= (sum == MinCost)?MatchCount+4'd1:MatchCount;
    end
end
always @(*) begin
    if(JOBS[7]>JOBS[6])
        changePoint = 3'd6;
    else if(JOBS[6]>JOBS[5])
        changePoint = 3'd5;
    else if(JOBS[5]>JOBS[4])
        changePoint = 3'd4;
    else if(JOBS[4]>JOBS[3])
        changePoint = 3'd3;
    else if(JOBS[3]>JOBS[2])
        changePoint = 3'd2;
    else if(JOBS[2]>JOBS[1])
        changePoint = 3'd1;
    else if(JOBS[1]>JOBS[0])
        changePoint = 3'd0;
    else changePoint = 3'd0;
end
always @(posedge CLK) begin
    if(RST)begin
        match <=1'b0;
        JOBS[0] <= 3'd0;
        JOBS[1] <= 3'd1;
        JOBS[2] <= 3'd2;
        JOBS[3] <= 3'd3;
        JOBS[4] <= 3'd4;
        JOBS[5] <= 3'd5;
        JOBS[6] <= 3'd6;
        JOBS[7] <= 3'd7;
    end
    else begin
        case (state_cs)
            READ:begin
                CostTable[W][J]<=Cost;
            end
            WK1:begin
                checkPoint <= changePoint;
                counter <=  changePoint + 3'd1;
                minIndex <= changePoint + 3'd1;
            end
            WK2:begin
                if(counter<3'd7)begin
                    if(JOBS[counter]>JOBS[counter + 3'd1]&&JOBS[counter + 3'd1]>JOBS[checkPoint]) //右小於左 且大於交換點
                        minIndex <= counter + 3'd1;
                    else minIndex <= minIndex;  
                    counter <= counter + 3'd1;        
                end
            end
            WK3:begin
                JOBS[checkPoint] <= JOBS[minIndex];
                JOBS[minIndex] <= JOBS[checkPoint];
            end
            WK4:begin
                case (checkPoint)
                    3'd0:begin
                        JOBS[1] <= JOBS[7];
                        JOBS[2] <= JOBS[6];
                        JOBS[3] <= JOBS[5];
                        JOBS[4] <= JOBS[4];
                        JOBS[5] <= JOBS[3];
                        JOBS[6] <= JOBS[2];
                        JOBS[7] <= JOBS[1];
                    end
                    3'd1:begin
                        JOBS[2] <= JOBS[7];
                        JOBS[3] <= JOBS[6];
                        JOBS[4] <= JOBS[5];
                        JOBS[5] <= JOBS[4];
                        JOBS[6] <= JOBS[3];
                        JOBS[7] <= JOBS[2];
                    end
                    3'd2:
                    begin
                        JOBS[3] <= JOBS[7];
                        JOBS[4] <= JOBS[6];
                        JOBS[5] <= JOBS[5];
                        JOBS[6] <= JOBS[4];
                        JOBS[7] <= JOBS[3];
                    end
                    3'd3:
                    begin
                        JOBS[4] <= JOBS[7];
                        JOBS[5] <= JOBS[6];
                        JOBS[6] <= JOBS[5];
                        JOBS[7] <= JOBS[4];
                    end
                    3'd4:
                    begin
                        JOBS[5] <= JOBS[7];
                        JOBS[6] <= JOBS[6];
                        JOBS[7] <= JOBS[5];
                    end
                    3'd5:
                    begin
                        JOBS[6] <= JOBS[7];
                        JOBS[7] <= JOBS[6];
                    end
                    3'd6:begin
                        JOBS[7] <= JOBS[7];
                    end
                endcase
            end
            MATCHING:begin
                match <= 1'b1;
                JOBS[0] <= 3'd0;
                JOBS[1] <= 3'd1;
                JOBS[2] <= 3'd2;
                JOBS[3] <= 3'd3;
                JOBS[4] <= 3'd4;
                JOBS[5] <= 3'd5;
                JOBS[6] <= 3'd6;
                JOBS[7] <= 3'd7;
            end
        endcase  
    end
end
endmodule



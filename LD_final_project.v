module LD_final_project(
    output reg [7:0] DATA_R, DATA_G, DATA_B,
    output reg [6:0] d7_1, 
    output reg [2:0] COMM, Life,
    output reg [1:0] COMM_CLK,
    output EN,
    input CLK, clear, Left, Right,
    input [7:0] SW  // 輸入秒數用的開關
);
    reg [7:0] plate [7:0];  //操控顯示板
    reg [7:0] people [7:0]; //玩家位置
    reg [6:0] seg1, seg2;  // 7 段顯示器的顯示數據
    reg [3:0] bcd_s,bcd_m; // 倒數計時的個位與十位數
    reg [2:0] random01, random02, random03, r, r1, r2; // 隨機數生成器的中間值，方便使用，不用動到主程式
    reg left, right, temp;

    // 原有 7 段顯示器、除頻器、變數宣告等不變
    segment7 S0(bcd_s, A0,B0,C0,D0,E0,F0,G0); //顯示個位數
    segment7 S1(bcd_m, A1,B1,C1,D1,E1,F1,G1); //顯示十位數
    divfreq  div0(CLK, CLK_div);  //控制顯示速度的時鐘除頻器
    divfreq1 div1(CLK, CLK_time);  //倒數計時的除頻器
    divfreq2 div2(CLK, CLK_mv); //控制移動的時鐘除頻器

    byte line, count, count1; //計數器
    integer a, b, c, touch; //計算用代數

//----------------------------------------------------
// 初始值：從外部輸入 SW 作為起始秒數
//----------------------------------------------------
    initial
    begin
        bcd_m = SW[7:4];  // 十位秒
        bcd_s = SW[3:0];  // 個位秒
        line = 3;
        random01 = (5*random01 + 3)%16;
        r = random01 % 8;
        random02 = (5*(random02+1) + 3)%16;   //產生隨機數字，用於障礙物的位置
        r1 = random02 % 8;
        random03= (5*(random03+2) + 3)%16;
        r2 = random03 % 8;
        a = 0;  b = 0;  c = 0 ;
        touch = 0;  //碰撞次數
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;  //初始全關
        DATA_B = 8'b11111111;
        plate[0] = 8'b11111111;
        plate[1] = 8'b11111111;
        plate[2] = 8'b11111111;
        plate[3] = 8'b11111111;
        plate[4] = 8'b11111111; //初始全關
        plate[5] = 8'b11111111;
        plate[6] = 8'b11111111;
        plate[7] = 8'b11111111;
        people[0] = 8'b11111111;
        people[1] = 8'b11111111;
        people[2] = 8'b11111111;
        people[3] = 8'b00111111; //玩家亮點出現在第四行
        people[4] = 8'b11111111;
        people[5] = 8'b11111111;
        people[6] = 8'b11111111;
        people[7] = 8'b11111111;
        count1 = 0;  //七段顯示器上的代數
    end

//----------------------------------------------------
// 7 段顯示器的視覺暫留 
//----------------------------------------------------
    always@(posedge CLK_div)
    begin
        seg1[0] = A0;  //轉換個位數變七段顯示器
        seg1[1] = B0;
        seg1[2] = C0;
        seg1[3] = D0;
        seg1[4] = E0;
        seg1[5] = F0;
        seg1[6] = G0;
        
        seg2[0] = A1; //轉換十位數
        seg2[1] = B1;
        seg2[2] = C1;
        seg2[3] = D1;
        seg2[4] = E1;
        seg2[5] = F1;
        seg2[6] = G1;
        
        if(count1 == 0)  
        begin
            d7_1 <= seg1;  //個位數顯示
            COMM_CLK[1] <= 1'b1;
            COMM_CLK[0] <= 1'b0;
            count1 <= 1'b1; 
        end
        else if(count1 == 1)
        begin
            d7_1 <= seg2;  //十位數顯示
            COMM_CLK[1] <= 1'b0;
            COMM_CLK[0] <= 1'b1;
            count1 <= 1'b0;
        end
    end

//----------------------------------------------------
// 倒數計時 (若時間到，bcd_m == 0 && bcd_s == 0)
//----------------------------------------------------
    always@(posedge CLK_time or posedge clear)
    begin
        if(clear)
        begin
            // 將秒數覆蓋為開關輸入秒數
            bcd_m <= SW[7:4];  
            bcd_s <= SW[3:0];
        end
        else
        begin
            if(touch < 3)  //如果碰撞小於3
            begin
              
                if(bcd_s == 0)
                begin
                    bcd_s <= 9;  //個位數規0，像十借位
                    if(bcd_m > 0)
                        bcd_m <= bcd_m - 1;
                    else
                        bcd_m <= 0;  // 避免負數
                end
                else
                    bcd_s <= bcd_s - 1; //倒數
            end
        end
    end

//----------------------------------------------------
// 主畫面的視覺暫留：到即時結束顯示全綠代表成功
//----------------------------------------------------
    always@(posedge CLK_div)
    begin
        if(count >= 7)
            count <= 0;  //掃描行數
        else
            count <= count + 1; //掃描下一行

        COMM = count;  //設定顯示行數
        EN = 1'b1; //啟用顯示

        // 新增一個判斷：time_up = 計時歸零
        if(touch >= 3)
        begin
            // 如果碰撞次數超過 3 就遊戲結束 → 顯示 GG
            DATA_R <= plate[count]; //GG顯示
            DATA_G <= 8'b11111111; //關閉全綠
            Life <= 3'b000; //生命0
        end
        else if(bcd_m == 0 && bcd_s == 0)
        begin
            // ======= 時間到 → 顯示全綠 =======
            DATA_R <= 8'b11111111;   // 沒有GG 
            DATA_G <= 8'b00000000;   // 全綠亮起 
            Life   <= 3'b000;        // 可自行決定顯示
        end
        else
        begin
            // 正常遊戲狀態
            DATA_G <= plate[count]; //障礙物位置
            DATA_R <= people[count]; //玩家位置
            if(touch == 0) //計算生命值
                Life <= 3'b111; 
            else if(touch == 1)
                Life <= 3'b110;
            else if(touch == 2)
                Life <= 3'b100;
        end
    end

//----------------------------------------------------
// 遊戲邏輯 (掉落物, 人物移動, 碰撞偵測, Game Over)
//----------------------------------------------------
    always@(posedge CLK_mv)
    begin
        right = Right;  //紀錄按鈕的信號
        left  = Left;    
        
        if(clear == 1) //設定clear
        begin
            touch = 0;   //碰撞規0
            line = 3;   //玩家位置回歸
            a = 0;
            b = 0;
            c = 0;  //初始化掉落物位置
            random01 = (5*random01 + 3)%16;  //產生隨機數列，用於生成掉落物
            r = random01 % 8;
            random02 = (5*(random02+1) + 3)%16;
            r1 = random02 % 8;
            random03= (5*(random03+2) + 3)%16;
            r2 = random03 % 8;
            plate[0] = 8'b11111111;
            plate[1] = 8'b11111111;
            plate[2] = 8'b11111111;
            plate[3] = 8'b11111111;  //沒有掉落物狀態
            plate[4] = 8'b11111111;
            plate[5] = 8'b11111111;
            plate[6] = 8'b11111111;
            plate[7] = 8'b11111111;
 
            people[0] = 8'b11111111;
            people[1] = 8'b11111111;
            people[2] = 8'b11111111;
            people[3] = 8'b00111111; //玩家在第三列
            people[4] = 8'b11111111;
            people[5] = 8'b11111111;
            people[6] = 8'b11111111;
            people[7] = 8'b11111111;
        end

        // 若尚未碰 3 次、也尚未 time_up，就持續掉落
        if(touch < 3)
        begin
            // fall object 1
            if(a == 0)
            begin
				plate[r][a] = 1'b0;  //在最上面生成掉落物
                a = a+1;
            end
            else if (a > 0 && a <= 7)
            begin
				plate[r][a-1] = 1'b1;  //清除上行掉落物
                plate[r][a] = 1'b0; //生成下行掉落物(移動)
                a = a+1;
            end
            else if(a == 8) //掉落物掉到最下面
            begin
                plate[r][a-1] = 1'b1;  //清除底部掉落物
                random01 = (5*random01 + 3)%16;  //重新生成隨機數字
                r = random01 % 8;  
                a = 0;  //a規0，掉落物重製最上面
            end

            // fall object 2 跟a一樣
            if(b == 0)
            begin
                plate[r1][b] = 1'b0;
                b = b+1;
            end
            else if (b > 0 && b <= 7)
            begin
                plate[r1][b-1] = 1'b1;
                plate[r1][b] = 1'b0;
                b = b+1;
            end
            else if(b == 8) 
            begin
                plate[r1][b-1] = 1'b1;
                random02 = (5*(random01+1) + 3)%16;
                r1 = random02 % 8;
                b = 0;
            end

            // fall object 3 跟a一樣
            if(c == 0)
            begin
                plate[r2][c] = 1'b0;
                c = c+1;
            end
            else if (c > 0 && c <= 7)
            begin
                plate[r2][c-1] = 1'b1;
                plate[r2][c] = 1'b0;
                c = c+1;
            end
            else if(c == 8) 
            begin
                plate[r2][c-1] = 1'b1;
                random03= (5*(random03+2) + 3)%16;
                r2 = random03 % 8;
                c = 0;
            end

            // people move
            if((right == 1) && (line != 7)) //玩家向右移動
            begin
                people[line][6] = 1'b1; //清除左邊
                people[line][7] = 1'b1;
                line = line + 1; //更新玩家向右邊移動
            end
            if((left == 1) && (line != 0))  //向左邊
            begin
                people[line][6] = 1'b1;  //清除原本
                people[line][7] = 1'b1;
                line = line - 1;  //更新位置
            end
            people[line][6] = 1'b0;
            people[line][7] = 1'b0;

            // 碰撞偵測
            if(plate[line][6] == 0) //沒動的傻子狀況，plate[line][6]==0 代表此行有掉落物，line為玩家位置
            begin
                touch = touch + 1;
                plate[r][6]  = 1'b1; //清除掉落物
                plate[r1][6] = 1'b1;
                plate[r2][6] = 1'b1;
                a = 8;  //充新生成掉落物
                b = 8;
                c = 8;
            end
            else if (plate[line][7] == 0) //往障礙物上撞的笨蛋狀況
            begin
                touch = touch + 1;
                plate[r][7]  = 1'b1;
                plate[r1][7] = 1'b1;
                plate[r2][7] = 1'b1;
                a = 8;
                b = 8;
                c = 8;
            end
        end
        else
        begin
            // touch >= 3 → 顯示 GG
            plate[0] = 8'b10000001;
            plate[1] = 8'b01111110;
            plate[2] = 8'b01101110;
            plate[3] = 8'b10001101;
            plate[4] = 8'b10000001;
            plate[5] = 8'b01111110;
            plate[6] = 8'b01101110;
            plate[7] = 8'b10001101;
        end
    end

endmodule

//----------------------------------------------------
// 7 段顯示器邏輯 (維持原狀)
//----------------------------------------------------
module segment7(input [0:3] a, output A,B,C,D,E,F,G);
    assign A = ~(a[0]&~a[1]&~a[2] | ~a[0]&a[2] | ~a[1]&~a[2]&~a[3] | ~a[0]&a[1]&a[3]),
           B = ~(~a[0]&~a[1] | ~a[1]&~a[2] | ~a[0]&~a[2]&~a[3] | ~a[0]&a[2]&a[3]),
           C = ~(~a[0]&a[1] | ~a[1]&~a[2] | ~a[0]&a[3]),
           D = ~(a[0]&~a[1]&~a[2] | ~a[0]&~a[1]&a[2] | ~a[0]&a[2]&~a[3] | ~a[0]&a[1]&~a[2]&a[3] | ~a[1]&~a[2]&~a[3]),
           E = ~(~a[1]&~a[2]&~a[3] | ~a[0]&a[2]&~a[3]),
           F = ~(~a[0]&a[1]&~a[2] | ~a[0]&a[1]&~a[3] | a[0]&~a[1]&~a[2] | ~a[1]&~a[2]&~a[3]),
           G = ~(a[0]&~a[1]&~a[2] | ~a[0]&~a[1]&a[2] | ~a[0]&a[1]&~a[2] | ~a[0]&a[2]&~a[3]);
endmodule

//----------------------------------------------------
// 視覺暫留除頻器 (維持原狀)
//----------------------------------------------------
module divfreq(input CLK, output reg CLK_div);
    reg [24:0] Count;
    always @(posedge CLK)
    begin
        if(Count > 5000)
        begin
            Count <= 25'b0;
            CLK_div <= ~CLK_div;
        end
        else
            Count <= Count + 1'b1;
    end
endmodule

//----------------------------------------------------
// 計時除頻器 (維持原狀)
//----------------------------------------------------
module divfreq1(input CLK, output reg CLK_time);
    reg [25:0] Count;
    initial CLK_time = 0;
    
    always @(posedge CLK)
    begin
        if(Count > 25000000)
        begin
            Count <= 25'b0;
            CLK_time <= ~CLK_time;
        end
        else
            Count <= Count + 1'b1;
    end
endmodule

//----------------------------------------------------
// 掉落物 & 人物移動除頻器 (維持原狀)
//----------------------------------------------------
module divfreq2(input CLK, output reg CLK_mv);
    reg [35:0] Count;
    initial CLK_mv = 0;
    
    always @(posedge CLK)
    begin
        if(Count > 3500000)
        begin
            Count <= 35'b0;
            CLK_mv <= ~CLK_mv;
        end
        else
            Count <= Count + 1'b1;
    end
endmodule

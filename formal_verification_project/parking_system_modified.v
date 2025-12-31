`timescale 1ns / 1ps
module parking_system( 
                input clk,reset_n,
 input sensor_entrance, sensor_exit, 
 input [1:0] password_1, password_2,
 output wire GREEN_LED,RED_LED,
 output reg [6:0] HEX_1, HEX_2
    );
 parameter IDLE = 3'b000, WAIT_PASSWORD = 3'b001, WRONG_PASS = 3'b010, RIGHT_PASS = 3'b011,STOP = 3'b100;
 // Moore FSM : output just depends on the current state
 reg[2:0] current_state, next_state;
 reg[31:0] counter_wait;
 reg red_tmp,green_tmp;
 // Next state
 always @(posedge clk or negedge reset_n)
 begin
 if(~reset_n) 
 current_state = IDLE;
 else
 current_state = next_state;
 end
 // counter_wait
 always @(posedge clk or negedge reset_n) 
 begin
 if(~reset_n) 
 counter_wait <= 0;
 else if(current_state==WAIT_PASSWORD)
 counter_wait <= counter_wait + 1;
 else 
 counter_wait <= 0;
 end
 // change state
 always @(*)
 begin
 case(current_state)
 IDLE: begin
 if(sensor_entrance == 1 )
 next_state = WAIT_PASSWORD;
 else
 next_state = IDLE;
 end
 WAIT_PASSWORD: begin
 if(counter_wait <= 3)
 next_state = WAIT_PASSWORD;
 else 
 begin
 if((password_1==2'b01)&&(password_2==2'b10))
 next_state = RIGHT_PASS;
 else
 next_state = WRONG_PASS;
 end
 end
 WRONG_PASS: begin
 if((password_1==2'b01)&&(password_2==2'b10))
 next_state = RIGHT_PASS;
 else
 next_state = WRONG_PASS;
 end
 RIGHT_PASS: begin
 if(sensor_entrance==1 && sensor_exit == 1) 
 next_state = STOP;
 else if(sensor_exit == 1)
 next_state = IDLE;
 else
 next_state = RIGHT_PASS;
 end
 STOP: begin
if(sensor_exit == 0)
 next_state = WAIT_PASSWORD;
 else
 next_state = STOP;
 end
 default: next_state = IDLE;
 endcase
 end
 // LEDs and output, change the period of blinking LEDs here
 always @(posedge clk) begin 
 case(current_state)
 IDLE: begin
 green_tmp = 1'b0;
 red_tmp = 1'b0;
 HEX_1 = 7'b1111111; // off
 HEX_2 = 7'b1111111; // off
 end
 WAIT_PASSWORD: begin
 green_tmp = 1'b0;
 red_tmp = 1'b1;
 HEX_1 = 7'b000_0110; // E
 HEX_2 = 7'b010_1011; // n 
 end
 WRONG_PASS: begin
 green_tmp = 1'b0;
 red_tmp = ~red_tmp;
 HEX_1 = 7'b000_0110; // E
 HEX_2 = 7'b000_0110; // E 
 end
 RIGHT_PASS: begin
 green_tmp = ~green_tmp;
 red_tmp = 1'b0;
 HEX_1 = 7'b000_0010; // 6
 HEX_2 = 7'b100_0000; // 0 
 end
 STOP: begin
 green_tmp = 1'b0;
 red_tmp = ~red_tmp;
 HEX_1 = 7'b001_0010; // 5
 HEX_2 = 7'b000_1100; // P 
 end
 endcase
 end
 assign RED_LED = red_tmp  ;
 assign GREEN_LED = green_tmp;

//RESET Check
Reset_check: assert property (@(posedge clk) (!reset_n) |-> (current_state == IDLE && counter_wait ==0));

//State Transitions Check
Idle_to_wait_check: assert property (@(posedge clk) (current_state == IDLE && sensor_entrance) |-> (next_state == WAIT_PASSWORD));
Wait_password_increment_check: assert property (@(posedge clk) (current_state == WAIT_PASSWORD) |=> (counter_wait == $past(counter_wait) + 1));
Password_match_check: assert property (@(posedge clk) (current_state ==WAIT_PASSWORD && counter_wait > 3) && (password_1 ==2'b01 && password_2 == 2'b10) |-> (next_state == RIGHT_PASS));
Invalid_password_check: assert property (@(posedge clk) (current_state == WAIT_PASSWORD && counter_wait > 3) && !(password_1 == 2'b01 && password_2 == 2'b10) |-> (next_state == WRONG_PASS));
Stop_state_check: assert property (@(posedge clk) (current_state ==RIGHT_PASS && sensor_entrance && sensor_exit) |-> (next_state == STOP));
Stop_State_Condition: assert property (@(posedge clk) (current_state == RIGHT_PASS && sensor_entrance && sensor_exit) |-> next_state == STOP);

//LED Checks
led_right_pass_check: assert property (@(posedge clk) (current_state ==RIGHT_PASS) |=> (GREEN_LED != $past(GREEN_LED)));
led_wrong_pass_check: assert property (@(posedge clk) (current_state == WRONG_PASS) |=> (RED_LED !=$past(RED_LED)));
HEX_DISPLAY_WAIT_PASS_CHECK: assert property (@(posedge clk) (current_state == WAIT_PASSWORD) |=> (HEX_1 ==7'b000_0110 && HEX_2 ==7'b010_1011));
Hex_Display_Idle_Check: assert property (@(posedge clk) (current_state == IDLE) |=> (HEX_1 == 7'b111_1111 && HEX_2 ==7'b111_1111));
Hex_Display_Right_Check: assert property (@(posedge clk) (current_state == RIGHT_PASS) |=> (HEX_1 == 7'b000_0010 && HEX_2 == 7'b100_0000));
Hex_display_stop_check: assert property (@(posedge clk) (current_state == STOP) |=> (HEX_1 == 7'b001_0010 && HEX_2 == 7'b000_1100));

//Password Checks
Wait_to_right_pass_check: assert property (@(posedge clk) (current_state == WAIT_PASSWORD && counter_wait >3) && (password_1 == 2'b01 && password_2 == 2'b10) |-> (next_state == RIGHT_PASS));
Wait_to_wrong_check: assert property (@(posedge clk) (current_state == WAIT_PASSWORD && counter_wait >3 && !(password_1 == 2'b01 && password_2 == 2'b10) |-> next_state == WRONG_PASS));
Right_to_stop: assert property (@(posedge clk) (current_state == RIGHT_PASS && sensor_entrance && sensor_exit |-> next_state == STOP));
idle_invalidsensor_input: assert property (@(posedge clk)(current_state == IDLE) |-> !(sensor_entrance && sensor_exit));
idle_invalid_sensor_input: assert property (@(posedge clk)(current_state == RIGHT_PASS && sensor_entrance == 1 && sensor_exit == 1 && counter_wait > 3)|-> next_state == STOP);


//Counter Checks
counter_reset_on_state_change: assert property (@(posedge clk) (current_state != WAIT_PASSWORD |=> counter_wait == 0));
counter_does_not_overflow: assert property (@(posedge clk) (counter_wait <= 32'hFFFF_FFFF));
Wait_Password_Timeout: assert property (@(posedge clk) (current_state == WAIT_PASSWORD) |-> (counter_wait <= 32'h3 || next_state != WAIT_PASSWORD));
Counter_No_Decrease: assert property (@(posedge clk) (counter_wait >= $past(counter_wait) || (counter_wait == 0)));

// Wrong State Transitions check = THESE MUST FAIL
RIGHTPASS_to_STOP: assert property (@(posedge clk) (current_state == RIGHT_PASS && sensor_exit == 0 && sensor_entrance == 0 |=> next_state == STOP));
RIGHTPASS_to_STOP_2: assert property (@(posedge clk) (current_state == RIGHT_PASS && sensor_exit == 1 |-> next_state == STOP));
Wait_to_right_pass_wrong_check: assert property (@(posedge clk) (current_state == WAIT_PASSWORD && counter_wait >3) && (password_1 == 2'b01 && password_2 == 2'b11) |=> (next_state == RIGHT_PASS));
IDLE_to_STOP: assert property (@(posedge clk) (current_state == IDLE && next_state == STOP));
STOP_to_IDLE: assert property (@(posedge clk) (current_state == STOP && next_state == IDLE));


sequence STOP_seq;
	current_state == STOP ##1
	current_state == RIGHT_PASS;
endsequence

sequence_stop_check: assert property (@(posedge clk) disable iff (!reset_n && password_1 != 2'b01 && password_2 != 2'b10) (current_state == STOP && password_1 == 2'b01 && password_2 == 2'b10 && sensor_entrance == 1 && sensor_exit == 1) |-> STOP_seq);

sequence STOP_RIGHT_seq;
	current_state == STOP ##1
	current_state == RIGHT_PASS ##1
	current_state == STOP ##1
	current_state == RIGHT_PASS ##1
	current_state == STOP;
endsequence

STOP_RIGHT: assert property (@(posedge clk) disable iff (!reset_n && password_1 != 2'b01 && password_2 != 2'b10 && sensor_entrance != 1 && sensor_exit != 1) (password_1 == 2'b01 && password_2 == 2'b10 && sensor_entrance == 1 && sensor_exit ==1 && current_state == STOP) |-> STOP_RIGHT_seq);


endmodule
 

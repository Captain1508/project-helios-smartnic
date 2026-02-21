//==============================================================================
// Module: packet_detector
// Description: Detects packet start by identifying rising edge of data_valid
//              Generates single-cycle pulse when new packet begins
//
// Author: Aman Sharma
// Project: Helios SmartNIC - Phase 1
//==============================================================================

module packet_detector(
    input logic clk,
    input logic rst_n,
    input logic data_valid,
    output logic packet_start
);
//State Declaration
typedef enum logic { 
    IDLE = 1'b0,
    ACTIVE = 1'b1
 } state_t;
 //State Registers
state_t state_q; // Current state
state_t state_d; // Next state

//Sequential Logic
always_ff @(posedge clk) begin
    if(!rst_n) begin
        state_q <= IDLE;
    end else begin
        state_q <= state_d;
    end
end
//Combinational Logic 
always_comb begin 
    state_d = state_q;
    case(state_q) 
    IDLE: begin
        if(data_valid)
        state_d = ACTIVE;
    end 
    ACTIVE: begin
        if(!data_valid)
        state_d = IDLE;
    end
    endcase
end
//Output Logic
assign packet_start = (state_q == IDLE) && (state_d == ACTIVE);
endmodule
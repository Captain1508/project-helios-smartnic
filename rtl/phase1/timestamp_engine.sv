//==============================================================================
// Module: timestamp_engine
// Description: Free-running cycle counter providing deterministic timestamps
//              for packet arrival monitoring in HFT environments.
//              Increments by 1 every clock cycle, wraps automatically.
//
// Author: Aman Sharma
// Project: Helios SmartNIC - Phase 1
//==============================================================================

module timestamp_engine #(
    parameter TS_WIDTH = 64
)(
    input  logic                  clk,
    input  logic                  rst_n,
    output logic [TS_WIDTH-1:0]   timestamp
);

    // Internal Signals
    logic [TS_WIDTH-1:0] timestamp_counter;  // Registered counter value
    // Counter Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Synchronous reset: Initialize counter to zero
            timestamp_counter <= '0;
        end else begin
            // Increment counter every clock cycle
            // Wraps around automatically at max value (2^TS_WIDTH - 1)
            timestamp_counter <= timestamp_counter + 1;
        end
    end

    // Output Assignment
    assign timestamp = timestamp_counter;

endmodule
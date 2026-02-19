//==============================================================================
// Module: stats_engine
// Description: Tracks packet and byte statistics for network monitoring
//
// Author: Aman Sharma
// Project: Helios SmartNIC - Phase 1
//==============================================================================

module stats_engine (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        packet_valid,
    input  logic        packet_start,
    input  logic [7:0]  byte_count,
    output logic [63:0] total_packets,
    output logic [63:0] total_bytes
);

    // Internal Signals (if needed)

    // Counter Logic    
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            total_packets <= 0;
            total_bytes <= 0;
        end else begin
            if(packet_start)
                total_packets <= total_packets + 1;
            if(packet_valid) 
                total_bytes <= total_bytes + byte_count;
        end
    end

endmodule
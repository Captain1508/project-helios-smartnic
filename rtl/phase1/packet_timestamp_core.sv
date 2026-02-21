module packet_timestamp_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        data_valid,
    input  logic [7:0]  byte_count,
    output logic [63:0] current_timestamp,
    output logic        packet_start,
    output logic [63:0] packet_timestamp,
    output logic [63:0] total_packets,
    output logic [63:0] total_bytes
);

    // Internal Signals
    // YOUR CODE: What signals connect the modules?
    
    // Module Instantiations
    // Timestamp Engine
    timestamp_engine #(
        .TS_WIDTH(64)
    ) ts_engine (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(current_timestamp)
    );

    // Packet Detector
    packet_detector pkt_detect (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(data_valid),
        .packet_start(packet_start)
    );

    // Statistics Engine
    stats_engine stats (
        .clk(clk),
        .rst_n(rst_n),
        .packet_valid(data_valid),
        .packet_start(packet_start),
        .byte_count(byte_count),
        .total_packets(total_packets),
        .total_bytes(total_bytes)
    );

    // Timestamp Capture Logic
    always_ff @(posedge clk) begin 
    if(!rst_n) begin
        packet_timestamp <= 64'h0;
    end else if(packet_start) begin
        packet_timestamp <= current_timestamp;
    end
    end
endmodule
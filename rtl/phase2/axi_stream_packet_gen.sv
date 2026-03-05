/**
 * AXI-Stream Packet Generator
 * 
 * Generates test packets with AXI-Stream interface
 * Supports configurable packet length and data patterns
 * 
 * Phase 2 - Project Helios SmartNIC
 */

module axi_stream_packet_gen #(
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = DATA_WIDTH/8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Control interface
    input  logic                    start_packet,      // Pulse to start new packet
    input  logic [7:0]              packet_length,     // Number of beats in packet
    input  logic [DATA_WIDTH-1:0]   data_pattern,      // Base data pattern
    
    // AXI-Stream master interface
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic [DATA_WIDTH-1:0]   m_axis_tdata,
    output logic [KEEP_WIDTH-1:0]   m_axis_tkeep,
    output logic                    m_axis_tlast,
    
    // Status
    output logic                    busy,              // Generator is active
    output logic                    done               // Packet complete
);

    // State machine
    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        TRANSFER = 2'b01,
        DONE     = 2'b10
    } state_t;
    
    state_t state, state_next;
    
    // Internal registers
    logic [7:0] beat_counter;
    logic [7:0] packet_len_reg;
    logic [DATA_WIDTH-1:0] data_reg;
    
    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= state_next;
    end
    
    // Next state logic
    always_comb begin
        state_next = state;
        
        case (state)
            IDLE: begin
                if (start_packet)
                    state_next = TRANSFER;
            end
            
            TRANSFER: begin
                // Transfer complete when last beat accepted
                if (m_axis_tvalid && m_axis_tready && m_axis_tlast)
                    state_next = DONE;
            end
            
            DONE: begin
                state_next = IDLE;  // One cycle done pulse
            end
            
            default: state_next = IDLE;
        endcase
    end
    
    // Beat counter (tracks position in packet)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_counter <= '0;
        end else begin
            case (state)
                IDLE: begin
                    beat_counter <= '0;
                end
                
                TRANSFER: begin
                    // Increment when beat is accepted
                    if (m_axis_tvalid && m_axis_tready) begin
                        beat_counter <= beat_counter + 1'b1;
                    end
                end
                
                default: beat_counter <= '0;
            endcase
        end
    end
    
    // Capture packet parameters on start
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_len_reg <= '0;
            data_reg <= '0;
        end else if (state == IDLE && start_packet) begin
            packet_len_reg <= packet_length;
            data_reg <= data_pattern;
        end
    end
    
    // AXI-Stream outputs
    assign m_axis_tvalid = (state == TRANSFER);
    
    // Data: increment pattern each beat
    assign m_axis_tdata = data_reg + beat_counter;
    
    // Keep: all bytes valid
    assign m_axis_tkeep = {KEEP_WIDTH{1'b1}};
    
    // Last: final beat of packet
    assign m_axis_tlast = (beat_counter == packet_len_reg - 1'b1);
    
    // Status outputs
    assign busy = (state == TRANSFER);
    assign done = (state == DONE);

endmodule
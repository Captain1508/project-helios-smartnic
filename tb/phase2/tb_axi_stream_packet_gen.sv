`timescale 1ns/1ps

/**
 * Testbench for AXI-Stream Packet Generator
 * 
 * Tests:
 * 1. Single packet transmission
 * 2. Backpressure handling (TREADY = 0)
 * 3. Back-to-back packets
 * 4. Variable length packets
 */

module tb_axi_stream_packet_gen;

    // Parameters
    localparam DATA_WIDTH = 64;
    localparam KEEP_WIDTH = DATA_WIDTH/8;
    localparam CLK_PERIOD = 10;
    
    // Signals
    logic                    clk;
    logic                    rst_n;
    logic                    start_packet;
    logic [7:0]              packet_length;
    logic [DATA_WIDTH-1:0]   data_pattern;
    logic                    m_axis_tvalid;
    logic                    m_axis_tready;
    logic [DATA_WIDTH-1:0]   m_axis_tdata;
    logic [KEEP_WIDTH-1:0]   m_axis_tkeep;
    logic                    m_axis_tlast;
    logic                    busy;
    logic                    done;
    
    // Test tracking
    integer packets_sent;
    integer beats_received;
    integer test_errors;
    
    // DUT instantiation
    axi_stream_packet_gen #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_packet(start_packet),
        .packet_length(packet_length),
        .data_pattern(data_pattern),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tlast(m_axis_tlast),
        .busy(busy),
        .done(done)
    );
    
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Monitor received beats
    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            beats_received++;
            $display("[%0t] Beat %0d: TDATA=0x%h, TLAST=%0b", 
                     $time, beats_received, m_axis_tdata, m_axis_tlast);
        end
    end
    
    // Test stimulus
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        start_packet = 0;
        packet_length = 0;
        data_pattern = 0;
        m_axis_tready = 0;
        packets_sent = 0;
        beats_received = 0;
        test_errors = 0;
        
        $display("========================================");
        $display("AXI-Stream Packet Generator Test");
        $display("========================================\n");
        
        // Reset
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        //======================================================================
        // TEST 1: Single packet with always-ready
        //======================================================================
        $display("\n[TEST 1] Single Packet - Always Ready");
        $display("  Sending: 4-beat packet, pattern=0xABCD");
        
        m_axis_tready = 1;  // Always ready
        
        @(posedge clk);
        start_packet = 1;
        packet_length = 4;
        data_pattern = 64'hABCD;
        
        @(posedge clk);
        start_packet = 0;
        
        // Wait for completion
        wait(done == 1);
        @(posedge clk);
        
        if (beats_received == 4) begin
            $display("  ✓ PASS: Received 4 beats");
        end else begin
            $display("  ✗ FAIL: Expected 4 beats, got %0d", beats_received);
            test_errors++;
        end
        
        beats_received = 0;
        #(CLK_PERIOD * 2);
        
        //======================================================================
        // TEST 2: Packet with backpressure
        //======================================================================
        $display("\n[TEST 2] Backpressure Handling");
        $display("  Sending: 5-beat packet with intermittent TREADY");
        
        // Start packet
        @(posedge clk);
        start_packet = 1;
        packet_length = 5;
        data_pattern = 64'h1234;
        m_axis_tready = 1;
        
        @(posedge clk);
        start_packet = 0;
        
        // Apply backpressure pattern: ready, ready, not-ready, ready, ready
        fork
            begin
                @(posedge clk);
                m_axis_tready = 1;
                @(posedge clk);
                m_axis_tready = 1;
                @(posedge clk);
                m_axis_tready = 0;  // Backpressure!
                @(posedge clk);
                @(posedge clk);
                m_axis_tready = 1;
                @(posedge clk);
                m_axis_tready = 1;
            end
        join_none
        
        // Wait for completion
        wait(done == 1);
        @(posedge clk);
        
        if (beats_received == 5) begin
            $display("  ✓ PASS: Received 5 beats despite backpressure");
        end else begin
            $display("  ✗ FAIL: Expected 5 beats, got %0d", beats_received);
            test_errors++;
        end
        
        beats_received = 0;
        m_axis_tready = 1;
        #(CLK_PERIOD * 2);
        
        //======================================================================
        // TEST 3: Back-to-back packets
        //======================================================================
        $display("\n[TEST 3] Back-to-Back Packets");
        $display("  Sending: Two 3-beat packets back-to-back");
        
        m_axis_tready = 1;
        
        // Packet 1
        @(posedge clk);
        start_packet = 1;
        packet_length = 3;
        data_pattern = 64'h1111;
        
        @(posedge clk);
        start_packet = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  - Packet 1 complete (%0d beats)", beats_received);
        integer pkt1_beats = beats_received;
        beats_received = 0;
        
        // Packet 2 (immediately after)
        @(posedge clk);
        start_packet = 1;
        packet_length = 3;
        data_pattern = 64'h2222;
        
        @(posedge clk);
        start_packet = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  - Packet 2 complete (%0d beats)", beats_received);
        integer pkt2_beats = beats_received;
        
        if (pkt1_beats == 3 && pkt2_beats == 3) begin
            $display("  ✓ PASS: Both packets transmitted correctly");
        end else begin
            $display("  ✗ FAIL: Packet 1: %0d beats, Packet 2: %0d beats", pkt1_beats, pkt2_beats);
            test_errors++;
        end
        
        beats_received = 0;
        #(CLK_PERIOD * 2);
        
        //======================================================================
        // TEST 4: Variable length packets
        //======================================================================
        $display("\n[TEST 4] Variable Length Packets");
        
        integer lengths[4] = '{1, 8, 3, 16};
        integer i;
        
        for (i = 0; i < 4; i++) begin
            $display("  - Testing %0d-beat packet", lengths[i]);
            
            @(posedge clk);
            start_packet = 1;
            packet_length = lengths[i];
            data_pattern = 64'hDEAD + i;
            
            @(posedge clk);
            start_packet = 0;
            
            wait(done == 1);
            @(posedge clk);
            
            if (beats_received == lengths[i]) begin
                $display("    ✓ PASS: %0d beats received", beats_received);
            end else begin
                $display("    ✗ FAIL: Expected %0d, got %0d", lengths[i], beats_received);
                test_errors++;
            end
            
            beats_received = 0;
            #(CLK_PERIOD * 2);
        end
        
        //======================================================================
        // Test Summary
        //======================================================================
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total errors: %0d", test_errors);
        
        if (test_errors == 0) begin
            $display("✓ ALL TESTS PASSED!");
        end else begin
            $display("✗ SOME TESTS FAILED");
        end
        
        $display("========================================\n");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
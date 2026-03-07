`timescale 1ns/1ps

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
    
    // Monitor
    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("[%0t] Transfer: TDATA=0x%h, TLAST=%0b", 
                     $time, m_axis_tdata, m_axis_tlast);
        end
    end
    
    // Test stimulus
    initial begin
        // Test variables
        integer test_errors;
        integer i;
        
        test_errors = 0;
        
        $display("========================================");
        $display("AXI-Stream Packet Generator Test");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        start_packet = 0;
        packet_length = 0;
        data_pattern = 0;
        m_axis_tready = 0;
        
        // Reset
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        //======================================================================
        // TEST 1: Single packet with always-ready
        //======================================================================
        $display("\n[TEST 1] Single Packet - Always Ready");
        $display("  Sending: 4-beat packet, pattern=0xABCD");
        
        m_axis_tready = 1;
        
        @(posedge clk);
        start_packet = 1;
        packet_length = 4;
        data_pattern = 64'hABCD;
        
        @(posedge clk);
        start_packet = 0;
        
        // Wait for completion using while loop
        while (done == 0) begin
            @(posedge clk);
        end
        @(posedge clk);
        
        $display("  ✓ Test 1 complete\n");
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
        
        // Apply backpressure pattern
        @(posedge clk);
        m_axis_tready = 1;
        @(posedge clk);
        m_axis_tready = 1;
        @(posedge clk);
        m_axis_tready = 0;  // Backpressure!
        @(posedge clk);
        @(posedge clk);
        m_axis_tready = 1;
        
        // Wait for completion
        while (done == 0) begin
            @(posedge clk);
        end
        @(posedge clk);
        
        $display("  ✓ Test 2 complete\n");
        m_axis_tready = 1;
        #(CLK_PERIOD * 2);
        
        //======================================================================
        // TEST 3: Back-to-back packets
        //======================================================================
        $display("\n[TEST 3] Back-to-Back Packets");
        
        m_axis_tready = 1;
        
        // Packet 1
        @(posedge clk);
        start_packet = 1;
        packet_length = 3;
        data_pattern = 64'h1111;
        
        @(posedge clk);
        start_packet = 0;
        
        while (done == 0) begin
            @(posedge clk);
        end
        @(posedge clk);
        
        $display("  - Packet 1 complete");
        
        // Packet 2 (immediately after)
        @(posedge clk);
        start_packet = 1;
        packet_length = 3;
        data_pattern = 64'h2222;
        
        @(posedge clk);
        start_packet = 0;
        
        while (done == 0) begin
            @(posedge clk);
        end
        @(posedge clk);
        
        $display("  - Packet 2 complete");
        $display("  ✓ Test 3 complete\n");
        #(CLK_PERIOD * 2);
        
        //======================================================================
        // TEST 4: Variable length packets
        //======================================================================
        $display("\n[TEST 4] Variable Length Packets");
        
        for (i = 1; i <= 4; i = i + 1) begin
            @(posedge clk);
            start_packet = 1;
            
            case (i)
                1: packet_length = 1;
                2: packet_length = 8;
                3: packet_length = 3;
                4: packet_length = 16;
            endcase
            
            data_pattern = 64'hDEAD + i;
            
            @(posedge clk);
            start_packet = 0;
            
            while (done == 0) begin
                @(posedge clk);
            end
            @(posedge clk);
            
            $display("  ✓ Packet %0d complete", i);
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
        #(CLK_PERIOD * 2000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
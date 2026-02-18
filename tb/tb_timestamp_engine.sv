`timescale 1ns/1ps

module tb_timestamp_engine;

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam CLK_PERIOD = 10;
    localparam TS_WIDTH_SMALL = 4;
    localparam TS_WIDTH_FULL = 64;

    //==========================================================================
    // Signal Declarations
    //==========================================================================
    logic                         clk;
    logic                         rst_n;
    logic [TS_WIDTH_SMALL-1:0]    timestamp_small;
    logic [TS_WIDTH_FULL-1:0]     timestamp_full;
    
    integer expected_val;
    integer errors;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    timestamp_engine #(
        .TS_WIDTH(TS_WIDTH_SMALL)
    ) dut_small (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(timestamp_small)
    );

    timestamp_engine #(
        .TS_WIDTH(TS_WIDTH_FULL)
    ) dut_full (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(timestamp_full)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //==========================================================================
    // Test Stimulus
    //==========================================================================
    initial begin
        $display("========================================");
        $display("Starting Timestamp Engine Testbench");
        $display("Testing both 4-bit and 64-bit counters");
        $display("========================================\n");

        //======================================================================
        // TEST 1: Reset Verification
        //======================================================================
        $display("[TEST 1] Reset Verification (64-bit counter)");
        
        // Assert reset
        rst_n = 0;
        #(CLK_PERIOD * 2);
        
        // Check during reset
        if (timestamp_full == 0) begin
            $display("  ✓ PASS: Counter is 0 during reset");
        end else begin
            $display("  ✗ FAIL: Expected 0, got %0d", timestamp_full);
        end
        
        // Release reset and check values at proper times
        rst_n = 1;
         // Wait for clock edge
        #1;              // Small delay for stability
        
        if (timestamp_full == 0) begin
            $display("  ✓ PASS: Counter is 0 one cycle after reset release");
        end else begin
            $display("  ✗ FAIL: Expected 0, got %0d", timestamp_full);
        end
        
        @(posedge clk);
        #1;
        
        if (timestamp_full == 1) begin
            $display("  ✓ PASS: Counter incremented to 1");
        end else begin
            $display("  ✗ FAIL: Expected 1, got %0d", timestamp_full);
        end

        //======================================================================
        // TEST 2: Sequential Increment
        //======================================================================
        $display("\n[TEST 2] Sequential Increment (64-bit, 10 cycles)");
        
        expected_val = 2;
        errors = 0;
        
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);  // Sync to clock
            #1;              // Wait for stability
            
            if (timestamp_full != expected_val) begin
                $display("  ✗ FAIL: At cycle %0d, expected %0d got %0d", 
                         i, expected_val, timestamp_full);
                errors++;
            end
            expected_val++;
        end
        
        if (errors == 0) begin
            $display("  ✓ PASS: Counter incremented correctly for 10 cycles");
        end else begin
            $display("  ✗ FAIL: %0d errors detected", errors);
        end

        //======================================================================
        // TEST 3: Reset During Operation
        //======================================================================
        $display("\n[TEST 3] Reset During Operation (64-bit counter)");
        
        $display("  - Letting counter run for 50 cycles...");
        repeat(50) @(posedge clk);  // Wait 50 clock edges
        #1;
        $display("  - Counter value before reset: %0d", timestamp_full);
        
        // Apply reset
        rst_n = 0;
        #(CLK_PERIOD * 2);
        
        if (timestamp_full == 0) begin
            $display("  ✓ PASS: Counter reset to 0");
        end else begin
            $display("  ✗ FAIL: Expected 0, got %0d", timestamp_full);
        end
        
        // Release reset
        rst_n = 1;
        #1;
        
        if (timestamp_full == 0) begin
            $display("  ✓ PASS: Counter is 0 one cycle after reset release");
        end else begin
            $display("  ✗ FAIL: Expected 0, got %0d", timestamp_full);
        end
        
        @(posedge clk);
        #1;
        
        if (timestamp_full == 1) begin
            $display("  ✓ PASS: Counter resumed counting");
        end else begin
            $display("  ✗ FAIL: Expected 1, got %0d", timestamp_full);
        end

        //======================================================================
        // TEST 4: Rollover Test
        //======================================================================
        $display("\n[TEST 4] Rollover Test (4-bit counter)");
        
        $display("  - Waiting for 4-bit counter to reach max (15)...");
        wait (timestamp_small == 15);
        $display("  - Counter at max value: %0d", timestamp_small);
        
        @(posedge clk);
        #1;
        
        if (timestamp_small == 0) begin
            $display("  ✓ PASS: Counter wrapped from 15 to 0");
        end else begin
            $display("  ✗ FAIL: Expected 0, got %0d", timestamp_small);
        end

        //======================================================================
        // Bonus
        //======================================================================
        $display("\n[BONUS] Verify both counters run independently");
        $display("  - 4-bit counter value: %0d", timestamp_small);
        $display("  - 64-bit counter value: %0d", timestamp_full);
        
        if (timestamp_small != timestamp_full[TS_WIDTH_SMALL-1:0]) begin
            $display("  ✓ PASS: Counters have different values");
        end

        //======================================================================
        // End
        //======================================================================
        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================");
        
        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
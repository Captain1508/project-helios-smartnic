`timescale 1ns/1ps

module tb_packet_detector;

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam CLK_PERIOD = 10;

    //==========================================================================
    // Signals
    //==========================================================================
    logic clk;
    logic rst_n;
    logic data_valid;
    logic packet_start;

    integer packet_count;
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    packet_detector dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(data_valid),
        .packet_start(packet_start)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            packet_count = 0;
        end else if (packet_start) begin
            packet_count++;
        end
    end

    //==========================================================================
    // Test Stimulus
    //==========================================================================
    initial begin
        $display("========================================");
        $display("Packet Detector Testbench");
        $display("========================================\n");

        // Initialize
        data_valid = 0;
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        @(posedge clk);
        #1;

        //======================================================================
        // TEST 1: Reset State
        //======================================================================
        $display("[TEST 1] Reset Verification");
        // Check FSM is in IDLE (packet_start should be 0)
        if(packet_start == 0) begin
            $display("Pass: FSM is in IDLE state(packet_start = 0)");
        end else begin 
            $display("Fail: Expected packet_start = 0 got %0d",packet_start);
        end
        //======================================================================
        // TEST 2: Single Packet Detection
        //======================================================================
        $display("\n[TEST 2] Single Packet Detection");
        // Apply data_valid = 1
        // Check packet_start pulses for ONE cycle
        // Check packet_start goes back to 0 (even though data_valid still high)
        data_valid = 1;
        @(posedge clk);
        
        if(packet_start == 1) begin 
            $display("Pass: packet_start asserted for one cycle");
        end else begin 
            $display("Fail: Expected packet_start = 1 got %0d",packet_start);
        end
        @(posedge clk);
        #1;         
        if(packet_start == 0) begin
            $display("Pass: packet_start deasserted");
        end else begin
            $display("Fail: Expected packet_start = 0  got %0d",packet_start);
        end
        data_valid = 0;
        @(posedge clk);
        #1;
        //======================================================================
        // TEST 3: Back-to-Back Packets
        //======================================================================
        $display("\n[TEST 3] Back-to-Back Packets");
        // Packet 1: data_valid high for 5 cycles
        // Gap: data_valid = 0 for 2 cycles
        // Packet 2: data_valid high for 3 cycles
        // Should see TWO packet_start pulses
        packet_count = 0;
        data_valid = 1;
        repeat (5) @(posedge clk);
        data_valid = 0;
        repeat (2) @(posedge clk);
        data_valid = 1;
        repeat (3) @(posedge clk);
        data_valid = 0;
        @(posedge clk);
        #1;
        if(packet_count == 2) begin
            $display("Pass: Detected two packet_start pulses ");
        end else begin 
            $display("Fail: Expected two packet_start pulses got %0d",packet_count);
        end 
        //======================================================================
        // TEST 4: Long Packet
        //======================================================================
        $display("\n[TEST 4] Long Packet (No Re-trigger)");
        // data_valid high for 20 cycles
        // packet_start should pulse ONLY at start
        // YOUR CODE HERE
        packet_count = 0;
        data_valid = 1;
        repeat (20) @(posedge clk);
        data_valid = 0;
        @(posedge clk);
        #1;
        if(packet_count == 1) begin
            $display("Pass: packet_start pulses");
        end else begin
            $display("Fail: Expected packet_start = 1 got %0d , % 0d",packet_count);
        end
        

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================");
        $finish;
    end

endmodule
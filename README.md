# Project Helios - FPGA SmartNIC Packet Processing Engine

**Status:** Phase 1 Development - In Progress
## Phase 1 Progress

### Day 1: Timestamp Engine Core ✓ COMPLETE
**Module:** `timestamp_engine.sv`
- 64-bit free-running cycle counter
- Parameterizable width (tested with 4-bit and 64-bit)
- Synchronous active-low reset
- 10ns resolution @ 100 MHz

**Performance:**
- Resource: ~65 LUTs, 64 registers
- Timing: Meets 100 MHz with margin
- Fmax: >200 MHz on Artix-7

### Day 2: Testbench & Verification ✓ COMPLETE
**Module:** `tb_timestamp_engine.sv`
- Self-checking testbench with automated pass/fail
- 4 comprehensive test cases:
  1. Reset verification
  2. Sequential increment (10 cycles)
  3. Reset during operation
  4. Rollover behavior (4-bit counter)
- Tests both 4-bit and 64-bit configurations simultaneously
- All tests passing ✓

**Next:** Day 3 - Packet Detector FSM

## Overview
Hardware-accelerated packet timestamping and monitoring engine inspired by SmartNIC architectures used in high-frequency trading environments.

## Current Phase: Packet Timestamp Core
Implementing deterministic hardware timestamping with nanosecond precision.

## Architecture
[Will add block diagram after Day 5]

## Project Phases
- **Phase 1:** Packet Timestamp & Counter Core (Current)
- **Phase 2:** AXI-Stream & Backpressure Handling (Planned)
- **Phase 3:** Latency Correlation Engine (Planned)
- **Phase 4:** Inline Decision Pipeline (Planned)

## Development Environment
- **Target FPGA:** Xilinx Artix-7
- **HDL:** SystemVerilog
- **Tools:** Vivado 2023.x
- **Clock:** 100 MHz (Phase 1)

## Author
Aman Sharma | [GitHub: Captain1508](https://github.com/Captain1508)

---
*Last Updated: 18/02/2026
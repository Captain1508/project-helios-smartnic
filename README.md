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

---

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

---

### Day 3: Packet Detector FSM ✓ COMPLETE
**Module:** `packet_detector.sv`
- Two-state FSM (IDLE, ACTIVE)
- Detects rising edge of `data_valid` signal
- Generates single-cycle `packet_start` pulse
- Clean state transitions with synchronous reset

**Verification:** `tb_packet_detector.sv`
- 4 comprehensive test cases (all passing):
  1. Reset state verification
  2. Single packet detection
  3. Back-to-back packet handling
  4. Long packet (no re-trigger)
- Waveforms captured for all scenarios

---

### Day 4: Statistics Engine ✓ COMPLETE
**Module:** `stats_engine.sv`
- 64-bit packet counter (increments on every `packet_start` pulse)
- 64-bit byte counter (accumulates `byte_count` when `packet_valid` asserted)
- Simultaneous packet and byte tracking
- Synchronous active-low reset

**Verification:** `tb_stats_engine.sv`
- 4 comprehensive test cases (all passing):
  1. Reset state verification
  2. Packet counting accuracy
  3. Byte accumulation across variable-length packets
  4. Simultaneous packet + byte counting
- All counters verified against expected values ✓

---

### Day 5: Top-Level Integration ✓ COMPLETE
**Module:** `packet_timestamp_core.sv`
- Integrates all three sub-modules: `timestamp_engine`, `packet_detector`, `stats_engine`
- Captures timestamp at exact moment of packet detection
- Single additional register for timestamp latch (minimal logic overhead)
- Clean hierarchical design with no redundant logic

**Verification:** `tb_packet_timestamp_core.sv`
- 4 system-level test cases (all passing):
  1. Single packet timestamping
  2. Multiple packets with gap (unique timestamps verified)
  3. Back-to-back packets (minimal 1-cycle gap)
  4. Long packet (single `packet_start` pulse confirmed)
- Concurrent packet monitor verifying pulse behavior ✓

---

### Day 6: Synthesis & Timing Analysis ✓ COMPLETE
**Target:** Xilinx Artix-7 (xc7a35tcpg236-1) @ 100 MHz

**Resource Utilization:**
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Slice LUTs | 12 | 20,800 | 0.06% |
| Slice Registers (FFs) | 257 | 41,600 | 0.62% |
| Latches | 0 | — | 0% ✓ |

**Timing Results:**
| Metric | Result |
|--------|--------|
| Target Clock | 100 MHz (10ns period) |
| Worst Negative Slack (WNS) | +0.733 ns |
| Timing Violations | 0 |
| Failing Endpoints | 0 / 963 |
| **Fmax** | **~107.9 MHz** |

**All timing constraints met.** Design exceeds 100 MHz target by ~8 MHz.

---

## Overview
Hardware-accelerated packet timestamping and monitoring engine inspired by SmartNIC architectures used in high-frequency trading environments.

## Current Phase: Packet Timestamp Core
Implementing deterministic hardware timestamping with nanosecond precision.

## Architecture
[Block diagram — coming after Phase 1 complete]

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
*Last Updated: 21/02/2026*
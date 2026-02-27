# 📡 OCT Modem Frame Constructor  
**SDA OCT Standard v4.0.0 – Verilog Implementation**

---

## 1. Overview

This repository implements a synchronous Verilog module that performs OCT Modem Frame Construction in accordance with the SDA Optical Communications Terminal (OCT) Standard v4.0.0.

The design accepts payload data and generates a correctly formatted OCT modem frame suitable for transmission. The implementation follows a deterministic FSM-based architecture and supports continuous back-to-back frame generation.

---

## 2. Functional Features

The module supports construction of modem frames consisting of:

- 64-bit Preamble  
- 128-bit Header  
- Header CRC-16  
- Zero Tail Field  
- Payload (Data / Management / Idle)  
- Payload CRC-32  
- Bit-wise Scrambling  

Supported frame types:

| Frame Type | Description |
|------------|-------------|
| 00 | Idle Frame |
| 01 | Data Frame |
| 10 | Management Frame |
| 11 | Reserved |

---

## 3. Design Architecture

The implementation follows a clear separation of control and datapath logic.

### 3.1 Control Path
- Finite State Machine (FSM)
- Frame sequencing control
- CRC enable/clear control
- Frame completion logic
- Busy indication

### 3.2 Datapath
- Header construction logic
- Idle frame LFSR generator
- Management frame builder
- Payload assembler
- CRC-16 generator (header)
- CRC-32 generator (payload)
- Scrambler
- Serial output driver

### 3.3 FSM States
IDLE → PREAMBLE → HEADER → PAYLOAD → IDLE


The FSM ensures deterministic frame construction and supports immediate generation of consecutive frames without idle gaps.

---

## 4. Module Interface

### Inputs

| Signal | Description |
|--------|------------|
| clk | System clock |
| rst_n | Active-low synchronous reset |
| start_frame | Frame transmission trigger |
| payload_valid | Indicates valid payload data |
| payload_data | Payload input data |
| payload_length | Payload length (reserved for extension) |
| FRAME_TYPE_i | Frame type selector |

### Outputs

| Signal | Description |
|--------|------------|
| frame_valid | Indicates active frame transmission |
| data_out | Bit-serial frame output |
| frame_done | Indicates frame completion |
| FRAME_TYPE | Active frame type |
| busy | Module busy indicator |

---

## 5. Frame Construction Flow

Frame generation follows the sequence:
Preamble
↓
Header
↓
Header CRC-16
↓
Zero Tail
↓
Payload
↓
Payload CRC-32
↓
Scrambled Serial Output

All fields are transmitted bit-serially.

---

## 6. Design Characteristics

- Fully synchronous implementation  
- Deterministic reset behavior  
- FSM-based architecture  
- Back-to-back frame support (no inter-frame gaps)  
- Parameterizable frame components  
- Bit-serial transmission output  
- CRC-16 and CRC-32 error detection  
- LFSR-based idle frame generation  
- Payload scrambling  

---

## 7. Testbench

The provided testbench verifies:

- Idle frame generation  
- Management frame generation  
- Data frame generation  
- Continuous back-to-back operation  
- Frame completion signaling  
- Busy signal behavior  

Simulation prints frame completion events and active frame types for verification.

---

## 8. Assumptions and Limitations

- Fixed payload size in current implementation  
- Single clock domain  
- Bit-serial output interface  
- ARQ logic not implemented  
- FEC encoding not included (future extension)  

---

## 9. Repository Structure

```
OCT-Frame-Constructor/
├── rtl/
│   ├── OCT.v
│   ├── crc16_header.v
│   ├── crc32_payload.v
├── tb/
│   ├── OCT_idle_tb.v
└── README.md
```

---

## 10. Future Enhancements

- Full parameterized payload length support  
- AXI-Stream interface wrapper  
- LDPC / FEC integration  
- ARQ state machine implementation  
- Formal verification support  
- Synthesis timing optimization  

---

## 11. Compliance Statement

This implementation aligns with the framing structure defined in SDA OCT Standard v4.0.0 (Layer 2 – Framing, Coding, and Encapsulation).

The module is intended as an RTL-level implementation for educational and prototyping purposes.

---

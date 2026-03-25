# Two-Zone FPGA Security System

A dual-zone intruder detection security system implemented in VHDL on a Xilinx Spartan-7 FPGA (Boolean Board).

## Overview

The system monitors two sensor zones — a **garden (outer) zone** and a **home (inner) zone** — and responds with escalating alerts depending on which zone is triggered:

- **Garden sensor tripped:** A short buzzer alert sounds for 2 seconds, then the system returns to idle.
- **Home sensor tripped:** A 9-second countdown begins with the timer displayed on the 7-segment display. The user must enter the correct 4-bit code using the switches and press the confirm button before the countdown reaches zero. If the countdown expires, a full siren alarm activates.
- **Alarm active:** The siren continues until the correct code is entered and confirmed.

## Hardware Components

| Component | Details |
|---|---|
| FPGA | Xilinx Spartan-7 XC7S50-CSGA324 (Boolean Board) |
| Sensors | 2× photoresistor / laser emitter pairs (active-low) |
| Audio module | DY-SV17F |
| Buzzer | Connected via audio module trigger pins |
| Display | 4-digit 7-segment display (countdown shown on rightmost digit) |
| User input | 4× slide switches + 1 confirm button |

## Finite State Machine

The system is implemented as a synchronous FSM with four states:

```
                  GARDEN sensor tripped
       ┌──────────────────────────────────────┐
       │                                      ▼
  ┌────┴────┐                        ┌────────────────┐
  │ S_IDLE  │                        │ S_GARDEN_ALERT │
  └────┬────┘                        └────────────────┘
       │                              after 2 s → S_IDLE
       │ HOME sensor tripped
       ▼
┌──────────────────┐  timer = 0   ┌──────────┐
│ S_HOME_COUNTDOWN │─────────────►│ S_ALARM  │
└──────────────────┘              └──────────┘
       │ correct code                   │ correct code
       └──────────────► S_IDLE ◄────────┘
```

| State | Description | Audio output |
|---|---|---|
| `S_IDLE` | System armed, waiting for a sensor trigger | Silent |
| `S_GARDEN_ALERT` | Outer zone breached — short buzzer alert | Buzzer (T6=0, R7=1) |
| `S_HOME_COUNTDOWN` | Inner zone breached — countdown timer active | Silent |
| `S_ALARM` | Countdown expired — full siren alarm | Siren (T6=1, R7=0) |

## Pin Assignments

### Clock & Reset

| Signal | Pin | Notes |
|---|---|---|
| `CLK_IN` | F14 | 100 MHz system clock |
| `RST` | J5 | Active-high reset |

### User Inputs

| Signal | Pin | Notes |
|---|---|---|
| `SWITCHES[0]` | V2 | Code bit 0 |
| `SWITCHES[1]` | U2 | Code bit 1 |
| `SWITCHES[2]` | U1 | Code bit 2 |
| `SWITCHES[3]` | T2 | Code bit 3 |
| `BTN_CONFIRM` | J2 | Confirm / disarm button |

### Sensors (Pmod Port A — active-low)

| Signal | Pin |
|---|---|
| `SENSOR_GARDEN` | A14 |
| `SENSOR_HOME` | B14 |

### Audio Trigger Pins

| Signal | Pin |
|---|---|
| `TRIG_T6` | T6 |
| `TRIG_R7` | R7 |

### 7-Segment Display

| Signal | Pins |
|---|---|
| `DISPL[6:0]` | D7, C5, A5, B7, A7, D6, B5 |
| `ANODE[3:0]` | D5, C4, C7, A8 |

## Security Code

The default disarm code is `1010` (binary), corresponding to switches 3 and 1 set high and switches 2 and 0 set low. To change the code, modify the `SECRET_CODE` constant in `design.vhdl`:

```vhdl
CONSTANT SECRET_CODE : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
```

## Project Files

| File | Description |
|---|---|
| `design.vhdl` | VHDL source — entity, FSM, and output logic |
| `constraints.xlc` | Xilinx constraints file — pin assignments and clock definition |

## Building

Open the project in **Xilinx Vivado**, add `design.vhdl` as the design source and `constraints.xlc` as the constraints file, then synthesize, implement, and generate the bitstream for the Spartan-7 XC7S50-CSGA324 target device.

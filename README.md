# 光Ruby(ひかるびー) - ながらRuby会議01デモ

https://regional.rubykaigi.org/nagara01/

A collection of PicoRuby demonstration projects for Nagara Ruby Conference 01. This repository showcases the integration of Ruby programming with LED control, sensor input, and real-time audio-visual effects on ESP32 devices.

## Overview

This project demonstrates the "Hikaru Ruby" (Glowing Ruby) concept - interactive LED demonstrations controlled by PicoRuby on ATOM Matrix ESP32 devices. Featured demonstrations include:
- **Voice-controlled LED patterns** with Unit ASR voice recognition
- **Motion-responsive lighting** using MPU6886 accelerometer integration  
- **Real-time MIDI visualization** with synchronized LED matrix displays
- **PC-ATOM Matrix communication** for live music performance visualization
- **Distance-based interactions** with VL53L0X ToF sensor integration
- Memory-efficient embedded Ruby programming optimized for live demonstrations

## Architecture

**Hybrid C++/Ruby System**:
- ESP-IDF framework for low-level hardware access
- PicoRuby runtime (R2P2-ESP32) for application logic
- Ruby scripts for sensor demos and LED control

**Key Components**:

**ATOM Matrix (PicoRuby)**:
- `n25.rb`: Basic 5x5 LED matrix demonstration  
- `n25imu.rb`: IMU-responsive LED matrix with motion detection
- `n25r.rb`: Voice-controlled LED patterns with Unit ASR
- `n60.rb`: 60-LED strip basic control demonstration
- `n60a.rb`: Accelerometer-driven 60-LED animations
- `n60d.rb`: Distance-sensitive LED strip with VL53L0X sensor
- `n60pc.rb`: PC communication bridge for LED strip control
- `n60syn.rb`: MIDI-controlled LED strip visualization
- `n60synimu.rb`: Combined MIDI and IMU responsive LED effects

**PC Side (CRuby)**:
- `syn_pc.rb`: MIDI input bridge for real-time music visualization
- `key_pc.rb`: Keyboard control interface for LED demonstrations

## Quick Start

**Prerequisites**:
- ESP-IDF installed at `$HOME/esp/esp-idf/`
- Homebrew with OpenSSL (macOS)
- ATOM Matrix ESP32 device

**Setup**:
```bash
rake init          # Initialize project and dependencies
rake build         # Build for ESP32
rake flash         # Flash to device
```

**Development Commands**:
```bash
rake -T            # List all available tasks
rake update        # Update R2P2-ESP32 dependencies
rake cleanbuild    # Clean rebuild
rake check_env     # Verify environment setup
```

## Project Structure

```
nagara01-demo/
├── src_components/              # Source components (tracked in git)
│   ├── R2P2-ESP32/
│   │   └── storage/home/        # PicoRuby demonstration files
│   │       ├── n25.rb          # Basic 5x5 LED matrix demo
│   │       ├── n25imu.rb       # IMU-responsive LED matrix
│   │       ├── n25r.rb         # Voice-controlled LEDs
│   │       ├── n60.rb          # 60-LED strip basic demo
│   │       ├── n60a.rb         # Accelerometer LED animations
│   │       ├── n60d.rb         # Distance-sensitive LEDs
│   │       ├── n60pc.rb        # PC communication bridge
│   │       ├── n60syn.rb       # MIDI LED visualization
│   │       └── n60synimu.rb    # Combined MIDI+IMU effects
│   └── pc/                     # PC-side Ruby applications
│       ├── syn_pc.rb           # MIDI input bridge
│       ├── key_pc.rb           # Keyboard control interface
│       ├── Gemfile             # Ruby dependencies
│       └── Gemfile.lock        # Dependency lock file
├── components/                  # Build directory (auto-generated)
├── build_config/                # Build configuration
│   └── xtensa-esp.rb           # Ruby gem configuration
└── Rakefile                    # Build automation
```

## Conference Demonstrations

**Basic LED Matrix** (`n25.rb`):
Fundamental 5x5 LED matrix control demonstrating the core PicoRuby LED programming concepts for conference attendees.

**Motion-Responsive Visuals** (`n25imu.rb`, `n60a.rb`):
Accelerometer-driven LED animations that respond to device movement and orientation changes in real-time.

**Voice-Controlled Lighting** (`n25r.rb`):
Unit ASR integration enabling voice commands to control LED patterns and colors during live demonstrations.

**Large Scale LED Control** (`n60.rb`, `n60d.rb`):
60-LED strip demonstrations featuring distance-sensitive patterns and large-scale visual effects for audience engagement.

**Live Music Visualization** (`n60syn.rb`, `n60synimu.rb`):
Real-time MIDI visualization with combined motion sensing for interactive music performance displays.

**PC Integration** (`n60pc.rb` + PC-side Ruby):
Bidirectional communication between ATOM Matrix and PC enabling complex interactive demonstrations and audience participation.

## Development Notes

- **Memory optimization**: Pre-allocated arrays and minimal dynamic allocation for embedded constraints
- **Sensor integration**: MPU6886 and VL53L0X sharing I2C bus with proper address management
- **UART communication**: Dual-mode support for USB (115200bps) and Grove (31250bps/115200bps)
- **LED control**: RMT peripheral for precise WS2812 timing with brightness safety limits
- **MIDI processing**: Binary message handling with real-time visualization capabilities
- All Ruby gems configured in `build_config/xtensa-esp.rb`

## Hardware Support

Tested with ATOM Matrix ESP32 devices featuring:
- **ESP32-PICO-D4** microcontroller (240MHz dual-core)
- **MPU6886** 6-axis IMU (I2C address 0x68)
- **5×5 WS2812** LED matrix (GPIO 27, 25 LEDs total)
- **Grove connector** for UART/I2C expansion (GPIO 26, 32)
- **USB-C interface** for programming and serial communication
- **Built-in button** (GPIO 39) for user input

**Compatible peripherals**:
- Unit ASR (CI-03T) voice recognition module
- MIDI Unit (SAM2695) synthesizer module  
- VL53L0X ToF distance sensor (I2C address 0x29)
- External WS2812 LED strips (15-60 LEDs)

## Conference Usage

This project was designed for live demonstrations at Nagara Ruby Conference 01, showcasing the "Hikaru Ruby" concept where Ruby code directly controls physical LED displays and responds to real-world sensor input. Each demonstration file is optimized for audience engagement and visual impact.

## License

This project serves as educational examples for PicoRuby development on ESP32 platforms and conference demonstration purposes.
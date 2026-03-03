# Nimphea Audio Template

A starter project for the Daisy Audio Platform with a pre-configured audio processing callback.

## Features
- Stereo audio passthrough boilerplate.
- Real-time safety guidelines.
- Standard Nimble-based project structure.
- Pre-configured build and flash tasks.

## Usage

1. Install Nimphea:
   ```bash
   nimble install nimphea
   ```

2. Build for ARM:
   ```bash
   nimble make
   ```

3. Flash via USB DFU:
   - Put Daisy in DFU mode (BOOT + RESET).
   ```bash
   nimble flash
   ```

## Audio Rules
Embedded audio requires strict deterministic behavior:
- No heap allocations (avoid `seq`, `string`, `new`).
- No blocking calls (avoid `delay`, `print`).
- Keep processing fast enough to fit within the block size (~1ms).

## Files
- `src/main.nim`: Main application entry point with `audioCallback`.
- `project.nimble`: Project configuration and build scripts.
- `src/panicoverride.nim`: Custom panic handler for bare metal.

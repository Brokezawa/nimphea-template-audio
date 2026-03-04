## Project configuration for Nimphea project
## This file is automatically loaded by the Nim compiler
##
## This is a self-contained configuration - no external dependencies

import std/os, std/strutils

# Find nimphea package - must be installed via nimble
const nimpheaPath = strip(staticExec("nimble path nimphea 2>/dev/null || echo ''"))

when nimpheaPath.len == 0:
  static:
    echo "Error: nimphea package not found."
    echo "Please install nimphea: nimble install nimphea"
    quit(1)

# Nimble flattens srcDir to the package root on install, so nimphea.nim may be at
# the package root (installed) or under src/ (develop mode). Detect which.
let nimpheaSrc =
  if fileExists(nimpheaPath / "src" / "nimphea.nim"): nimpheaPath / "src"
  else: nimpheaPath

# Base configuration
switch("path", nimpheaSrc)
switch("backend", "cpp")
switch("cpu", "arm")
switch("os", "standalone")
switch("cc", "gcc")
switch("gcc.exe", "arm-none-eabi-gcc")
switch("gcc.cpp.exe", "arm-none-eabi-g++")
switch("mm", "arc")
switch("opt", "size")
switch("exceptions", "goto")
switch("define", "useMalloc")
switch("define", "noSignalHandler")

# ARM CPU flags
switch("passC", "-mcpu=cortex-m7")
switch("passC", "-mthumb")
switch("passC", "-mfpu=fpv5-d16")
switch("passC", "-mfloat-abi=hard")

# General compiler flags from libDaisy Makefile
switch("passC", "-Wall")
switch("passC", "-Wno-missing-attributes")
switch("passC", "-Wno-stringop-overflow")
switch("passC", "-fdata-sections")
switch("passC", "-ffunction-sections")
switch("passC", "-fno-exceptions")
switch("passC", "-fno-rtti")
switch("passC", "-fno-unwind-tables")
switch("passC", "-fshort-enums")
switch("passC", "-std=gnu++14")

# Include paths from nimphea
switch("passC", "-I" & nimpheaPath / "libDaisy/src")
switch("passC", "-I" & nimpheaPath / "libDaisy")
switch("passC", "-I" & nimpheaPath / "libDaisy/Drivers/STM32H7xx_HAL_Driver/Inc")
switch("passC", "-I" & nimpheaPath / "libDaisy/Drivers/CMSIS_5/CMSIS/Core/Include")
switch("passC", "-I" & nimpheaPath / "libDaisy/src/sys")
switch("passC", "-I" & nimpheaPath / "libDaisy/Drivers/CMSIS-Device/ST/STM32H7xx/Include")
switch("passC", "-I" & nimpheaPath / "libDaisy/Middlewares/ST/STM32_USB_Host_Library/Core/Inc")
switch("passC", "-I" & nimpheaPath / "libDaisy/src/usbh")
switch("passC", "-I" & nimpheaPath / "libDaisy/src/usbd")
switch("passC", "-I" & nimpheaPath / "libDaisy/Middlewares/Third_Party/FatFs/src")
switch("passC", "-I" & nimpheaPath / "libDaisy/Middlewares/ST/STM32_USB_Device_Library/Core/Inc")
switch("passC", "-I" & nimpheaPath / "libDaisy/Middlewares/ST/STM32_USB_Host_Library/Class/MSC/Inc")

# CMSIS-DSP include paths (headers always available, library is opt-in)
switch("passC", "-I" & nimpheaPath / "libDaisy/Drivers/CMSIS-DSP/Include")
switch("passC", "-I" & nimpheaPath / "libDaisy/Drivers/CMSIS_5/CMSIS/DSP/Include")

# Preprocessor defines from libDaisy Makefile
switch("passC", "-DUSE_HAL_DRIVER")
switch("passC", "-DSTM32H750xx")
switch("passC", "-DHSE_VALUE=16000000")
switch("passC", "-DCORE_CM7")
switch("passC", "-DSTM32H750IB")
switch("passC", "-DARM_MATH_CM7")
switch("passC", "-DUSE_FULL_LL_DRIVER")
switch("passC", "-DFILEIO_ENABLE_FATFS_READER")

# Linker flags from libDaisy Makefile
switch("passL", "-lc")
switch("passL", "-lm")
switch("passL", "-lnosys")
switch("passL", "-Wl,--cref")

# Boot mode selection (opt-in via -d:bootSram or -d:bootQspi)
# Default: direct flash (no bootloader)
#
# Three boot modes are supported:
#   1. BOOT_NONE (default): Direct flash to internal flash (0x08000000)
#      - No bootloader required
#      - Fastest startup, full control over memory layout
#      - Best for new projects and development
#      - Use: No special defines needed
#
#   2. BOOT_SRAM: Application runs from SRAM (0x20000000), loaded from bootloader
#      - Requires a DFU bootloader pre-installed on device
#      - Allows iterative development without re-flashing bootloader
#      - Limited SRAM (512KB) restricts application size
#      - Use: -d:bootSram (add to customDefines in project.nimble)
#
#   3. BOOT_QSPI: Application stored in QSPI flash (0x90040000)
#      - Requires a DFU bootloader with QSPI support
#      - Provides unlimited code space (128MB QSPI available)
#      - Essential for large applications (e.g., with CMSIS-DSP at 1MB)
#      - Use: -d:bootQspi (add to customDefines in project.nimble)
#
# To change boot mode:
#   Edit project.nimble and change the customDefines line:
#   - Direct flash:  customDefines = ""
#   - From SRAM:     customDefines = "bootSram"
#   - From QSPI:     customDefines = "bootQspi"
#
# Flash commands change based on boot mode:
#   - BOOT_NONE: Use 'nimble stlink' (direct flash via ST-Link) OR 'nimble flash' (DFU)
#   - BOOT_SRAM: Use 'nimble flash' (DFU bootloader required)
#   - BOOT_QSPI: Use 'nimble flash' (DFU bootloader required)

when defined(bootQspi):
  switch("passC", "-DBOOT_APP")
  switch("passL", "-T" & nimpheaPath / "libDaisy/core/STM32H750IB_qspi.lds")
elif defined(bootSram):
  switch("passC", "-DBOOT_APP")
  switch("passL", "-T" & nimpheaPath / "libDaisy/core/STM32H750IB_sram.lds")
# else: flash.lds is linked in the project's .nimble make task

# Optional debug mode (opt-in via -d:debug)
when defined(debug):
  switch("opt", "none")
  switch("passC", "-g")
  switch("passC", "-ggdb")
  switch("passC", "-DDEBUG")

# Optional: FatFs LFN support (opt-in via -d:useFatFsLFN)
when defined(useFatFsLFN):
  switch("passL", "-L" & nimpheaPath / "build -lfatfs_ccsbcs")

# Optional: CMSIS-DSP support (opt-in via -d:useCMSIS)
when defined(useCMSIS):
  switch("passL", "-L" & nimpheaPath / "build -lCMSISDSP")

# Project-specific overrides can be added below
# Example: switch("define", "myCustomDefine")

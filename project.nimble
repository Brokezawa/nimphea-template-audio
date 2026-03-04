# Package
version       = "0.1.0"
author        = "Your Name"
description   = "An audio Nimphea project"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]

# Dependencies
requires "nim >= 2.0.0"
requires "nimphea >= 1.1.0"

# Build configuration
# NOTE: This project uses config.nims for compiler configuration
# The config.nims file is automatically loaded by the Nim compiler

import os, strutils

const
  # Flexible flash configuration
  # Change dfuPid to match your bootloader:
  #   0x0483:0xDF11 - STM32 DFU bootloader (libDaisy default)
  dfuPid = "0x0483:0xDF11"
  
  # Internal flash addresses for different boot modes
  flashAddressInternal = 0x08000000  # BOOT_NONE (default)
  flashAddressQspi = 0x90040000      # BOOT_SRAM or BOOT_QSPI
  
  # Linker script for this project
  # QSPI programs should use "STM32H750IB_qspi.lds" for larger programs
  linkerScript = "STM32H750IB_flash.lds"

# Optional: Boot mode selection and library support
# Add defines here for your project:
# - Boot modes: -d:bootSram, -d:bootQspi (default: direct flash)
# - Libraries: -d:useFatFsLFN, -d:useCMSIS
when not declared(customDefines):
  const customDefines = ""

task make, "Build for ARM Cortex-M7":
  ## Build project for ARM Cortex-M7 Daisy hardware
  ## Configuration is loaded from config.nims
  
  let pkgPath = gorge("nimble path nimphea 2>/dev/null").strip()
  if pkgPath.len == 0:
    echo "Error: nimphea package not found."
    echo "Run 'nimble install nimphea' first."
    quit(1)
  
  # Setup build directories
  let nimcacheDir = "build/nimcache"
  mkDir("build")
  mkDir(nimcacheDir)
  
  # Determine boot mode from customDefines
  let bootMode =
    if customDefines.contains("bootQspi"):
      "BOOT_QSPI"
    elif customDefines.contains("bootSram"):
      "BOOT_SRAM"
    else:
      "BOOT_NONE"
  
  # Select flash address based on boot mode
  let flashAddress = if bootMode == "BOOT_NONE":
    flashAddressInternal
  else:
    flashAddressQspi
  
  # Compile Nim to object files (config.nims provides compiler flags)
  var nimCmd = "nim cpp --noLinking:on --nimcache:" & nimcacheDir & " "
  if customDefines.len > 0:
    # Add each define with -d: prefix
    for define in customDefines.split():
      nimCmd.add("-d:" & define & " ")
  nimCmd.add("src/main.nim")
  exec nimCmd
  
  # Collect object files
  var objs: seq[string] = @[]
  for kind, path in walkDir(nimcacheDir):
    if kind == pcFile and path.endsWith(".o"):
      objs.add(path)
  if objs.len == 0:
    echo "Error: no object files found after compile"
    quit(1)
  
  # Link with ARM cross-linker
  # Skip linker script for bootloaded modes (bootloader provides flash layout)
  var linkCmd = "arm-none-eabi-g++ -o build/main.elf " & join(objs, " ")
  linkCmd.add(" -mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard")
  linkCmd.add(" --specs=nano.specs --specs=nosys.specs")
  linkCmd.add(" -L" & pkgPath / "libDaisy/build -ldaisy")
  
  # Check if CMSIS or FatFs were defined and add appropriate libraries
  if customDefines.contains("useCMSIS"):
    linkCmd.add(" -L" & pkgPath / "build -lCMSISDSP")
  if customDefines.contains("useFatFsLFN"):
    linkCmd.add(" -L" & pkgPath / "build -lfatfs_ccsbcs")
  
  # Skip linker script if boot mode override is defined
  if bootMode == "BOOT_NONE":
    let lds = pkgPath / "libDaisy/core/" & linkerScript
    if fileExists(lds):
      linkCmd.add(" -T" & lds)
  
  linkCmd.add(" -Wl,-Map=build/main.map -Wl,--gc-sections -Wl,--print-memory-usage")
  linkCmd.add(" -Wl,--allow-multiple-definition")
  
  exec linkCmd
  
  # Generate binary and print size
  exec "arm-none-eabi-objcopy -O binary build/main.elf build/main.bin"
  exec "arm-none-eabi-size build/main.elf"
  
  echo "✓ Build complete: build/main.bin (boot mode: " & bootMode & ")"

task clear, "Remove build artifacts":
  ## Remove all build artifacts
  if dirExists("build"):
    rmDir("build")
    echo "✓ Removed build/"

task flash, "Flash via DFU":
  ## Flash via DFU bootloader (for bootloaded applications)
  let bootMode =
    if customDefines.contains("bootQspi"):
      "BOOT_QSPI"
    elif customDefines.contains("bootSram"):
      "BOOT_SRAM"
    else:
      "BOOT_NONE"
  
  let flashAddress = if bootMode == "BOOT_NONE":
    flashAddressInternal
  else:
    flashAddressQspi
  
  exec "dfu-util -a 0 -s " & flashAddress.toHex() & ":leave -D build/main.bin"

task stlink, "Flash via ST-Link":
  ## Flash via ST-Link (direct flash, requires BOOT_NONE mode)
  let bootMode =
    if customDefines.contains("bootQspi"):
      "BOOT_QSPI"
    elif customDefines.contains("bootSram"):
      "BOOT_SRAM"
    else:
      "BOOT_NONE"
  
  if bootMode != "BOOT_NONE":
    echo "Error: stlink task requires BOOT_NONE mode (direct flash)"
    echo "Bootloaded applications (" & bootMode & ") must use 'nimble flash' instead"
    quit(1)
  
  exec "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg -c \"program build/main.elf verify reset exit\""

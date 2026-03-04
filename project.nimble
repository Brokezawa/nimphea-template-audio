# Package
version       = "0.1.0"
author        = "Your Name"
description   = "An audio Nimphea project"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]

# Dependencies
requires "nim >= 2.0.0"
requires "nimphea >= 1.0.0"

# Build configuration (copied from nimphea for standalone use)
import os, strutils, strformat

task make, "Build for ARM Cortex-M7":
  let nimpheaPath = gorge("nimble path nimphea").strip()
  if nimpheaPath == "":
    echo "Error: nimphea package not found. Run 'nimble install nimphea' first."
    quit(1)
  
  # Standard build flags for Daisy Seed
  var nimCmd = "nim cpp"
  nimCmd.add(" --cpu:arm --os:standalone --mm:arc --opt:size --exceptions:goto")
  nimCmd.add(" --define:useMalloc --define:noSignalHandler")
  
  # Include nimphea src and libDaisy
  # nimble path returns the package root; in installed packages Nimble flattens
  # src/ to the root, so nimphea.nim lives at the root. In develop mode (nimble develop)
  # the repo structure is intact and nimphea.nim lives under src/.
  let nimpheaSrc =
    if fileExists(nimpheaPath / "src" / "nimphea.nim"): nimpheaPath / "src"
    else: nimpheaPath
  nimCmd.add(" --path:" & nimpheaSrc)
  
  # Link with libDaisy (assume built by nimble install)
  nimCmd.add(" --passL:-L" & nimpheaPath / "libDaisy/build")
  nimCmd.add(" --passL:-ldaisy")
  
  # ELF and BIN output
  let target = "main"
  nimCmd.add(" -o:build/" & target & ".elf")
  nimCmd.add(" src/" & target & ".nim")
  
  mkDir("build")
  exec nimCmd
  exec "arm-none-eabi-objcopy -O binary build/" & target & ".elf build/" & target & ".bin"
  exec "arm-none-eabi-size build/" & target & ".elf"

task flash, "Flash via DFU":
  exec "dfu-util -a 0 -s 0x08000000:leave -D build/main.bin"

task stlink, "Flash via ST-Link":
  exec "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg -c \"program build/main.elf verify reset exit\""

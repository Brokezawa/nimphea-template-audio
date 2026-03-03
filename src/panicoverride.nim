## Panic handler for embedded systems
## This overrides Nim's default panic handler for bare metal ARM targets

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  # In embedded systems without a console, we can't output anything
  # In a real implementation, you might want to:
  # - Blink an LED in a specific pattern
  # - Output to a serial debug port
  # - Store error info in a specific memory location
  discard

proc panic(s: string) {.exportc: "panic", noreturn.} =
  # halt the system
  while true:
    discard

{.pop.}

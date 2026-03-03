import nimphea

# Set up C++ interop macros
useNimpheaNamespace()

# Real-time audio callback
# RULES: 
# - No heap allocations (no seq, no string)
# - No blocking calls (no delay, no printing)
# - Keep it fast!
proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  for i in 0..<size:
    # Passthrough input to output (Stereo)
    output[0][i] = input[0][i]
    output[1][i] = input[1][i]

proc main() =
  # Initialize the Daisy Seed board
  var daisy = initDaisy()
  
  # Start audio processing with our callback
  daisy.startAudio(audioCallback)
  
  # Optional: Start serial log for debugging
  startLog()
  printLine("Audio Passthrough Template Started")

  while true:
    # The main loop runs at a lower priority than the audio callback
    # Use it for handling controls, display, etc.
    daisy.toggleLed()
    daisy.delay(1000)

when isMainModule:
  main()

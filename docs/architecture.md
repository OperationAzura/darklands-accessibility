# Architecture

The system is split into independently versioned repositories so emulator
changes remain reviewable and the Python applications can evolve separately.

```text
Darklands inside DOSBox Staging
            |
            | localhost HTTP API (127.0.0.1:8086)
            |
     +------+--------------------+
     |                           |
     v                           v
 DarkText                Darklands Coords
 frame -> OCR -> Piper    memory/save -> guidance
                         input API -> navigation
```

## DOSBox Staging accessibility fork

The `darklands-accessibility` branch adds three pieces to upstream DOSBox
Staging:

- a PPM endpoint containing the latest native emulated frame;
- synthetic keyboard and mouse endpoints that do not require host focus;
- live-frame plumbing in the renderer/capture path.

Darklands Coords also uses the web server's existing memory-read endpoint. The
web server remains disabled by default.

## DarkText

DarkText requests the latest frame, normalizes it to Darklands' 640x480 logical
layout, and OCRs the story pane. A fast visual detector tracks the highlighted
choice between full OCR passes. Multi-frame consensus repairs text temporarily
covered by the game's cursor. Piper output is cached by normalized content.

## Darklands Coords

Darklands Coords reads coordinates and quest records from the newest save. An
interactive calibration process finds candidate coordinate addresses in
emulated RAM and verifies the persisted address against later saves. Assisted
navigation holds a numeric-keypad direction through the DOSBox input endpoint,
stopping at the destination or when movement appears blocked.

## Umbrella repository

This repository owns only integration concerns: documentation, an environment
file, a launcher, and install/update automation. The three components are
ordinary Git clones, not copied sources or submodules.

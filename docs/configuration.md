# Configuration

The installer creates:

```text
~/.config/darklands-accessibility/darklands.env
```

It is a shell environment file loaded by the `darklands` launcher. The shipped
template is [`config/darklands.env.example`](../config/darklands.env.example).

## Important settings

| Variable | Purpose |
| --- | --- |
| `DARKLANDS_GAME_DIR` | Directory containing the installed game |
| `DARKLANDS_GAME_EXE` | Path to `darkland.exe` |
| `DARKTEXT_DATA_DIR` | Logs, debug captures, and generated speech cache |
| `DARKTEXT_PIPER_BIN` | Piper executable used by DarkText |
| `DARKTEXT_VOICE_DIR` | Directory containing Piper `.onnx` voices |
| `DARKLANDS_PIPER_BIN` | Optional Piper executable override for Darklands Coords |
| `DARKLANDS_VOICE_DIR` | Piper voices used by Darklands Coords |
| `DOSBOX_WEBSERVER_PORT` | Loopback API port, normally `8086` |

Environment variables supplied directly to a command take priority over the
template defaults because each setting uses shell default-value expansion.

## Runtime data

No runtime data belongs in Git. DarkText stores logs, debug images, and its
generated audio cache beneath `DARKTEXT_DATA_DIR`. Darklands Coords stores its
calibrated RAM address in `DARKLANDS_COORDS_CONFIG`.

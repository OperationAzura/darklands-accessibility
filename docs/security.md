# Security and save safety

## Keep the API on loopback

The modified DOSBox web API exposes emulator memory and synthetic input. The
launcher binds it to `127.0.0.1`. Do not change that to `0.0.0.0` or expose the
port to an untrusted network. DOSBox also validates HTTP host headers.

## Save editing

Teleport and add-money deliberately modify the newest matching save file. Both
tools create a timestamped backup beside the save before writing. Teleport also
verifies the backup and reads the written coordinates back. Keep ordinary game
backups as an additional precaution.

## Files not distributed

The repositories exclude Darklands executables and assets, save files, Piper
models, generated speech, logs, OCR debug captures, virtual environments,
build directories, and local configuration. Do not commit these later.

## Reporting issues

Avoid attaching proprietary game files or personal save files to public issue
reports. Reproduce with textual diagnostics or sanitized screenshots where
possible.

# Publishing audit

Audit completed 2026-09-09 before the initial public release.

## Scope and results

- Secret scanning covered every commit in DarkText, Darklands Coords, and this
  umbrella repository, plus both accessibility commits in the DOSBox fork. No
  secrets were found.
- A full working-tree scan of the DOSBox fork reported four false positives in
  vendored SIMDe preprocessor definitions; inspection confirmed they are
  floating-point API macros, not credentials.
- Personal absolute paths were removed from application code. Remaining home
  directory paths in upstream DOSBox examples are generic documentation from
  the upstream project.
- No Darklands binaries, assets, save files, Piper voices, generated speech,
  logs, OCR captures, virtual environments, caches, or build output are tracked.
- Upstream DOSBox program/resource archives remain because they are intentional,
  licensed content from the upstream repository rather than Darklands data.
- DarkText and Darklands Coords were checked against the excluded research
  references; no copied implementation was identified. Their dependencies are
  not vendored and use MIT-, BSD-, or Apache-compatible licenses.
- DOSBox Staging's GPL-2.0-or-later license, copyright history, source headers,
  and bundled third-party licenses remain intact.

## Validation

- DarkText: 15 tests passed; two opt-in hardware/audio tests skipped.
- Darklands Coords: three tests passed.
- Both Python projects built valid wheels with MIT license metadata.
- Launcher and install/update scripts passed `bash -n` and ShellCheck 0.11.0.
- DOSBox accessibility changes passed `git diff --check`; the active installed
  binary was built after and matched the audited local build artifact.

# Supplied input and reference data

Keep user-provided files and reference material here, separate from editable
application code and generated builds.

- `support/MOBILO TOOLZ/` is the supplied runtime support tree (DA/FDL payloads,
  DLLs, and USB support files). Its original layout is preserved when creating
  a portable package or setup installer. `assets-manifest.json` records the
  files' sizes and SHA-256 hashes; update it only when the supplied files
  intentionally change.
- `ui-reference/` contains the supplied UI sample screenshots used to match
  the app and to regenerate the small embedded toolbar artwork.
- Put future uploaded file structures or reference inputs under a descriptive
  subfolder in `data/`; do not place application source or build output here.

The app's editable source and build scripts live in `src/DeviceSetup/`. Local
installer, portable bundle, and staging outputs go in the top-level
`artifacts/` folder.

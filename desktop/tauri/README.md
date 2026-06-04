# HeiTang KB Forge Desktop

This is the v1.2.2 Tauri desktop utility scaffold.

It provides a local UI wrapper for the existing `heitang-kb-forge` CLI workflows:

- `build`
- `batch`
- `pipeline --config`

## Boundary

The desktop app only starts the local CLI installed on the machine. It does not call cloud services, write to a real vector database, deploy an Agent, or replace the Python CLI.

## Development

```powershell
cd .\desktop\tauri
npm install
npm run tauri:dev
```

## Build EXE

```powershell
cd .\desktop\tauri
npm install
npm run tauri:build
```

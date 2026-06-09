# AGENTS.md

## After cloning
```sh
git submodule update --init --recursive
```
Native libs do not exist in a fresh clone — build them before building .NET packages.

## Build order (must be this order)
1. **Native libraries** — run platform-specific script natively on target platform:
   ```sh
   native/make-macos.sh osx-arm64       # macOS
   native/make-linux.sh linux-x64       # Linux x64
   native/make-windows.bat win-x64      # Windows (needs VS 2022)
   ```
   Outputs to `native/out/{platform}/`. Alternative: `native/build-all.sh` (cmake, requires `tree-sitter-cli` npm package).

2. **Core .NET binding**:
   ```sh
   cd dotnet && ./make-tree-sitter-core.sh <build_number>
   ```

3. **Grammar bindings** (auto-discovers all `native/tree-sitter-*/` dirs):
   ```sh
   ./make-grammars.sh <build_number>
   ```

All `.nupkg` files go to `dotnet/out/`.

## Architecture
- `dotnet/TreeSitter/` — core library (SDK-style csproj, targets **`net10.0`**)
- `dotnet/.GrammarTemplate/` — template for grammar bindings; produces `TreeSitter{GrammarName}/` packages targeting **`net8.0`** (references core project)
- All bindings share the `TreeSitter` namespace
- DllImport uses bare library basenames (`"tree-sitter"`, `"tree-sitter-python"`), not full paths — OS loader resolves via runtimes pack or system path

## Solution file
`dotnet-tree-sitter.sln` only includes the core `TreeSitter` project. Grammar bindings are built standalone by `make-grammars.sh`.

## Submodules
Located in `native/`: tree-sitter core + 10 grammar repos (python, javascript, cpp, c-sharp, java, php, go, ruby, typescript, bsl). The bsl submodule uses SSH URL (`git@github.com:zabbius/tree-sitter-bsl.git`).

## Gotchas
- **No tests** — thin P/Invoke wrappers around tree-sitter C API
- `LangVersion` is `default` (not pinned)
- Grammar template placeholders: `{GrammarName}` (PascalCase), `{grammar_name}` (snake_case), `{grammar-name}` (kebab-case)
- Native libs have `CopyToOutputDirectory=Always` — must exist at runtime
- `download-tree-sitter-grammars.sh` is a deprecated alternative to submodules (downloads into `externals/`)
- CI: `.github/workflows/tree-sitter.yml` — five native jobs, then one dotnet job that downloads all artifacts and publishes prerelease nupkgs

## Adding a new grammar
1. Add submodule under `native/tree-sitter-{name}/`
2. Run `make-grammars.sh` — auto-discovers it via `.GrammarTemplate/`

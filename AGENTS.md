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
   Outputs to `native/out/{platform}/`. Alternative: `build-all.sh` (naive all-platforms build via `native/build-all.sh`).

2. **Core .NET binding**:
   ```sh
   dotnet/make-tree-sitter-core.sh <build_number>
   ```
   Package ID: `HolisticWare.Tools.TreeSitter`, version `0.0.1.<build_number>`.

3. **Grammar bindings** (auto-discovers all `native/tree-sitter-*/` dirs):
   ```sh
   dotnet/make-grammars.sh <build_number>
   ```
   Package IDs: `TreeSitter.NET.{GrammarName}` (e.g. `TreeSitter.NET.Python`), version `1.0.<build_number>`.

All `.nupkg` files go to `dotnet/out/`.

## Architecture
- `dotnet/TreeSitter/src/` — core library (9 P/Invoke wrappers: Binding, Language, Node, Parser, Query, Tree, TreeCursor, Types, NodeExtensions) targeting **`net10.0`**
- `dotnet/.GrammarTemplate/` — template for grammar bindings; produces `TreeSitter{GrammarName}/` packages targeting **`net8.0`** (references core project)
- All bindings share the `TreeSitter` namespace (`<RootNamespace>TreeSitter</RootNamespace>`)
- Native libs are packed into `runtimes/{rid}/native/` with `<CopyToOutputDirectory>Always</CopyToOutputDirectory>` — OS loader resolves via runtimes pack at runtime
- Grammar template placeholders: `{GrammarName}` (PascalCase), `{grammar_name}` (snake_case), `{grammar-name}` (kebab-case)

## Solution file
`dotnet/dotnet-tree-sitter.sln` only includes the core `TreeSitter` project. Grammar bindings are built standalone by `make-grammars.sh`.

## Submodules
Located in `native/`: tree-sitter core + 10 grammar repos (python, javascript, cpp, c-sharp, java, php, go, ruby, typescript, bsl). The bsl submodule uses SSH URL (`git@github.com:zabbius/tree-sitter-bsl.git`). PHP and TypeScript grammars have custom build scripts (`tree-sitter-{php,typescript}.make-*.sh`) because their default Makefiles don't produce the expected output.

## Gotchas
- **No tests** — thin P/Invoke wrappers around tree-sitter C API
- `LangVersion` is `default` (not pinned) in all csproj files
- `download-tree-sitter-grammars.sh` at repo root is a deprecated alternative to submodules (downloads into `externals/`)
- CI: `.github/workflows/tree-sitter.yml` — five native jobs (linux-x64, linux-arm64, macos-arm64, macos-intel, windows-x64), then one dotnet job that downloads all artifacts and publishes prerelease nupkgs via `actions/create-release@v1`
- Dotnet setup in CI uses `dotnet-version: '8.x'` despite core targeting net10.0

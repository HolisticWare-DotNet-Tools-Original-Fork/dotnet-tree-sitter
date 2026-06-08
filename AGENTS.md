# AGENTS.md

## Repo structure
- **Root**: `dotnet/` — C# bindings; `native/` — tree-sitter C library + grammar submodules
- **Core library**: `dotnet/TreeSitter/` — single-project SDK-style csproj targeting `net8.0`
- **Grammar bindings**: Built from `dotnet/.GrammarTemplate/` via `make-grammars.sh`; produce `TreeSitter{GrammarName}/` packages
- **Native libs**: Prebuilt `.so`/`.dylib`/`.dll` live in `native/out/{platform}/`; referenced by csproj via `runtimes/{rid}/native/` pack paths. These do not exist in a fresh clone — run the build scripts first

## Submodules
All native code comes from git submodules under `native/`:
- `tree-sitter` core (https://github.com/tree-sitter/tree-sitter.git)
- Grammars: python, javascript, cpp, c-sharp, java, php, go, ruby, typescript, bsl

After cloning: `git submodule update --init --recursive`

## Build commands

### Native libraries (make — default)
```sh
native/make-macos.sh osx-arm64    # build on macOS (outputs to native/out/osx-arm64/)
native/make-linux.sh linux-x64    # build on Linux x64
native/make-windows.bat win-x64   # build on Windows x64 (requires Visual Studio 2022)
native/update-submodules.sh       # update all grammar submodules
```

### Native libraries (cmake — alternative)
```sh
native/build-all.sh osx-arm64     # builds all grammars, outputs to native/out/osx-arm64/
```
Requires `tree-sitter` CLI (`npm install -g tree-sitter-cli`) for grammar parser generation.

CMake produces the correct output format per platform: `.dylib` on macOS, `.so` on Linux, `.dll` on Windows. Must be run natively on each target platform. Cross-compile toolchains in `native/cmake/` (requires installing cross-compilers manually).

CMakeLists.txt files ship with upstream submodules; local patches applied for this repo:
- `ts-test` targets wrapped in `if(ENABLE_TS_TEST)` to avoid name collisions across grammars
- PHP/TypeScript parent CMakeLists.txts use `${GRAMMAR_BINDINGS_C}` variable for pc.in paths
- `tree-sitter-bsl` skipped when submodule not initialized (requires SSH access)

### .NET packages
```sh
cd dotnet
./make-tree-sitter-core.sh <build_number>   # builds TreeSitter package
./make-grammars.sh <build_number>           # generates and builds all grammar packages into out/
```

Both scripts output `.nupkg` files to `dotnet/out/`. CI passes build number via `${{ github.run_number }}`.

## Adding a new grammar binding
1. Add the tree-sitter grammar submodule under `native/tree-sitter-{name}/`
2. Update `native/update-submodules.sh` if needed
3. Run `make-grammars.sh` — it auto-discovers `native/tree-sitter-*/` dirs and generates bindings from `.GrammarTemplate/`
4. Template placeholders: `{GrammarName}` (PascalCase), `{grammar_name}` (snake_case), `{grammar-name}` (kebab-case)

## CI
`.github/workflows/tree-sitter.yml` — five native build jobs (linux-x64, linux-arm64, macos-arm64, macos-intel, windows-x64) then a single dotnet build job that downloads all artifacts and publishes prerelease nupkgs.

## Important details
- **No tests** in this repo — the bindings are thin P/Invoke wrappers around tree-sitter C API
- `LangVersion` is `default` (not pinned); target framework is `net8.0`
- Native `.so`/`.dylib`/`.dll` files are set to `CopyToOutputDirectory=Always` — they must exist at runtime in the same directory or be unpacked from the nuget package
- DllImport names use bare library basenames (e.g. `"tree-sitter"`, `"tree-sitter-python"`), not full paths — the OS loader finds them via runtimes pack or system library path
- Grammar binding csprojs reference the core `TreeSitter` project; all bindings share the `TreeSitter` namespace

--os:standalone
--cpu:amd64
--cc:clang
# --gc:orc
--gc:none
--d:release
--nomain
--opt:size
--listCmd
--d:wasm
--stackTrace:off
--d:noSignalHandler
# --exceptions:goto
--app:lib
--checks:off

let llTarget = "bpf"

switch("passC", "-fPIC")
switch("passC", "-march=bpfel+solana")
switch("passC", "-target " & llTarget)
switch("passC", "-O2")
# switch("passL", "-target=" & llTarget)

# switch("passC", "-I/usr/include") # Wouldn't compile without this :(

# switch("passC", "-flto") # Important for code size!

# gc-sections seems to not have any effect
# var linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined,--export-dynamic,--gc-sections,--strip-all"
# var linkerOptions = "-z notext --Bdynamic /opt/solana-release/bin/sdk/bpf/c/bpf.ld --entry entrypoint /opt/solana-release/bin/sdk/bpf/c/../dependencies/bpf-tools/rust/lib/rustlib/bpfel-unknown-unknown/lib/libcompiler_builtins-c71fcddec0528fab.rlib"
var linkerOptions = "-z notext --Bdynamic /opt/solana-release/bin/sdk/bpf/c/bpf.ld --entry entrypoint"
linkerOptions &= " /opt/solana-release/bin/sdk/bpf/c/../dependencies/bpf-tools/rust/lib/rustlib/bpfel-unknown-unknown/lib/libcompiler_builtins-c71fcddec0528fab.rlib"
linkerOptions &= " --strip-all --gc-sections"

switch("clang.exe", "/opt/solana-release/bin/sdk/bpf/c/../dependencies/bpf-tools/llvm/bin/clang")
switch("clang.linkerexe", "/opt/solana-release/bin/sdk/bpf/c/../dependencies/bpf-tools/llvm/bin/ld.lld")
switch("clang.options.linker", linkerOptions)
# switch("clang.cpp.options.linker", linkerOptions)

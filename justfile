default:
    just --list

prepare:
    zigup 0.14.0-dev.1646+b19d0fb0

debug: 
    zig build

run:
    zig build -Doptimize=Debug run

release:
    zig build -Doptimize=ReleaseSafe run

package: 
    zig build -Doptimize=ReleaseSafe

test: 
    zig build test

clean:
    rm -r ./.zig-cache ./zig-out

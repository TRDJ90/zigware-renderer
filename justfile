default:
    just --list

prepare:
    zigup 0.14.0-dev.1646+b19d0fb0

build: 
    zig build

debug:
    zig build -Doptimize=Debug run

run:
    zig build -Doptimize=ReleaseFast run

test: 
    zig build test

clean:
    rm -r ./.zig-cache ./zig-out

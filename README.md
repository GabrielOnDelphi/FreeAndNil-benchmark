# Delphi FreeAndNil benchmark

Is `if Assigned(X) then FreeAndNil(X)` faster than a plain `FreeAndNil(X)`?

## Why I made it

In my book [*Delphi in all its glory - Reaching for the gods*](https://www.amazon.com/Delphi-all-its-glory-Reaching/dp/B0CTQPNB56) (Part 2 of the series) I recommend FreeAndNil over Free, and I say that its cost is negligible. A claim in a book needs a proof, so I measured it, together with the old question: does the "if" in front of FreeAndNil buy any speed? The numbers below are the ones printed in the book.

The full story is on my website: [if Assigned(X) then FreeAndNil(X): is the check faster? I measured it](https://gabrielmoraru.com/freeandnil-if-assigned-benchmark/).

## What it measures

Four ways to free an object:

- `FreeAndNil(X)` - the RTL's own
- `if Assigned(X) then FreeAndNil(X)`
- `FreeAndNilBetter(X)` - a FreeAndNil that tests nil itself and then calls Destroy directly
- `X.Free` - leaves X dangling, so it is only a speed reference

Each way runs over 4096 slots that are all nil, all objects (plain TObject, the cheapest destructor there is), or a 50% random mix. Only the freeing loop is timed: 4096000 calls per run, one warm-up run, then the fastest of 5 runs. Before any timing, a self-check proves that every way frees every object exactly once.

## Results

Delphi 13, Release build, AMD Ryzen 5 7600X. Nanoseconds per call, lower is better:

```
Win32                         X is nil   X is an object
X.Free                            0.92             9.67
FreeAndNil(X)                     0.92            10.01
if Assigned + FreeAndNil          0.37            10.23
Better FreeAndNil                 0.37             9.30

Win64                         X is nil   X is an object
X.Free                            1.11            10.34
FreeAndNil(X)                     1.11            10.28
if Assigned + FreeAndNil          0.37            10.09
Better FreeAndNil                 0.55             9.57
```

In short: FreeAndNil costs the same as Free. When X is nil, the "if" saves about 0.6-0.7 ns per call. When X holds an object, the "if" makes no difference you can rely on. The numbers move by a few tenths of a nanosecond between runs and between builds, so run it on your own machine.

![The VCL front end of the benchmark](screenshot.png)

## How to run it

- `FreeAndNilBenchConsole.dpr` - console program, RTL units only, compiles in a stock Delphi. It prints the report and saves it as `Results - Win32.txt` or `Results - Win64.txt` beside the exe.
- `FreeAndNilBench.Core.pas` - the measuring unit. Call `RunFreeAndNilBenchmark` from your own program.
- `FreeAndNilBench.dpr` - my VCL front end (a button and a memo, see `screenshot.png`). It uses my [LightSaber](https://github.com/GabrielOnDelphi/Delphi-LightSaber) library and the bridge unit of [Autopilot for Delphi](https://gabrielmoraru.com/my-delphi-code/autopilot-for-delphi/) (the `Bridge` folder of [its GitHub repository](https://github.com/GabrielOnDelphi/Autopilot-for-Delphi)), which lets an AI assistant drive the running app. Fix the library paths in the `.dpr`, or use the console program.

Build in Release mode: a debug memory manager changes the cost of freeing.

## More

- My website: [gabrielmoraru.com](https://gabrielmoraru.com)
- My books, the five-part series *Delphi in all its glory*: [gabrielmoraru.com/publications-citations](https://gabrielmoraru.com/publications-citations/)

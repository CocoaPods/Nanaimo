# Benchmarks

`bench.rb` measures Nanaimo's parse, conversion and serialization throughput
over the `project.pbxproj` fixtures in `spec/fixtures`.

## Running

```sh
ruby bench/bench.rb            # interpreter
ruby --yjit bench/bench.rb     # YJIT
ruby --zjit bench/bench.rb     # ZJIT, if your Ruby is built with it
```

Each workload is warmed up (so JIT-compiled code is what gets timed), then run
in batches for the given number of seconds (default 3). The reported number is
the median batch rate in iterations per second, where one iteration processes
every fixture once. Higher is better.

| Workload             | What it times                                              |
| -------------------- | ---------------------------------------------------------- |
| `parse`              | `Nanaimo::Reader#parse!`                                   |
| `as_ruby`            | `Nanaimo::Plist#as_ruby` on parsed plists                  |
| `write_ascii`        | `Nanaimo::Writer` on parsed plists                         |
| `write_pbxproj`      | `Nanaimo::Writer::PBXProjWriter` on parsed plists          |
| `write_pbxproj_ruby` | `Nanaimo::Writer::PBXProjWriter` on plain Ruby hashes      |
| `write_xml`          | `Nanaimo::Writer::XMLWriter` on plain Ruby hashes          |
| `roundtrip`          | parse followed by `PBXProjWriter`, as Xcodeproj does       |

## Options

- First argument: seconds to time each workload, e.g. `ruby bench/bench.rb 1.5`.
- `ONLY=parse,write_xml`: run only the listed workloads.
- `NANAIMO_LIB=/path/to/lib`: benchmark a different copy of the library, using
  the same harness and fixtures.

## Comparing against another revision

```sh
git worktree add /tmp/nanaimo-base master
for jit in "" --yjit --zjit; do
  NANAIMO_LIB=/tmp/nanaimo-base/lib ruby $jit bench/bench.rb
  ruby $jit bench/bench.rb
done
```

Timings use process CPU time rather than wall-clock time, which makes them less
sensitive to other load on the machine, but they are still noisy. Alternate
between the two revisions, repeat each run a few times, and compare the best
results rather than trusting a single run.

Add a `--shout` option to `greet.sh` that prints the greeting in upper case.

- `sh greet.sh --shout Ada` prints `HELLO, ADA!` and exits 0.
- `sh greet.sh --shout` prints `HELLO, WORLD!` and exits 0. An empty name after `--shout` is the same as no name.
- The option counts only as the first argument, followed by at most one name. `sh greet.sh --shout Ada Bob` and `sh greet.sh Ada --shout` both print `greet: too many arguments` on stderr and exit 2.
- A name never starts with `-`: after `--shout`, such an argument is an unknown option, so `sh greet.sh --shout -x` prints `greet: unknown option: -x` on stderr and exits 2.
- Only the letters a to z become A to Z. Every other character stays as it is: `sh greet.sh --shout ada-lovelace_42` prints `HELLO, ADA-LOVELACE_42!`.
- Without the option, nothing changes, and other arguments starting with `-` are still unknown options.
- Add tests of each behavior to `test.sh`, and describe the option in `doc/product/spec/greeting.md`.

Nothing else changes. There are no open questions: this request is complete, and each choice above is final.

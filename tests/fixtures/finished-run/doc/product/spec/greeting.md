---
type: spec
---

# Greeting

## Usage

```sh
sh greet.sh [--shout] [name]
```

`--shout` prints the greeting in upper case. It counts as the option in the first argument only, with at most one name after it.

## The name and its default

- With a name, it prints `Hello, <name>!`, such as `Hello, Ada!` for `sh greet.sh Ada`.
- With no name, or an empty one, it prints `Hello, world!`.
- With `--shout`, it prints the same greeting in upper case: `HELLO, ADA!` for `sh greet.sh --shout Ada`, and `HELLO, WORLD!` for `sh greet.sh --shout`.

## Errors

Errors go to stderr, and nothing goes to stdout.

- A first argument that starts with `-`, other than `--shout`, prints `greet: unknown option: <arg>`. After `--shout`, an argument that starts with `-` is an unknown option too: `sh greet.sh --shout -x` prints `greet: unknown option: -x`.
- More than one argument after the option, or without it, prints `greet: too many arguments`. So `sh greet.sh --shout Ada Bob` and `sh greet.sh Ada --shout` both print it.

An unknown option is reported before too many arguments: `sh greet.sh -x Ada` prints `greet: unknown option: -x`.

## Exit statuses

- `0`: the greeting was printed.
- `2`: an error, with its message on stderr.

## Limitations

- `--shout` is the only option, so every other argument that starts with `-` is an unknown option, and a name can't start with `-`.
- `--shout` counts in the first argument only, with at most one name after it.
- With `--shout`, only a to z become A to Z. Every other character stays as it is: `sh greet.sh --shout ada-lovelace_42` prints `HELLO, ADA-LOVELACE_42!`.
- It greets one name at a time.

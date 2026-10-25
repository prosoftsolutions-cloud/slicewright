---
type: spec
---

# Greeting

## Usage

```sh
sh greet.sh [name]
```

## The name and its default

- With a name, it prints `Hello, <name>!`, such as `Hello, Ada!` for `sh greet.sh Ada`.
- With no name, or an empty one, it prints `Hello, world!`.

## Errors

Errors go to stderr, and nothing goes to stdout.

- A first argument that starts with `-` prints `greet: unknown option: <arg>`.
- More than one argument prints `greet: too many arguments`.

An unknown option is reported before too many arguments: `sh greet.sh -x Ada` prints `greet: unknown option: -x`.

## Exit statuses

- `0`: the greeting was printed.
- `2`: an error, with its message on stderr.

## Limitations

- There are no options, so every argument that starts with `-` is an unknown option, and a name can't start with `-`.
- It greets one name at a time.

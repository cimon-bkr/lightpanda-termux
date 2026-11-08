# lightpanda-termux

Runs [Lightpanda](https://github.com/lightpanda-io/browser) (a headless browser for scripts and AI
agents) on an Android phone, through [Termux](https://termux.dev).

Lightpanda has no screen or tabs. It loads a page, runs its JavaScript and either prints the result
or speaks the Chrome DevTools Protocol so Puppeteer, Playwright or an AI agent can drive it. It has
no Android build, and its official Linux build is made for glibc, which Android lacks. This
installer runs that official binary through Termux's `glibc-runner`.

> **Status: preview.** The installer passes `shellcheck` and was tested against a mock Termux
> (good download, corrupted download, wrong CPU). It has **not** been run on a real phone yet.

## Install

In Termux (the F-Droid or GitHub build), on a 64-bit ARM phone:

```sh
curl -fLO https://github.com/cimon-bkr/lightpanda-termux/releases/download/v0.1.0/install-lightpanda-termux.sh
bash install-lightpanda-termux.sh
```

It installs `glibc-repo` and `glibc-runner`, downloads Lightpanda 1.0.3, refuses the file if its
SHA-256 is not the expected one, and creates two commands. The binary needs glibc 2.38 or newer; if
it does not start, run `pkg update && pkg upgrade` and install again.

## Use

```sh
lightpanda fetch --dump https://example.com   # print a page after its JavaScript has run
lightpanda-serve                              # CDP server on ws://127.0.0.1:9222
lightpanda mcp                                # MCP server for AI agents
```

`lightpanda-serve` also keeps the phone awake while it runs.

## Telemetry

Lightpanda sends usage telemetry unless `LIGHTPANDA_DISABLE_TELEMETRY` is set. The `lightpanda`
command sets it. To leave telemetry on: `LIGHTPANDA_KEEP_TELEMETRY=1 lightpanda ...`

## Other versions

`LIGHTPANDA_VERSION=1.0.2 bash install-lightpanda-termux.sh` installs another release. Only 1.0.3
has a pinned checksum; for other versions the script prints the SHA-256 it got.

## Remove

```sh
rm "$PREFIX/bin/lightpanda" "$PREFIX/bin/lightpanda-serve"; rm -rf ~/.lightpanda
```

## Licenses

The installer script is MIT (see `LICENSE`). It downloads Lightpanda, which is
[AGPL-3.0](https://github.com/lightpanda-io/browser/blob/main/LICENSE); nothing of Lightpanda is
copied into this repository.

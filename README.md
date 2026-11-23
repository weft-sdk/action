<div align="center">

<img src="https://raw.githubusercontent.com/weft-sdk/.github/main/profile/logo.svg" alt="Weft" width="72" height="72">

# Weft Action

**Catch breaking contract changes, stale generated code and unformatted contracts in a pull request.**

[![Test](https://img.shields.io/github/actions/workflow/status/weft-sdk/action/test.yml?branch=main&label=test&labelColor=111111&color=7d92ff)](https://github.com/weft-sdk/action/actions)
[![License](https://img.shields.io/github/license/weft-sdk/action?labelColor=111111&color=7d92ff)](LICENSE)

[**Weft**](https://github.com/weft-sdk/weft) &nbsp;·&nbsp;
[**weft check**](https://github.com/weft-sdk/weft/blob/main/docs/06-cli.md#weft-check) &nbsp;·&nbsp;
[**Contract evolution**](https://github.com/weft-sdk/weft/blob/main/docs/02-contract-language.md#evolving-contracts-safely)

</div>

<br>

## Use it

```yaml
name: contracts
on: pull_request

jobs:
  weft:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # weft check compares with your latest release tag
      - uses: weft-sdk/action@main
```

On every pull request it runs three checks and writes the result to the job summary:

| Check | Command | Fails when |
| --- | --- | --- |
| **Breaking changes** | `weft check` | A change breaks a sender or a receiver, and the package version does not say so |
| **Generated code** | `weft gen --check` | `weft.gen.*` does not match the contracts |
| **Formatting** | `weft fmt --check` | A `.weft` file is not in the canonical style |

Each breaking change is also written as an error annotation on the run, with the place in the contract and what to do about it.

## Inputs

| Input | Default | What it does |
| --- | --- | --- |
| `version` | `latest` | The `weft` version to install, like `v0.1.0` |
| `working-directory` | `.` | The folder that holds `weft.yaml` |
| `check` | `true` | Run `weft check` |
| `baseline` | the latest tag | Compare with this git ref: a tag, a branch or a commit |
| `gen-check` | `true` | Run `weft gen --check` |
| `fmt-check` | `true` | Run `weft fmt --check` |

## Outputs

| Output | What it is |
| --- | --- |
| `passes` | `true` when every check that ran passed |

## Examples

**Compare with the main branch** instead of the latest tag:

```yaml
- uses: weft-sdk/action@main
  with:
    baseline: origin/main
```

**Only check that the generated code is current**, in a repository with contracts in a subfolder:

```yaml
- uses: weft-sdk/action@main
  with:
    working-directory: services/orders
    check: "false"
    fmt-check: "false"
```

**Pin the version:**

```yaml
- uses: weft-sdk/action@main
  with:
    version: v0.1.0
```

## How it installs weft

The action downloads the prebuilt `weft` binary for the runner (Linux, macOS or Windows, on x86-64 or arm64) from the [releases](https://github.com/weft-sdk/weft/releases) of the Weft repository, and puts it on the `PATH`. When a release does not exist, it builds `weft` from source with `cargo`, which takes a few minutes.

When the repository has no release tag yet, `weft check` is skipped with a notice and the other two checks still run.

## License

[Apache License 2.0](LICENSE).

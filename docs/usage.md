# Usage and options

## Actions

The `Runzivo:` actions in Herdr's command palette run `bin/rzv-herdr` in a
pane. You can bind one to a key in your Herdr config:

```toml
[[keys.command]]
key = "prefix+R"
type = "plugin_action"
command = "runzivo.sandboxes.status"
description = "Runzivo status"
```

Action ids: `create`, `attach`, `status`, `list`, `sleep`, `wake`, `delete`,
each prefixed with `runzivo.sandboxes.`.

## Create

Create asks for a name, a size (`2vcpu-8gb`, `4vcpu-16gb`, `8vcpu-32gb`,
`16vcpu-64gb`) and a lifetime (`8h`, `12h` or `24h`; `rzv sandboxes list`
shows what your environment offers). The sandbox is named `herdr-<name>`.
Then it:

1. runs `rzv sandboxes create` and waits until the sandbox runs,
2. runs `rzv sandboxes ssh-config <id> --write`, which adds the `<id>.rzv`
   SSH alias,
3. runs `herdr machine add <id>.rzv --label herdr-<name>`. Herdr asks before
   it installs itself in the sandbox.

The machine then shows in Herdr's sidebar. You can also run
`herdr --remote <id>.rzv`. `claude` and `codex` are preinstalled in the
sandbox; sign in to them there with your own account.

## Choosing a sandbox

The other actions use your only `herdr-*` sandbox, or ask which one when you
have several.

## From a shell

The same script works outside Herdr:

```sh
dir=$(herdr plugin list --json | grep -o '"plugin_root":"[^"]*rzv-herdr-plugin[^"]*"' | cut -d'"' -f4)
"$dir/bin/rzv-herdr" status herdr-myname
```

`rzv-herdr delete <name> --yes` deletes without asking.

## Settings

- `RZV_BIN`: the `rzv` to use. Otherwise `rzv` on `PATH`, then `~/.local/bin/rzv`.
- `RZV_PROFILE`: the `rzv` profile, as for `rzv` itself.
- `RZV_HERDR_WORKSPACE`: a Runzivo workspace id, passed as `--workspace`.

Herdr starts the plugin with the environment of the Herdr server, so set these
before you start Herdr.

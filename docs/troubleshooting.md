# Errors and fixes

| Message | Fix |
| --- | --- |
| The Runzivo CLI (rzv) is not installed | `curl -fsSL https://runzivo.dev/downloads/rzv/install.sh \| sh` |
| rzv ... is too old | Run the same install command to update |
| You are not signed in to Runzivo | `rzv login`, then retry |
| Your workspace is out of credit | Add credit with `rzv billing` or in the portal |
| No free sandbox capacity right now | Wait a few minutes, then retry |
| Already running its maximum number of sandboxes | Sleep or delete one, then retry |
| Reached the end of its lifetime | Delete it and create a new one |
| SSH ... does not answer yet | Wait a minute, then run the attach action |
| Herdr could not add the machine | Read Herdr's message above it, then run attach |

Other `rzv` errors are shown as `rzv` prints them.

## Herdr cannot connect

- Check plain SSH first: `ssh <id>.rzv true`.
- Refresh the alias: `rzv sandboxes ssh-config <id> --write`.
- `herdr machine status herdr-<name>` shows what Herdr sees.
- Windows is not supported: sandbox SSH needs macOS or Linux.

## Plugin logs

```sh
herdr plugin log list --plugin runzivo.sandboxes
```

## A machine without a sandbox

If you deleted the sandbox some other way, remove the machine:
`herdr machine list`, then `herdr machine remove <id>`.

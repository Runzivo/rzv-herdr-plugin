# Testing and releasing

## Checks

CI runs shellcheck on `bin/` and `scripts/`, and checks that the manifest
version matches `bin/rzv-herdr`.

## Live test

`scripts/20-shared-e2e.sh` installs the plugin from GitHub into a pinned,
checksummed Herdr 0.9.5 with its own config, then drives the actions:
create, a pane in the sandbox, status, sleep, wake, a pane after wake, a
refused delete and a confirmed delete. It runs only against Runzivo's shared
test environment and deletes its sandbox on exit.

```sh
RZV_PROFILE=<shared profile> E2E_WORK=<short empty dir> E2E_LOCK=<lock dir> \
  E2E_REF=<branch or tag> \
  scripts/20-shared-e2e.sh
```

## Release

1. Set `version` in `herdr-plugin.toml` and `bin/rzv-herdr`, update
   `CHANGELOG.md`, and merge.
2. Run the live test against `main`.
3. Tag `vX.Y.Z` on `main` and create a GitHub release from it.
4. The [Herdr marketplace](https://herdr.dev/plugins) indexes the default
   branch of repositories with the `herdr-plugin` topic every 30 minutes.

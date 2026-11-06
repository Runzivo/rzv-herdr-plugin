# Security

- The plugin runs only `rzv`, `ssh` and `herdr` on your computer, as you.
- It never reads, stores or prints your Runzivo tokens. `rzv` keeps its own
  sign-in, and SSH uses short-lived certificates that `rzv` issues.
- It holds no AI provider keys. Sign in to agents inside the sandbox with your
  own account.
- It reads none of your code and sends no usage data. The `herdr-` name prefix
  is the only marker of sandboxes it creates.
- It changes only `rzv`'s SSH config (through `rzv sandboxes ssh-config
  --write`, and on delete it removes the file `rzv` wrote for that sandbox),
  Herdr's machine list (through `herdr machine add` and `remove`) and a
  short-lived error file in the plugin's Herdr state directory.
- Herdr installs plugins from GitHub without a review. Read
  `herdr-plugin.toml` and `bin/` before you install, and pin a tag with
  `--ref`.

Report a security problem to security@runzivo.dev.

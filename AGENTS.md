# rzv-herdr-plugin agent guide

Runzivo-wide rules: [rzv-business/operating-policy.md](https://github.com/Runzivo/rzv-business/blob/main/operating-policy.md).
This file adds only plugin guidance.

- The plugin calls only `rzv`, `ssh` and `herdr`. No Runzivo API calls of its
  own, no stored tokens, no AI provider keys, nothing that reads user code.
- Bash 3.2 compatible (macOS), shellcheck clean.
- Run `scripts/20-shared-e2e.sh` before a release; see docs/testing.md.
- The repository is public: no internal hostnames, inventory, secrets or
  unreleased plans.

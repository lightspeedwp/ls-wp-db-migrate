# Claude Code plugin packaging

The maintained manifest is [plugin.json](plugin.json). It loads the repository's
root parent skill; Claude also discovers the focused sub-skills in root `skills/`.
Shared resources remain inside the same plugin checkout.

Validate from the repository root with `claude plugin validate .`.
See [installation](../docs/INSTALLATION.md) for personal-skill and plugin invocation.
`plugin/manifest.json` is legacy metadata, not Claude Code configuration.

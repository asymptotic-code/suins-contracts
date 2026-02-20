# Agents

We only care about the auction contract in `packages/auction/`.

## Sui Prover

Install the Sui Prover skill for Claude Code to get AI-assisted specification writing, verification debugging, and prover guidance.

Add the plugin source:

```
/plugin marketplace add asymptotic-code/sui-prover
```

Install the plugin:

```
/plugin install sui-prover@sui-prover
```

Once installed, Claude Code can help you write specifications, run the prover, and debug verification failures using the `/sui-prover` command.

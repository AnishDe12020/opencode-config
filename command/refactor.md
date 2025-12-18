---
description: refactor code while preserving behavior
---

refactor the following code:

$ARGUMENTS

## approach

1. understand current behavior first (read tests if they exist)
2. identify code smells:
   - duplication
   - long functions
   - deep nesting
   - unclear names
   - god objects
3. apply incremental changes, verify behavior preserved after each
4. use LSP tools for safe renames and reference finding
5. if large refactor, use swarm for parallel execution

## constraints

- do NOT change behavior unless explicitly asked
- do NOT delete tests to make refactor "pass"
- preserve public API unless asked to change

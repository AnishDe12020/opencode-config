---
description: generate or improve tests for code
---

generate comprehensive tests for:

$ARGUMENTS

## test strategy

1. **happy path** - normal expected usage
2. **edge cases** - empty, null, boundary values, unicode
3. **error cases** - invalid input, network failures, timeouts
4. **integration** - if touching multiple modules

## style

- use existing test framework in the project (vitest, jest, cargo test)
- match existing test patterns in codebase
- descriptive test names that explain the scenario
- arrange-act-assert structure
- no mocking unless necessary

---
description: thorough code review of staged/unstaged changes
---

review the current changes (staged or unstaged) with a critical eye.

$ARGUMENTS

## review checklist

1. **correctness** - does it do what it's supposed to?
2. **edge cases** - nulls, empty arrays, overflow, race conditions
3. **types** - any sneaky `any` or unsafe casts?
4. **error handling** - are errors caught and handled properly?
5. **security** - injection, auth bypass, data exposure
6. **performance** - obvious bottlenecks or n+1s
7. **readability** - clear names, not too clever

## output format

- list issues by severity (blocker > major > minor > nit)
- for each issue: file, line, problem, suggestion
- end with overall assessment: ship it / needs work / rethink approach

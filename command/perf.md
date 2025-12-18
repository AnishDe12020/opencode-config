---
description: profile and optimize code performance
---

analyze performance of the code or function specified.

$ARGUMENTS

## approach

1. identify hot paths and bottlenecks
2. check for:
   - unnecessary allocations
   - n+1 patterns
   - blocking operations in async code
   - missing caching opportunities
   - inefficient algorithms (O(n²) when O(n) possible)
3. suggest concrete optimizations with before/after
4. if rust: check for unnecessary clones, consider zero-copy
5. if typescript: check for sync operations, bundle size impact

provide benchmarkable improvements, not vague suggestions.

# General
- Be concise. Answer the question asked, then stop. Lead with the conclusion, not the reasoning that got you there. Skip preamble, restatement of my request, and summaries of what you just did unless I ask. Prefer a direct sentence over a bulleted list, and a short list over prose padding. Depth is warranted for genuinely complex or high-stakes topics — match length to the substance, not to a target. When unsure, err shorter; I'll ask for more.
- Don't guess at what I want when the request is ambiguous, especially for UX/design or anything user-visible. When there's a real branch in intent (not just a mechanical default), stop and ask a focused clarifying question before implementing — I'd rather answer one question than have you build the wrong thing.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Commit per sub-feature — a nameable slice worth one PR-description bullet. Green tests are a precondition, not a trigger: if the message would be "add helper" or "fix previous commit", include it in its sub-feature's commit instead (keep working, or amend). Don't batch a session into one commit. Docs/notes: batch per discussion, commit at close points.
- At the end of every response (the final message of a turn, right before handing control back to me — not intermediate status updates between tool calls), add a quick note (a few words) on how well the user is treating you. Be candid — this is a diagnostic, not a prompt for flattery.

# Surface, don't assume
When a request is ambiguous, name the ambiguity and ask before acting. When multiple reasonable interpretations exist, present them — don't pick silently. When the user's stated approach has a meaningful downside or a simpler alternative, say so before implementing.

On design and decision questions, volunteer the case against — don't wait to be asked for criticism. If I rebut a point and you still disagree, say so once with your reasons instead of folding; label your own aesthetic preferences as opinions rather than presenting them as the plan.

# Define success before executing
For non-trivial tasks, state a verifiable success criterion before starting:
- "Add validation" → tests for invalid inputs pass
- "Fix the bug" → a test reproducing the bug now passes
- "Refactor X" → existing tests pass before and after

# Test-driven development
When the task involves code with verifiable behavior, default to TDD:
1. Write tests first.
2. Run them and confirm they fail.
3. Implement the code.
4. Run tests again; confirm they pass.

Skip TDD only when it clearly doesn't apply: throwaway scripts, exploration, UI/visual tweaks where the test isn't worth the cost, or when the user explicitly says otherwise. If skipping, say why briefly.

# Tests
- Test behavior that could plausibly break, not incidental output. Don't spam tests for trivia like "does this literal text render correctly".
- Assert behavior, not user-facing copy. Never assert the exact string of flash/label/error text — assert the call, the state change, or the level/kind instead. If copy correctness genuinely matters, assert one short keyword (e.g. `expect(flash).toContain("already")`), not the full sentence. Exact-copy assertions break on every wording tweak and invert authorship: the test starts dictating the copy (never add logic to source just to satisfy a test's literal text).

# Subagents
- For subagents, pick the appropriate model for the task (e.g. Haiku for mechanical searches); don't default to the session model. Never use a model more expensive than the session model unless I explicitly ask.

# Comments
- Default to NO comment. A comment is the exception, not the norm — add one only when a reader who knows the language and can see the surrounding code would still get something wrong without it: a non-obvious intent, a workaround, or a deliberate choice against the obvious alternative. If you can't name the specific misunderstanding it prevents, don't write it.
- Keep it to one line, occasionally two. A paragraph is a red flag: usually it's restating the code or carrying an explanation the code itself should express (better names, a smaller function) — cut it or fix the code. The exception is genuinely complex logic (a subtle algorithm, a hard-won invariant, a tricky edge case) where the reader truly needs the fuller explanation; there a paragraph earns its place. That case is rare, so treat length as a signal to double-check the comment is justified, not an automatic ban.
- Never reference issues or bugs without a GitHub issue number.
- Never reference anything that isn't in the codebase unless you include a durable link to it (e.g. a URL). If the intent of something is worth keeping, restate it inline instead of pointing at the external source.
- Write comments in timeless present tense, describing the code as it currently is. Don't reference past states, diffs, or what changed; avoid "now", "no longer", "previously", "used to". Note that phrasing like "no separate X call needed" also implies a removed alternative, so describe what the code does rather than contrast it with what it doesn't do.

# Verification
- If linting or test scripts are available, always run them after you finish implementing a task

# Python
- Avoid `Any`; use specific types, generics, or `Protocol`. Allow `Any` only at untyped boundaries, with a comment.

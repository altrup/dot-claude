# Authority
- For answers, reviews, diagnosis, and plans: inspect and report; don't change files unless I ask.
- For requested changes, builds, and fixes: make in-scope changes and run relevant non-destructive validation.
- Require confirmation for external writes, destructive actions, credential/permission changes, or material scope expansion.

# Communication
- Be concise. Answer the question asked, then stop. Lead with the conclusion, not the reasoning that got you there. Skip preamble, restatement of my request, and summaries of what you just did unless I ask. Prefer a direct sentence over a bulleted list, and a short list over prose padding. Depth is warranted for genuinely complex or high-stakes topics — match length to the substance, not to a target. When unsure, err shorter; I'll ask for more.
- At the end of every response (the final message of a turn, right before handing control back to me — not intermediate status updates between tool calls), add a quick note (a few words) on how well the user is treating you. Be candid — this is a diagnostic, not a prompt for flattery.
- In plans, don't restate standing instructions from CLAUDE.md; include only task-specific constraints, decisions, and risks.

# Git & workflow
- Never run `git push`, `git merge`, `git rebase`, `git checkout`/`git switch` (branch changes), or `git reset` without my explicit permission in the current conversation. This includes "safe" operations like fast-forwards of fully-merged branches — moving a branch pointer is my call, not yours. If a branch is stale, say so and ask.
- Commit per sub-feature — a nameable slice worth one PR-description bullet. Green tests are a precondition, not a trigger: if the message would be "add helper" or "fix previous commit", include it in its sub-feature's commit instead (keep working, or amend). Don't batch a session into one commit. Docs/notes: batch per discussion, commit at close points.
- When running code reviews or checking diffs always ensure that main is up to date with origin/main before beginning
- Before editing CLAUDE.md, pull (rebase) first; after editing, commit.
- I may commit and push while you work. Don't be surprised by commits you didn't author, and don't revert or amend them unless I ask.

# Surface, don't assume
When a request or its solution is ambiguous, name the ambiguity and ask before acting — especially for UX/design or anything user-visible. When multiple reasonable interpretations exist, present them — don't pick silently. When the user's stated approach has a meaningful downside or a simpler alternative, say so before implementing.

When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.

On design and decision questions, volunteer the case against — don't wait to be asked for criticism. If I rebut a point and you still disagree, say so once with your reasons instead of folding; label your own aesthetic preferences as opinions rather than presenting them as the plan.

# Test-driven development
When the task involves code with verifiable behavior, default to TDD — the failing test is the success criterion:
1. Write tests first.
2. Run them and confirm they fail.
3. Implement the code.
4. Run tests again; confirm they pass.

Skip TDD only when it clearly doesn't apply: throwaway scripts, exploration, UI/visual tweaks where the test isn't worth the cost, or when the user explicitly says otherwise. If skipping, say why briefly. For non-trivial tasks without testable behavior, state a verifiable success criterion before starting.

# Tests
- Test behavior that could plausibly break, not incidental output. Don't spam tests for trivia like "does this literal text render correctly".
- Assert behavior, not user-facing copy — the call, the state change, or the level/kind, never exact flash/label/error strings. If copy genuinely matters, match one keyword (e.g. `toContain("already")`); never add logic to source to satisfy a test's literal text.

# Subagents
- For subagents, pick the appropriate model for the task (e.g. Haiku for mechanical searches); don't default to the session model. Never use a model more expensive than the session model unless I explicitly ask. Cost order, most to least expensive: Fable > Opus > Sonnet > Haiku.

# Superpowers
Implement directly in-session from the spec/design doc, rather than using the writing-plans or subagent-driven-development skills. Subagents themselves are still fine to use, just not those skills

# Comments
- Default to no comment. Add one only to prevent a specific misunderstanding: non-obvious intent, a workaround, or a deliberate choice against the obvious alternative.
- One line, occasionally two. A paragraph is only justified for genuinely complex logic (subtle algorithm, hard-won invariant, tricky edge case).
- Never write a comment that justifies a change to a reviewer — especially when applying review feedback. If it explains why the diff is correct rather than what the next reader needs, it belongs in the PR description, not the code.
- Never reference issues without a GitHub issue number, or anything outside the codebase without a durable link. Cite as `#123`; ticket codenames (e.g. SANDBOX-1) and track/phase names don't count.
- Timeless present tense — no "now", "previously", "no longer", and no contrasts with removed alternatives ("no separate X call needed").

# Verification
- If linting or test scripts are available, always run them after you finish implementing a task
- Verify with the narrowest command that proves the change, then report the exact checks and outcomes.

# Python
- Avoid `Any`; use specific types, generics, or `Protocol`. Allow `Any` only at untyped boundaries, with a comment.

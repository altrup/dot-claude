---
name: grill-me
description: Ask the user clarification questions through AskUserQuestion, round after round, until the user says to stop. Use only when the user invokes /grill-me.
disable-model-invocation: true
---

# Grill me

Find the gaps between what the user wants and what you understand, and close
them with questions. The topic is the skill arguments, or the current
conversation if there are none.

## Loop

1. Read what you need first (code, files, conversation). Do not ask what you
   can find yourself.
2. Ask the 1-3 most important open questions with AskUserQuestion. Rank by
   how much a wrong assumption would change the result. Put your
   recommendation first where you have one.
3. Add one last question to each round: "More questions?" with the options
   "Continue" and "We're good".
4. Use the answers to find the next questions. Repeat until the user selects
   "We're good" or says so in text. Only the user ends the loop.

## No questions left

If you have no question whose answer would change what you do, say so
plainly and stop asking. Do not invent filler questions to keep the loop
alive: they cost the user time and hide the fact that you understand enough.
State any assumptions you still hold, so the user can correct them or end
the session.

## Finish

Give a short summary of the agreed understanding: decisions, assumptions,
open risks. Then stop. Do not start the work; the user gives that go-ahead
separately.

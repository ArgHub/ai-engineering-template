# Plan

<!-- ADAPT: replace with your project's goal, non-goals and milestones. -->

## Goal

Give any team a small, language-neutral structure for AI-assisted development that produces maintainable code and complies with security governance, with one small sample to make it concrete.

## Non-goals

Things we have decided not to do in this version. An agent must not add them; lifting one needs an ADR.

- No real authentication provider in the sample (demo API keys only).
- No database in the sample (in-memory repository).
- No samples in more than one language until the C# one has been used in practice.
- No dependency on any one CI provider beyond the two small GitHub workflows.

## Milestones

| # | Milestone | Status |
|---|---|---|
| M1 | AI structure: rules, memory, knowledge, reviewers, hard limits | Done |
| M2 | C# sample with tests and four walkthroughs | Done |
| M3 | Reviewer evals run and results recorded | Next |
| M4 | Go sample (optional) | Later |

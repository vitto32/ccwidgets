# Claude Model Short Badge Colors Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update the short Claude model badge so OP, SN, and HK use the requested text and background colors when color output is enabled.

**Architecture:** Keep the existing model detection and rendering flow in `claude-model.sh`, but split short-badge color handling from the default text-color rendering. Add a small shell test that asserts the emitted ANSI sequences for the short badge output.

**Tech Stack:** Bash, ANSI truecolor escape sequences

---

### Task 1: Add failing coverage for short badge colors

**Files:**
- Create: `scripts/claude-model/claude-model.test.sh`
- Test: `scripts/claude-model/claude-model.test.sh`

**Step 1: Write the failing test**

Create a shell test that:
- runs `scripts/claude-model/claude-model.sh --model-short --color`
- captures the output bytes as hex
- asserts:
  - Opus uses white text on default background
  - Sonnet uses `#1E1E2E` text on `#6CD7CA` background
  - Haiku uses `#C23128` text on `#FFC601` background

**Step 2: Run test to verify it fails**

Run: `bash scripts/claude-model/claude-model.test.sh`
Expected: FAIL because the script still emits the old foreground-only colors.

**Step 3: Write minimal implementation**

Update `scripts/claude-model/claude-model.sh` so the short badge can use dedicated foreground/background ANSI sequences without affecting full-name or emoji rendering.

**Step 4: Run test to verify it passes**

Run: `bash scripts/claude-model/claude-model.test.sh`
Expected: PASS

**Step 5: Verify broader behavior**

Run:
- `bash scripts/claude-model/claude-model.test.sh`
- `printf '{"model":{"id":"claude-sonnet"}}' | scripts/claude-model/claude-model.sh --emoji --model --color`

Expected:
- test passes
- non-short rendering still prints the existing colorized output

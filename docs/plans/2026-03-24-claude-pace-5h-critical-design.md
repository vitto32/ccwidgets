# Claude Pace 5h Critical State Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the 5-hour usage section render as critical when the window is fully exhausted and stop showing a meaningless safe rate in that state.

**Architecture:** Keep the fix local to `pretty_print` in `scripts/claude-pace/claude-pace`. The JSON processing already marks the 5-hour window as `critical`; the bug is that the pretty renderer derives color from `burn_rate` instead of reusing `status`. Add a focused regression test that captures the pretty output for a fully exhausted 5-hour window.

**Tech Stack:** Python 3, Bash test script

---

### Task 1: Add regression test

**Files:**
- Create: `scripts/claude-pace/claude-pace.test.sh`
- Test: `scripts/claude-pace/claude-pace.test.sh`

**Step 1: Write the failing test**

Create a shell test that:
- loads `scripts/claude-pace/claude-pace` via `runpy.run_path`
- calls `pretty_print()` with `five_hour.pct = 100`, `five_hour.status = "critical"`
- asserts the rendered output contains the red ANSI sequence for `100%`
- asserts the rendered output does not contain `Safe rate:`

**Step 2: Run test to verify it fails**

Run: `bash scripts/claude-pace/claude-pace.test.sh`

Expected: FAIL because current `pretty_print()` colors the 5-hour section from `burn_rate` and still prints `Safe rate:`

### Task 2: Implement minimal renderer fix

**Files:**
- Modify: `scripts/claude-pace/claude-pace`

**Step 1: Write minimal implementation**

Update `pretty_print()` so the 5-hour section:
- uses `five_hour.status` to derive color/state label
- treats `critical` as red even when the burn rate alone would only be yellow
- omits the safe-rate text entirely when remaining quota is `<= 0`

**Step 2: Run test to verify it passes**

Run: `bash scripts/claude-pace/claude-pace.test.sh`

Expected: PASS

### Task 3: Verify project state

**Files:**
- Modify: `scripts/claude-pace/claude-pace`
- Create: `scripts/claude-pace/claude-pace.test.sh`

**Step 1: Run targeted verification**

Run: `bash scripts/claude-pace/claude-pace.test.sh`

Expected: PASS

**Step 2: Run existing regression test**

Run: `bash scripts/claude-model/claude-model.test.sh`

Expected: PASS

**Step 3: Commit**

```bash
git add docs/plans/2026-03-24-claude-pace-5h-critical-design.md scripts/claude-pace/claude-pace scripts/claude-pace/claude-pace.test.sh
git commit -m "fix(claude-pace): mark exhausted 5h window critical"
```

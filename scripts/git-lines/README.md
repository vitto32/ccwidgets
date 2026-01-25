# git-lines

Show git diff line counts (added/removed).

## Usage

```bash
git-lines.sh
```

## Output

```
+45 -12     # 45 lines added, 12 removed
            # Empty if no unstaged changes
```

**Colors:**
- Green: added lines
- Red: removed lines

## Integration

### ccstatusline

```yaml
sections:
  - name: git-lines
    command: git-lines.sh
```

### Shell prompt

```bash
PS1='$(git-lines.sh) $ '
```

## Dependencies

- Git
- Bash

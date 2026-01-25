# git-files

Show git working directory file status as colored counts.

## Usage

```bash
git-files.sh
```

## Output

```
+3 ~2 -1    # 3 added, 2 modified, 1 deleted
✓ clean     # No changes (gray)
```

**Colors:**
- Green: added/untracked files
- Yellow: modified files
- Red: deleted files

## Integration

### ccstatusline

```yaml
sections:
  - name: git-files
    command: git-files.sh
```

### Shell prompt

```bash
# .bashrc / .zshrc
PS1='$(git-files.sh) $ '
```

## Dependencies

- Git
- Bash

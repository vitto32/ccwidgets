# context-pct

Display context window usage percentage with color coding.

## Usage

Reads JSON from stdin, outputs colored percentage:

```bash
echo '{"context_window":{"used_percentage":45}}' | context-pct.sh
```

## Output

Color-coded percentage based on thresholds:
- **Gray**: 0% (no context)
- **Green**: 1-49% (comfortable)
- **Yellow**: 50-69% (attention)
- **Orange**: 70-84% (warning)
- **Red**: 85%+ (critical)

## Integration

### ccstatusline

```yaml
sections:
  - name: context
    command: context-pct.sh
    stdin: true  # Receives session JSON
```

## Dependencies

- `jq`
- Bash

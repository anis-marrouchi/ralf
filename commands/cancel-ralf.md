---
description: "Cancel active Ralf loop"
allowed-tools: ["Bash(rm:*)"]
---

# Cancel Ralf Loop

Stop any active Ralf loop by removing the state file.

## Steps

1. Check if `.ralf/state.json` exists
2. If it exists:
   - Show current iteration and status
   - Remove the state file
   - Confirm cancellation
3. If it doesn't exist:
   - Inform user there's no active loop

## Execute

```bash
if [ -f ".ralf/state.json" ]; then
  echo "Current Ralf state:"
  cat .ralf/state.json | jq '.'
  rm .ralf/state.json
  echo ""
  echo "Ralf loop cancelled. The .ralf/prd.json and .ralf/progress.txt files are preserved."
  echo "Run /ralf to start a new loop."
else
  echo "No active Ralf loop found."
  echo ""
  echo "To start a new loop: /ralf [prd.json path]"
fi
```

## Important Notes

- This only cancels the loop - it does NOT delete prd.json or progress.txt
- Any completed stories remain marked as `passes: true`
- You can resume by running `/ralf` again
- The loop will pick up from the next incomplete story

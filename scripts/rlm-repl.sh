#!/bin/bash

# RLM REPL Environment Setup Script
# Initializes a Python REPL environment for RLM processing
#
# Usage: ./rlm-repl.sh <files_glob> <query>
# Example: ./rlm-repl.sh "src/**/*.ts" "Find all API endpoints"

set -euo pipefail

# Configuration
MAX_OUTPUT_CHARS=30000
MAX_FILE_SIZE=100000
DEFAULT_THRESHOLD=50000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
FILES_GLOB="${1:-}"
QUERY="${2:-}"
THRESHOLD="${3:-$DEFAULT_THRESHOLD}"

if [[ -z "$FILES_GLOB" ]] || [[ -z "$QUERY" ]]; then
    echo "Usage: $0 <files_glob> <query> [threshold]"
    echo ""
    echo "Arguments:"
    echo "  files_glob  - Glob pattern for files to analyze (e.g., 'src/**/*.ts')"
    echo "  query       - What to analyze or extract"
    echo "  threshold   - Token threshold (default: 50000)"
    echo ""
    echo "Example:"
    echo "  $0 'src/**/*.ts' 'Find all API endpoints'"
    exit 1
fi

# Create temporary directory for REPL session
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Python script that sets up the REPL environment
cat > "$TEMP_DIR/rlm_env.py" << 'PYTHON_ENV'
import os
import sys
import json
import re
import glob as glob_module
from pathlib import Path

# Global tracking
_sub_calls_made = 0
_tokens_processed = 0

# Store original print before overriding
import builtins
_original_print = builtins.print

def load_files(pattern, max_size=100000):
    """Load files matching glob pattern into context dict"""
    context = {}
    total_chars = 0

    # Handle both single pattern and list of patterns
    patterns = [pattern] if isinstance(pattern, str) else pattern

    for pat in patterns:
        for filepath in glob_module.glob(pat, recursive=True):
            if os.path.isfile(filepath):
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if len(content) <= max_size:
                            context[filepath] = content
                            total_chars += len(content)
                except Exception as e:
                    print(f"Warning: Could not read {filepath}: {e}", file=sys.stderr)

    return context, total_chars

def llm_query(prompt):
    """Query a sub-LLM for semantic analysis"""
    global _sub_calls_made
    _sub_calls_made += 1

    # Use Claude CLI for sub-queries
    import subprocess

    try:
        # Create a temporary file for the prompt
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(prompt)
            prompt_file = f.name

        # Call Claude CLI with the prompt
        result = subprocess.run(
            ['claude', '-p', prompt, '--output-format', 'text'],
            capture_output=True,
            text=True,
            timeout=60
        )

        os.unlink(prompt_file)

        if result.returncode == 0:
            return result.stdout.strip()
        else:
            # Check for common error conditions
            error_msg = result.stderr or result.stdout or "Unknown error"
            if "credit" in error_msg.lower() or "balance" in error_msg.lower():
                return f"[LLM query failed: Insufficient API credits. Error: {error_msg}]"
            return f"[LLM query failed (code {result.returncode}): {error_msg}]"
    except subprocess.TimeoutExpired:
        return "[LLM query timed out]"
    except FileNotFoundError:
        return "[Claude CLI not found - install with: npm install -g @anthropic-ai/claude-code]"
    except Exception as e:
        return f"[LLM query error: {e}]"

def truncated_print(*args, max_chars=30000, **kwargs):
    """Print with truncation for large outputs"""
    output = ' '.join(str(a) for a in args)
    if len(output) > max_chars:
        output = output[:max_chars] + f"\n... [truncated, {len(output) - max_chars} chars omitted]"
    _original_print(output, **kwargs)

def FINAL(answer):
    """Return final text answer"""
    result = {
        "type": "FINAL",
        "answer": answer,
        "sub_calls_made": _sub_calls_made,
        "tokens_processed": _tokens_processed
    }
    print(f"\n<FINAL_RESULT>{json.dumps(result, indent=2)}</FINAL_RESULT>")
    sys.exit(0)

def FINAL_VAR(var_name):
    """Return a variable's content as final answer"""
    # Get variable from calling frame
    import inspect
    frame = inspect.currentframe().f_back
    var_value = frame.f_locals.get(var_name) or frame.f_globals.get(var_name)

    if var_value is None:
        print(f"Error: Variable '{var_name}' not found")
        sys.exit(1)

    result = {
        "type": "FINAL_VAR",
        "variable": var_name,
        "value": var_value,
        "sub_calls_made": _sub_calls_made,
        "tokens_processed": _tokens_processed
    }
    print(f"\n<FINAL_RESULT>{json.dumps(result, indent=2, default=str)}</FINAL_RESULT>")
    sys.exit(0)

# Override print with truncated version
builtins.print = truncated_print

# Export functions to global namespace
__all__ = ['load_files', 'llm_query', 'FINAL', 'FINAL_VAR', 'truncated_print']
PYTHON_ENV

# Python script to initialize the session
cat > "$TEMP_DIR/init_session.py" << PYTHON_INIT
import sys
sys.path.insert(0, '$TEMP_DIR')

from rlm_env import *

# Load files from glob pattern
pattern = '''$FILES_GLOB'''
context, total_chars = load_files(pattern)
total_tokens = total_chars // 4  # Rough estimate

print("=" * 60)
print("RLM REPL Environment Initialized")
print("=" * 60)
print(f"Files loaded: {len(context)}")
print(f"Total size: {total_chars:,} characters (~{total_tokens:,} tokens)")
print(f"Query: $QUERY")
print("=" * 60)
print("")
print("Available variables:")
print("  context      - Dict mapping file paths to contents")
print("  total_chars  - Total characters loaded")
print("  total_tokens - Estimated token count")
print("")
print("Available functions:")
print("  llm_query(prompt)  - Query sub-LLM for semantic tasks")
print("  FINAL(answer)      - Return final text answer")
print("  FINAL_VAR(name)    - Return variable as final answer")
print("")

# Check if context exceeds threshold
threshold = $THRESHOLD
if total_tokens > threshold:
    print(f"NOTE: Context ({total_tokens:,} tokens) exceeds threshold ({threshold:,})")
    print("      Use chunking and filtering to process efficiently")
else:
    print(f"NOTE: Context ({total_tokens:,} tokens) is under threshold ({threshold:,})")
    print("      RLM may not be necessary for this context size")
print("")
PYTHON_INIT

# Run the initialization
echo -e "${GREEN}Starting RLM REPL session...${NC}"
echo ""

python3 "$TEMP_DIR/init_session.py"

# Start interactive Python REPL with environment loaded
echo -e "${YELLOW}Entering interactive REPL. Type 'exit()' or Ctrl+D to exit.${NC}"
echo ""

python3 -i "$TEMP_DIR/init_session.py"

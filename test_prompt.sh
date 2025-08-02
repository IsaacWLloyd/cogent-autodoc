#!/bin/bash

# Test script to debug the prompt variable issue

echo "=== Testing prompt variable assignment ==="

# Simulate the same environment as the main script
project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
prompt_path="$project_root/.cogent/templates/default-prompt.md"

echo "Project root: $project_root"
echo "Prompt path: $prompt_path"

# Test 1: Check if file exists
echo "=== Test 1: File existence ==="
if [ -f "$prompt_path" ]; then
    echo "✓ Prompt file exists at: $prompt_path"
else
    echo "✗ Prompt file NOT found at: $prompt_path"
    echo "Checking alternative locations..."
    find . -name "default-prompt.md" 2>/dev/null
fi

# Test 2: Try to read the file directly
echo -e "\n=== Test 2: Direct file read ==="
if [ -f "$prompt_path" ]; then
    echo "File contents:"
    cat "$prompt_path"
else
    echo "Cannot read file - doesn't exist"
fi

# Test 3: Test variable assignment
echo -e "\n=== Test 3: Variable assignment ==="
prompt=$(cat "$prompt_path" 2>/dev/null)
echo "Prompt variable length: ${#prompt}"
echo "Prompt variable content:"
echo "[$prompt]"

# Test 4: Test with debugging
echo -e "\n=== Test 4: Debug assignment ==="
set -x
prompt=$(cat "$prompt_path")
set +x
echo "After assignment - prompt length: ${#prompt}"

# Test 5: Test JSON output
echo -e "\n=== Test 5: JSON output test ==="
cat <<EOF
{
  "decision": "block",
  "reason": "$prompt"
}
EOF
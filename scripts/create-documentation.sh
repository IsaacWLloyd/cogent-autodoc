#!/bin/bash

# Claude Code Documentation Hook Script
# This script is triggered after Claude Code edits a file
# It creates a documentation template and triggers automatic filling

# Enable strict error handling
set -euo pipefail

# Function to log messages
log() {
    echo "[Documentation Hook] $1" >&2
}

# Function to extract file path from JSON input
extract_file_path() {
    local json="$1"
    # For PostToolUse hook, file_path is in tool_input.file_path
    # First try to extract from tool_input
    local file_path=$(echo "$json" | grep -o '"tool_input"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    
    # If not found in tool_input, try direct file_path (for manual testing)
    if [ -z "$file_path" ]; then
        file_path=$(echo "$json" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    echo "$file_path"
}

# Function to get relative path from project root
get_relative_path() {
    local file_path="$1"
    # Use CLAUDE_PROJECT_DIR if available, otherwise use current directory
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    
    # Remove project root from path if it exists
    if [[ "$file_path" == "$project_root"* ]]; then
        echo "${file_path#$project_root/}"
    else
        echo "$file_path"
    fi
}

# Function to create documentation directory structure
create_doc_directory() {
    local file_path="$1"
    local relative_path=$(get_relative_path "$file_path")
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local doc_dir="$project_root/.cogent/$relative_path"
    
    # Remove the filename to get just the directory
    doc_dir=$(dirname "$doc_dir")
    
    # Create directory if it doesn't exist
    mkdir -p "$doc_dir"
    echo "$doc_dir"
}

# Function to generate documentation filename
generate_doc_filename() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    echo "${filename}.md"
}

# Function to determine file type
get_file_type() {
    local file_path="$1"
    local extension="${file_path##*.}"
    
    case "$extension" in
        py) echo "Python" ;;
        js) echo "JavaScript" ;;
        ts|tsx) echo "TypeScript" ;;
        jsx) echo "React JavaScript" ;;
        java) echo "Java" ;;
        cpp|cc|cxx) echo "C++" ;;
        c) echo "C" ;;
        go) echo "Go" ;;
        rs) echo "Rust" ;;
        rb) echo "Ruby" ;;
        php) echo "PHP" ;;
        swift) echo "Swift" ;;
        kt) echo "Kotlin" ;;
        *) echo "Code" ;;
    esac
}

# Function to create documentation template
create_documentation_template() {
    local file_path="$1"
    local doc_path="$2"
    local file_type=$(get_file_type "$file_path")
    local filename=$(basename "$file_path")
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    cat > "$doc_path" << 'EOF'
# Documentation: `{{FILENAME}}`

## File Overview
<!-- PLACEHOLDER: Provide a comprehensive overview of what this {{FILE_TYPE}} file does, its main purpose, and its role in the system. Be specific about the functionality it provides. -->

[AI: Please describe the overall purpose and functionality of this file in 2-3 paragraphs]

## Intent
<!-- PLACEHOLDER: Explain WHY this file exists, what problem it solves, and what requirements or user needs it addresses. Include the business logic or technical rationale. -->

[AI: Please explain the intent behind this file - why it was created and what problem it solves]

## Project Integration
<!-- PLACEHOLDER: Describe how this file connects to and interacts with the overall project architecture. Include:
- What other components depend on this file
- What this file depends on
- How it fits into the larger system design
- Data flow and communication patterns -->

[AI: Please describe how this file integrates with the rest of the project, including dependencies and interactions]

## Recent Changes
**Last Updated:** {{TIMESTAMP}}
**Modified File:** `{{FILE_PATH}}`

<!-- PLACEHOLDER: Document what was changed in the most recent edit and why -->

[AI: Please describe the recent changes made to this file based on the latest edit]

## Key Components

### Classes
<!-- PLACEHOLDER: List and describe all classes defined in this file -->

[AI: Please list all classes with their purpose and key methods]

### Functions
<!-- PLACEHOLDER: List and describe all standalone functions -->

[AI: Please list all functions with their purpose, parameters, and return values]

### Important Variables/Constants
<!-- PLACEHOLDER: List and describe important variables, constants, or configuration values -->

[AI: Please list important variables and constants with their purpose]

## Dependencies

### Internal Dependencies
<!-- PLACEHOLDER: List all internal project files/modules this file imports or depends on -->

[AI: Please list all internal dependencies with brief descriptions]

### External Dependencies
<!-- PLACEHOLDER: List all external libraries, packages, or frameworks used -->

[AI: Please list all external dependencies with version requirements if applicable]

## Usage Examples

### Basic Usage
```{{LANGUAGE}}
<!-- PLACEHOLDER: Provide a simple example of how to use the main functionality -->

[AI: Please provide a basic usage example]
```

### Advanced Usage
```{{LANGUAGE}}
<!-- PLACEHOLDER: Provide more complex usage examples showing different features -->

[AI: Please provide an advanced usage example demonstrating key features]
```

## API Documentation
<!-- PLACEHOLDER: For files that expose public APIs, document all public methods/functions -->

[AI: Please document all public APIs with parameters, return types, and examples]

## Testing
<!-- PLACEHOLDER: Describe how this file is tested, what test files cover it, and any special testing considerations -->

[AI: Please describe the testing approach for this file]

## Error Handling
<!-- PLACEHOLDER: Document how errors are handled, what exceptions might be thrown, and recovery strategies -->

[AI: Please describe error handling patterns used in this file]

## Performance Considerations
<!-- PLACEHOLDER: Note any performance implications, optimizations, or concerns -->

[AI: Please describe any performance considerations or optimizations]

## Security Considerations
<!-- PLACEHOLDER: Document any security implications, data validation, or authentication/authorization logic -->

[AI: Please describe any security considerations for this file]

## Notes
<!-- PLACEHOLDER: Any additional important information, TODOs, known issues, or future improvements -->

[AI: Please add any additional notes, warnings, or important considerations]

---
*This documentation was automatically generated by the Cogent Documentation System*
EOF

    # Replace placeholders
    sed -i "s|{{FILENAME}}|$filename|g" "$doc_path"
    sed -i "s|{{FILE_TYPE}}|$file_type|g" "$doc_path"
    sed -i "s|{{TIMESTAMP}}|$timestamp|g" "$doc_path"
    sed -i "s|{{FILE_PATH}}|$file_path|g" "$doc_path"
    
    # Set appropriate language for code blocks
    local language=""
    case "${file_path##*.}" in
        py) language="python" ;;
        js) language="javascript" ;;
        ts|tsx) language="typescript" ;;
        jsx) language="jsx" ;;
        java) language="java" ;;
        cpp|cc|cxx) language="cpp" ;;
        c) language="c" ;;
        go) language="go" ;;
        rs) language="rust" ;;
        rb) language="ruby" ;;
        php) language="php" ;;
        swift) language="swift" ;;
        kt) language="kotlin" ;;
        *) language="text" ;;
    esac
    sed -i "s|{{LANGUAGE}}|$language|g" "$doc_path"
}

# Main execution
main() {
    log "Starting documentation generation hook"
    
    # Read JSON input from stdin
    local json_input=""
    if [ -t 0 ]; then
        log "No input provided"
        exit 1
    else
        json_input=$(cat)
    fi
    
    # Extract file path from JSON
    local file_path=$(extract_file_path "$json_input")
    
    if [ -z "$file_path" ]; then
        log "Error: Could not extract file_path from input"
        exit 1
    fi
    
    log "Processing file: $file_path"
    
    # Check if file should be skipped
    if [[ "$file_path" =~ \.(md|json|yml|yaml|toml|lock|gitignore|env)$ ]] || \
       [[ "$file_path" =~ /\.(cogent|claude|git)/ ]] || \
       [[ "$file_path" =~ /(node_modules|dist|__pycache__)/ ]]; then
        log "Skipping file based on exclusion rules: $file_path"
        exit 0
    fi
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        log "Warning: File does not exist: $file_path"
        exit 0
    fi
    
    # Create documentation directory
    local doc_dir=$(create_doc_directory "$file_path")
    local doc_filename=$(generate_doc_filename "$file_path")
    local doc_path="$doc_dir/$doc_filename"
    
    # Check if documentation already exists
    if [ -f "$doc_path" ]; then
        log "Documentation already exists: $doc_path"
        # Update the timestamp in existing documentation
        sed -i "s|^\*\*Last Updated:\*\* .*|**Last Updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")|" "$doc_path"
        # Use proper Claude Code hook feedback mechanism
        cat <<EOF
{
  "decision": "block",
  "reason": "Documentation already exists at $doc_path. Please update the existing documentation by reading both $file_path and $doc_path, then update the 'Recent Changes' section with the latest modifications and update any other sections that may have been affected by the changes."
}
EOF
        exit 0
    fi
    
    # Create documentation template
    create_documentation_template "$file_path" "$doc_path"
    
    log "Created documentation template: $doc_path"
    
    # Use proper Claude Code hook feedback mechanism
    cat <<EOF
{
  "decision": "block",
  "reason": "Documentation template created at $doc_path. Please fill it with content by analyzing the source file at $file_path. Read both files, then update the documentation template by replacing all [AI: ...] placeholders with comprehensive, accurate content based on the source code. Make sure to document all classes, functions, dependencies, and provide real usage examples."
}
EOF
}

# Run main function
main "$@"
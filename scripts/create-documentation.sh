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

# Function to check if file should be included based on patterns
should_include_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # Always skip certain directories and files
    if [[ "$file_path" =~ /\.(cogent|claude|git)/ ]] || \
       [[ "$file_path" =~ /(node_modules|dist|build|__pycache__|target|bin|obj)/ ]]; then
        return 1
    fi
    
    # Skip if COGENT_INCLUDE_PATTERNS is not set
    if [ -z "${COGENT_INCLUDE_PATTERNS:-}" ]; then
        return 1
    fi
    
    # Convert comma-separated patterns to array
    IFS=',' read -ra patterns <<< "$COGENT_INCLUDE_PATTERNS"
    
    # Check if filename matches any pattern
    for pattern in "${patterns[@]}"; do
        # Remove leading/trailing whitespace
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$filename" == $pattern ]]; then
            return 0
        fi
    done
    
    return 1
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

# Function to load environment variables from .env file
load_env() {
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local env_file="$project_root/.cogent/.env"
    local env_example_file="$project_root/.cogent/.env.example"
    
    if [ -f "$env_file" ]; then
        # Export variables from .env file
        set -a
        source "$env_file"
        set +a
    elif [ -f "$env_example_file" ]; then
        log "Warning: .cogent/.env file not found, using .env.example"
        # Export variables from .env.example file
        set -a
        source "$env_example_file"
        set +a
    else
        log "Warning: Neither .cogent/.env nor .cogent/.env.example found, using defaults"
        # Set defaults if neither file exists
        export COGENT_TEMPLATE_MAIN=".cogent/templates/default-template.md"
        export COGENT_PROMPT_CREATE=".cogent/templates/default-prompt.md"
        export COGENT_PROMPT_UPDATE=".cogent/templates/update-prompt.md"
        export COGENT_INCLUDE_PATTERNS="*.py,*.js,*.ts,*.tsx,*.jsx,*.java,*.cpp,*.cc,*.cxx,*.c,*.h,*.hpp,*.go,*.rs,*.rb,*.php,*.swift,*.kt,*.scala,*.cs"
    fi
}

# Function to create documentation template
create_documentation_template() {
    local file_path="$1"
    local doc_path="$2"
    local filename=$(basename "$file_path")
    
    # Get project root directory
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local template_path="$project_root/$COGENT_TEMPLATE_MAIN"
    
    # Copy template and replace filename placeholder
    cp "$template_path" "$doc_path"
    sed -i "s|{{FILENAME}}|$filename|g" "$doc_path"
}

# Main execution
main() {
    log "Starting documentation generation hook"
    
    # Load environment variables
    load_env
    
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
    
    # Check if file should be included based on patterns
    if ! should_include_file "$file_path"; then
        log "Skipping file based on inclusion patterns: $file_path"
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
        
        # Get project root directory and read update prompt
        local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
        local update_prompt_path="$project_root/$COGENT_PROMPT_UPDATE"
        local relative_doc_path=$(get_relative_path "$doc_path")
        local update_prompt=$(cat "$update_prompt_path" | sed "s|{{FILENAME}}|$(basename "$file_path")|g" | sed "s|{{DOC_PATH}}|$relative_doc_path|g" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
        
        # Use proper Claude Code hook feedback mechanism
        cat <<EOF
{
  "decision": "block",
  "reason": $update_prompt"
}
EOF
        exit 0
    fi
    
    # Create documentation template
    create_documentation_template "$file_path" "$doc_path"
    
    log "Created documentation template: $doc_path"
    
    # Get project root directory and read default prompt
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local prompt_path="$project_root/$COGENT_PROMPT_CREATE"
    local prompt=$(cat "$prompt_path" | sed "s|{{FILENAME}}|$(basename "$file_path")|g" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
    
    # Use proper Claude Code hook feedback mechanism - block and direct to fill template
    cat <<EOF
{
  "decision": "block",
  "reason": "Created documentation template at $doc_path. $prompt"
}
EOF
}

# Run main function
main "$@"

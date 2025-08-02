#!/bin/bash

# Cogent AutoDoc Installer
# Automated documentation generation for Claude Code projects
# https://github.com/IsaacWLloyd/cogent-autodoc

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://raw.githubusercontent.com/IsaacWLloyd/cogent-autodoc/main"
SCRIPT_URL="${REPO_URL}/scripts/create-documentation.sh"
TEMPLATE_URL="${REPO_URL}/scripts/templates/documentation.md"
PROMPT_URL="${REPO_URL}/scripts/templates/documentation-prompt.txt"
INSTALL_DIR=".cogent"
CLAUDE_SETTINGS_DIR=".claude"
CLAUDE_SETTINGS_FILE="${CLAUDE_SETTINGS_DIR}/settings.json"

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo -e "${PURPLE}▶${NC} $1"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
   ____                        _      _         _        ____             
  / ___|___   __ _  ___ _ __ __| |_   / \  _   _| |_ ___ |  _ \  ___   ___ 
 | |   / _ \ / _` |/ _ \ '_ ` _ \| __| / _ \| | | | __/ _ \| | | |/ _ \ / __|
 | |__| (_) | (_| |  __/ | | | | |_ / ___ \ |_| | || (_) | |_| | (_) | (__ 
  \____\___/ \__, |\___|_| |_| |\__/_/   \_\__,_|\__\___/|____/ \___/ \___|
             |___/                                                         
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Automated Documentation Generation for Claude Code${NC}"
    echo
}

# Function to read user input that works with piped installation
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local input=""
    
    # Try to read from /dev/tty first (for direct terminal input)
    if [[ -t 0 ]] && [[ -e /dev/tty ]]; then
        echo -n "$prompt"
        read -r input < /dev/tty || input="$default"
    else
        # If /dev/tty is not available, use default
        echo "$prompt (using default: $default)"
        input="$default"
    fi
    
    # Return the result (use default if input is empty)
    echo "${input:-$default}"
}

check_dependencies() {
    log_step "Checking dependencies..."
    
    # Check for curl or wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
    
    # Check for basic Unix tools
    for tool in grep sed mkdir chmod; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool '$tool' is not available."
            exit 1
        fi
    done
    
    log_success "All dependencies satisfied"
}

detect_project_type() {
    log_step "Detecting project type..."
    
    local project_type="generic"
    
    if [[ -f "package.json" ]]; then
        if grep -q "react" package.json; then
            project_type="react"
        elif grep -q "typescript" package.json; then
            project_type="typescript"
        else
            project_type="nodejs"
        fi
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        project_type="python"
    elif [[ -f "Cargo.toml" ]]; then
        project_type="rust"
    elif [[ -f "go.mod" ]]; then
        project_type="go"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        project_type="java"
    fi
    
    log_info "Detected project type: ${project_type}"
    echo "$project_type"
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$output"
    else
        log_error "No download tool available"
        exit 1
    fi
}

setup_cogent_directory() {
    log_step "Setting up .cogent directory..."
    
    # Create .cogent directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        log_success "Created $INSTALL_DIR directory"
    else
        log_warning "$INSTALL_DIR directory already exists"
    fi
    
    # Create templates directory
    local templates_dir="${INSTALL_DIR}/templates"
    if [[ ! -d "$templates_dir" ]]; then
        mkdir -p "$templates_dir"
        log_success "Created templates directory"
    fi
    
    # Download the documentation script
    local script_path="${INSTALL_DIR}/create-documentation.sh"
    log_info "Downloading documentation script..."
    
    if download_file "$SCRIPT_URL" "$script_path"; then
        chmod +x "$script_path"
        log_success "Documentation script installed and made executable"
    else
        log_error "Failed to download documentation script"
        exit 1
    fi
    
    # Download the documentation template
    local template_path="${templates_dir}/documentation.md"
    log_info "Downloading documentation template..."
    
    if download_file "$TEMPLATE_URL" "$template_path"; then
        log_success "Documentation template installed"
    else
        log_error "Failed to download documentation template"
        exit 1
    fi
    
    # Download the documentation prompt
    local prompt_path="${templates_dir}/documentation-prompt.txt"
    log_info "Downloading documentation prompt..."
    
    if download_file "$PROMPT_URL" "$prompt_path"; then
        log_success "Documentation prompt installed"
    else
        log_error "Failed to download documentation prompt"
        exit 1
    fi
}

# JSON utility functions
validate_json() {
    local json_file="$1"
    if command -v python3 &> /dev/null; then
        python3 -m json.tool "$json_file" >/dev/null 2>&1
    elif command -v node &> /dev/null; then
        node -e "JSON.parse(require('fs').readFileSync('$json_file', 'utf8'))" >/dev/null 2>&1
    else
        # Basic validation - check for balanced braces
        local open_braces=$(grep -o '{' "$json_file" | wc -l)
        local close_braces=$(grep -o '}' "$json_file" | wc -l)
        [[ "$open_braces" -eq "$close_braces" ]]
    fi
}

merge_json_settings() {
    local settings_file="$1"
    local temp_file="${settings_file}.tmp"
    
    # Our hook configuration to add
    local new_hook='{
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.cogent/create-documentation.sh"
          }
        ]
      }'
    
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON merging
        log_info "Using jq for safe JSON merging..."
        
        # Check if hooks.PostToolUse already exists
        if jq -e '.hooks.PostToolUse' "$settings_file" >/dev/null 2>&1; then
            # PostToolUse exists, append to it
            jq --argjson newhook "$new_hook" '.hooks.PostToolUse += [$newhook]' "$settings_file" > "$temp_file"
        elif jq -e '.hooks' "$settings_file" >/dev/null 2>&1; then
            # hooks exists but no PostToolUse, create it
            jq --argjson newhook "$new_hook" '.hooks.PostToolUse = [$newhook]' "$settings_file" > "$temp_file"
        else
            # No hooks at all, create the whole structure
            jq --argjson newhook "$new_hook" '.hooks = { "PostToolUse": [$newhook] }' "$settings_file" > "$temp_file"
        fi
        
        # Validate the result
        if validate_json "$temp_file"; then
            mv "$temp_file" "$settings_file"
            log_success "Successfully merged hook configuration with jq"
        else
            rm -f "$temp_file"
            log_error "JSON merge failed validation"
            return 1
        fi
    else
        # Fallback: Python-based JSON merging
        log_info "Using Python for JSON merging (jq not available)..."
        
        python3 << EOF
import json
import sys

try:
    # Read existing settings
    with open('$settings_file', 'r') as f:
        settings = json.load(f)
    
    # Ensure hooks structure exists
    if 'hooks' not in settings:
        settings['hooks'] = {}
    if 'PostToolUse' not in settings['hooks']:
        settings['hooks']['PostToolUse'] = []
    
    # Our new hook
    new_hook = {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
            {
                "type": "command",
                "command": "\$CLAUDE_PROJECT_DIR/.cogent/create-documentation.sh"
            }
        ]
    }
    
    # Check if our hook already exists (avoid duplicates)
    hook_exists = False
    for hook in settings['hooks']['PostToolUse']:
        if (hook.get('matcher') == 'Edit|Write|MultiEdit' and 
            len(hook.get('hooks', [])) > 0 and
            'create-documentation.sh' in str(hook['hooks'][0].get('command', ''))):
            hook_exists = True
            break
    
    if not hook_exists:
        settings['hooks']['PostToolUse'].append(new_hook)
    
    # Write back
    with open('$settings_file', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF
        
        if [[ $? -eq 0 ]]; then
            log_success "Successfully merged hook configuration with Python"
        else
            log_error "Python JSON merge failed"
            return 1
        fi
    fi
}

setup_claude_settings() {
    log_step "Setting up Claude Code hooks..."
    
    # Create .claude directory if it doesn't exist
    if [[ ! -d "$CLAUDE_SETTINGS_DIR" ]]; then
        mkdir -p "$CLAUDE_SETTINGS_DIR"
        log_success "Created $CLAUDE_SETTINGS_DIR directory"
    fi
    
    # Handle existing settings.json
    if [[ -f "$CLAUDE_SETTINGS_FILE" ]]; then
        log_info "Existing Claude settings found at $CLAUDE_SETTINGS_FILE"
        
        # Validate existing JSON
        if ! validate_json "$CLAUDE_SETTINGS_FILE"; then
            log_error "Existing settings.json contains invalid JSON"
            local response=$(read_input "Attempt to fix and continue? (y/N): " "N")
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Skipping Claude settings update"
                return 0
            fi
            
            # Try to fix common JSON issues
            sed -i 's/,}/}/g; s/,]/]/g' "$CLAUDE_SETTINGS_FILE"
            if ! validate_json "$CLAUDE_SETTINGS_FILE"; then
                log_error "Unable to fix JSON syntax. Please fix manually."
                return 1
            fi
        fi
        
        # Create backup
        local backup_file="${CLAUDE_SETTINGS_FILE}.backup.$(date +%s)"
        cp "$CLAUDE_SETTINGS_FILE" "$backup_file"
        log_success "Backup created at $backup_file"
        
        # Check if our hook already exists
        if grep -q "create-documentation.sh" "$CLAUDE_SETTINGS_FILE"; then
            log_info "Cogent AutoDoc hook already configured"
            return 0
        fi
        
        # Attempt to merge settings
        if merge_json_settings "$CLAUDE_SETTINGS_FILE"; then
            log_success "Successfully merged hook configuration"
        else
            log_warning "Automatic merge failed. Manual configuration required:"
            cat << 'EOF'

Add this hook to your existing PostToolUse hooks array in settings.json:

{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "$CLAUDE_PROJECT_DIR/.cogent/create-documentation.sh"
    }
  ]
}

Or if you don't have PostToolUse hooks yet, add this to your settings.json:

"hooks": {
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "$CLAUDE_PROJECT_DIR/.cogent/create-documentation.sh"
        }
      ]
    }
  ]
}
EOF
            return 0
        fi
    else
        # Create new settings.json
        log_info "Creating new Claude Code settings file"
        cat > "$CLAUDE_SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.cogent/create-documentation.sh"
          }
        ]
      }
    ]
  }
}
EOF
        log_success "Created new Claude Code settings with hook configuration"
    fi
    
    # Final validation
    if ! validate_json "$CLAUDE_SETTINGS_FILE"; then
        log_error "Final settings.json validation failed"
        if [[ -f "${CLAUDE_SETTINGS_FILE}.backup.$(date +%s)" ]]; then
            log_info "Restoring from backup..."
            mv "${backup_file}" "$CLAUDE_SETTINGS_FILE"
        fi
        return 1
    fi
    
    log_success "Claude Code hooks configured successfully"
}

create_gitignore_entries() {
    log_step "Updating .gitignore..."
    
    local gitignore_entries=(
        "# Cogent AutoDoc - Documentation templates (commit these)"
        ".cogent/"
        ""
        "# Cogent AutoDoc - Exclude if you don't want to commit docs"
        "# .cogent/"
    )
    
    if [[ -f ".gitignore" ]]; then
        # Check if entries already exist
        if ! grep -q "Cogent AutoDoc" .gitignore; then
            echo "" >> .gitignore
            printf '%s\n' "${gitignore_entries[@]}" >> .gitignore
            log_success "Added .cogent entries to .gitignore"
        else
            log_info ".gitignore already contains Cogent AutoDoc entries"
        fi
    else
        printf '%s\n' "${gitignore_entries[@]}" > .gitignore
        log_success "Created .gitignore with .cogent entries"
    fi
}

show_usage_instructions() {
    echo
    log_success "Installation complete!"
    echo
    log_info "How to use Cogent AutoDoc:"
    echo
    echo -e "${YELLOW}1. Create or edit files using Claude Code${NC}"
    echo "   The hook will automatically trigger and create documentation templates"
    echo
    echo -e "${YELLOW}2. Documentation files are stored in:${NC}"
    echo "   .cogent/[relative-path-to-file].md"
    echo
    echo -e "${YELLOW}3. Customization:${NC}"
    echo "   - Edit .cogent/templates/documentation.md to modify the template"
    echo "   - Edit .cogent/templates/documentation-prompt.txt to modify the prompt"
    echo "   - Documentation templates are auto-filled by Claude"
    echo "   - Check .claude/settings.json for hook configuration"
    echo
    echo -e "${YELLOW}4. Project Integration:${NC}"
    echo "   - Add to CLAUDE.md: \"Check .cogent/ for existing documentation\""
    echo "   - Commit .cogent/ to share docs with your team"
    echo
    echo -e "${GREEN}Example workflow:${NC}"
    echo "   $ claude-code"
    echo "   > Write a new React component"
    echo "   → Hook automatically creates documentation"
    echo "   → Claude fills in the documentation details"
    echo
    echo -e "${CYAN}For more information: https://github.com/IsaacWLloyd/cogent-autodoc${NC}"
}

interactive_setup() {
    local project_type="$1"
    
    echo
    log_step "Interactive Setup"
    echo
    
    # Ask about documentation preferences
    echo -e "${YELLOW}Documentation Preferences:${NC}"
    echo "1. Comprehensive (detailed docs for all files)"
    echo "2. Selective (docs only for important files)" 
    echo "3. Minimal (basic structure only)"
    local doc_level=$(read_input "Choose documentation level (1-3, default: 1): " "1")
    
    # Ask about file exclusions
    echo
    echo -e "${YELLOW}File Exclusions:${NC}"
    echo "Current exclusions: .md, .json, .yml, node_modules, dist, __pycache__"
    local custom_exclusions=$(read_input "Add custom exclusions (comma-separated, or press Enter to skip): " "")
    
    # Ask about template customization
    echo
    echo -e "${YELLOW}Template Customization:${NC}"
    local customize_template=$(read_input "Customize documentation template for $project_type? (y/N): " "N")
    
    if [[ "$customize_template" =~ ^[Yy]$ ]]; then
        log_info "Template customization will be available in future versions"
        log_info "For now, edit .cogent/create-documentation.sh manually"
    fi
    
    # Save preferences (for future use)
    cat > "${INSTALL_DIR}/config.json" << EOF
{
  "project_type": "$project_type",
  "documentation_level": $doc_level,
  "custom_exclusions": "$custom_exclusions",
  "template_customized": false,
  "installed_at": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
}
EOF
    
    log_success "Configuration saved to ${INSTALL_DIR}/config.json"
}

main() {
    print_banner
    
    # Check if we're in a valid project directory
    if [[ ! -f "$(pwd)" ]] && [[ ! -d ".git" ]] && [[ ! -f "package.json" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "Cargo.toml" ]]; then
        log_warning "This doesn't appear to be a project root directory"
        local response=$(read_input "Continue anyway? (y/N): " "N")
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    check_dependencies
    
    local project_type
    project_type=$(detect_project_type)
    
    setup_cogent_directory
    setup_claude_settings
    create_gitignore_entries
    
    # Ask if user wants interactive setup
    echo
    local interactive=$(read_input "Run interactive setup for advanced configuration? (y/N): " "N")
    
    if [[ "$interactive" =~ ^[Yy]$ ]]; then
        interactive_setup "$project_type"
    fi
    
    show_usage_instructions
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Cogent AutoDoc Installer"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version, -v  Show version information"
        echo "  --uninstall    Remove Cogent AutoDoc from this project"
        echo
        echo "For more information: https://github.com/IsaacWLloyd/cogent-autodoc"
        exit 0
        ;;
    --version|-v)
        echo "Cogent AutoDoc v1.0.0"
        exit 0
        ;;
    --uninstall)
        log_step "Uninstalling Cogent AutoDoc..."
        
        # Remove .cogent directory
        if [[ -d "$INSTALL_DIR" ]]; then
            rm -rf "$INSTALL_DIR"
            log_success "Removed $INSTALL_DIR directory"
        fi
        
        # Remove hooks from settings.json (if they exist)
        if [[ -f "$CLAUDE_SETTINGS_FILE" ]] && grep -q "create-documentation.sh" "$CLAUDE_SETTINGS_FILE"; then
            log_warning "Please manually remove hook configuration from $CLAUDE_SETTINGS_FILE"
        fi
        
        log_success "Uninstallation complete"
        exit 0
        ;;
    "")
        # No arguments, run main installation
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
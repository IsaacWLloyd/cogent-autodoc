#!/bin/bash

# Cogent AutoDoc Installer
# Automated documentation generation for Claude Code projects
# https://github.com/IsaacWLloyd/cogent-autodoc

set -euo pipefail

# Colors for output
if [[ -n "${NO_COLOR:-}" ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    NC=''
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
fi

# Configuration
REPO_URL="https://raw.githubusercontent.com/IsaacWLloyd/cogent-autodoc/main"
SCRIPT_URL="${REPO_URL}/scripts/create-documentation.sh"
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
=========================================
    C O G E N T   A U T O D O C  
  Automated Documentation Generation
=========================================
EOF
    echo -e "${NC}"
    echo
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

attempt_global_install() {
    local source_tool="$1"
    local global_bin_dir="$HOME/.local/bin"
    local global_tool_path="$global_bin_dir/cogent-config"
    
    # Check if ~/.local/bin exists or can be created
    if [[ ! -d "$global_bin_dir" ]]; then
        if mkdir -p "$global_bin_dir" 2>/dev/null; then
            log_success "Created ~/.local/bin directory"
        else
            log_warning "Cannot create ~/.local/bin directory"
            show_global_install_instructions "$source_tool"
            return 1
        fi
    fi
    
    # Try to copy the tool globally
    if cp "$source_tool" "$global_tool_path" 2>/dev/null; then
        log_success "Configuration tool installed globally to $global_tool_path"
        
        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$global_bin_dir:"* ]]; then
            log_warning "~/.local/bin is not in your PATH"
            echo
            log_info "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
            echo -e "  ${GREEN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
            echo
            log_info "Or reload your shell after installation with:"
            echo -e "  ${GREEN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
            echo
        fi
        
        log_info "You can now run 'cogent-config' from anywhere!"
        return 0
    else
        log_warning "Cannot install globally to $global_tool_path"
        show_global_install_instructions "$source_tool"
        return 1
    fi
}

show_global_install_instructions() {
    local source_tool="$1"
    echo
    log_info "To install cogent-config globally yourself, run:"
    echo -e "  ${GREEN}mkdir -p ~/.local/bin${NC}"
    echo -e "  ${GREEN}cp \"$source_tool\" ~/.local/bin/cogent-config${NC}"
    echo -e "  ${GREEN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo
    log_info "Or use the project-local version:"
    echo -e "  ${GREEN}.cogent/bin/cogent-config --interactive${NC}"
    echo
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
    
    # Download and install .env.example, then copy to .env if it doesn't exist
    local env_example_url="${REPO_URL}/.env.example"
    local env_example_path="${INSTALL_DIR}/.env.example"
    local env_file="${INSTALL_DIR}/.env"
    
    log_info "Downloading .env.example configuration file..."
    if download_file "$env_example_url" "$env_example_path"; then
        log_success ".env.example configuration file downloaded"
        
        # Copy to .env if it doesn't exist
        if [[ ! -f "$env_file" ]]; then
            cp "$env_example_path" "$env_file"
            log_success "Created .env configuration file from .env.example"
        else
            log_info ".env configuration file already exists"
        fi
    else
        log_error "Failed to download .env.example configuration file"
        exit 1
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
    
    # Download template files
    local default_template_url="${REPO_URL}/templates/default-template.md"
    local default_prompt_url="${REPO_URL}/templates/default-prompt.md"
    local update_prompt_url="${REPO_URL}/templates/update-prompt.md"
    local default_template_path="${templates_dir}/default-template.md"
    local default_prompt_path="${templates_dir}/default-prompt.md"
    local update_prompt_path="${templates_dir}/update-prompt.md"
    
    log_info "Downloading template files..."
    
    if download_file "$default_template_url" "$default_template_path"; then
        log_success "Default template downloaded"
    else
        log_error "Failed to download default template"
        exit 1
    fi
    
    if download_file "$default_prompt_url" "$default_prompt_path"; then
        log_success "Default prompt template downloaded"
    else
        log_error "Failed to download default prompt template"
        exit 1
    fi
    
    if download_file "$update_prompt_url" "$update_prompt_path"; then
        log_success "Update prompt template downloaded"
    else
        log_error "Failed to download update prompt template"
        exit 1
    fi
    
    # Create bin directory and download cogent-config tool
    local bin_dir="${INSTALL_DIR}/bin"
    mkdir -p "$bin_dir"
    
    local config_tool_url="${REPO_URL}/bin/cogent-config"
    local config_tool_path="${bin_dir}/cogent-config"
    
    log_info "Downloading configuration tool..."
    if download_file "$config_tool_url" "$config_tool_path"; then
        chmod +x "$config_tool_path"
        log_success "Configuration tool installed to .cogent/bin/"
    else
        log_error "Failed to download configuration tool"
        exit 1
    fi
    
    # Attempt global installation
    attempt_global_install "$config_tool_path"
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
            echo -n "Attempt to fix and continue? (y/N): "
            read -r response
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
        "# Cogent AutoDoc - Generated documentation"
        ".cogent/"
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

update_claude_md() {
    log_step "Updating CLAUDE.md..."
    
    local claude_md_file="CLAUDE.md"
    local cogent_section="## Cogent AutoDoc
For context about any file, check \`.cogent/[relative-path-to-file].md\` unless you're completely confident about its purpose and implementation."
    
    if [[ -f "$claude_md_file" ]]; then
        # Check if Cogent AutoDoc section already exists
        if grep -q "## Cogent AutoDoc" "$claude_md_file"; then
            log_info "CLAUDE.md already contains Cogent AutoDoc section"
            return 0
        fi
        
        # Find insertion point after first # header and its content
        local temp_file="${claude_md_file}.tmp"
        local found_first_header=false
        local inserted=false
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            echo "$line" >> "$temp_file"
            
            # If we found the first # header but haven't inserted yet
            if [[ "$found_first_header" == true && "$inserted" == false ]]; then
                # Check if this line starts a new ## section or we're at EOF
                if [[ "$line" =~ ^##[[:space:]] ]] || [[ -z "$line" && $(wc -l < "$temp_file") -gt 1 ]]; then
                    # Insert our section before this line
                    if [[ "$line" =~ ^##[[:space:]] ]]; then
                        # Remove the last line we just added, insert our section, then add it back
                        sed -i '$d' "$temp_file"
                        echo "" >> "$temp_file"
                        echo "$cogent_section" >> "$temp_file"
                        echo "" >> "$temp_file"
                        echo "$line" >> "$temp_file"
                    else
                        echo "" >> "$temp_file"
                        echo "$cogent_section" >> "$temp_file"
                    fi
                    inserted=true
                fi
            fi
            
            # Mark when we've found the first # header
            if [[ "$line" =~ ^#[[:space:]] && "$found_first_header" == false ]]; then
                found_first_header=true
            fi
            
        done < "$claude_md_file"
        
        # If we never found a good insertion point, append to end
        if [[ "$inserted" == false ]]; then
            echo "" >> "$temp_file"
            echo "$cogent_section" >> "$temp_file"
        fi
        
        mv "$temp_file" "$claude_md_file"
        log_success "Added Cogent AutoDoc section to existing CLAUDE.md"
    else
        # Create new CLAUDE.md file
        echo "$cogent_section" > "$claude_md_file"
        log_success "Created CLAUDE.md with Cogent AutoDoc section"
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
    echo -e "${YELLOW}3. Configuration:${NC}"
    echo -e "   ${GREEN}▶ Use the configuration tool to customize settings:${NC}"
    echo -e "   ${GREEN}▶ cogent-config --interactive${NC} (if installed globally)"
    echo -e "   ${GREEN}▶ .cogent/bin/cogent-config --interactive${NC} (project-local)"
    echo "   - Manage .gitignore settings"
    echo "   - Configure version history" 
    echo "   - Edit custom templates"
    echo "   - View and reset settings"
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


main() {
    print_banner
    
    # Check if we're in a valid project directory
    if [[ ! -f "$(pwd)" ]] && [[ ! -d ".git" ]] && [[ ! -f "package.json" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "Cargo.toml" ]]; then
        log_warning "This doesn't appear to be a project root directory"
        echo -n "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    check_dependencies
    
    detect_project_type >/dev/null
    
    setup_cogent_directory
    setup_claude_settings
    create_gitignore_entries
    update_claude_md
    
    show_usage_instructions
    
    # Show configuration information
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🚀 Next Steps: Configure Your Settings${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}Configure Cogent AutoDoc settings using the configuration tool:${NC}"
    echo
    if command -v cogent-config &> /dev/null; then
        echo -e "  ${GREEN}cogent-config --interactive${NC}"
    else
        echo -e "  ${GREEN}.cogent/bin/cogent-config --interactive${NC}"
    fi
    echo
    echo -e "${CYAN}This tool allows you to:${NC}"
    echo "  • Manage .gitignore settings for .cogent/"
    echo "  • Configure version history settings"
    echo "  • Create and edit custom templates"
    echo "  • View current configuration"
    echo "  • Reset to default settings"
    echo
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
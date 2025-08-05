# Cogent AutoDoc

**Simple Claude Code hook that creates file-level intent documentation, helping Claude understand your codebase better by bridging knowledge gaps.**

## 🚀 Installation

Run this command in your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/IsaacWLloyd/cogent-autodoc/main/install.sh | bash
```

Or with wget:

```bash
wget https://raw.githubusercontent.com/IsaacWLloyd/cogent-autodoc/main/install.sh && chmod +x install.sh && ./install.sh
```

## 💬 Community

Join our Discord community for support, feedback, and discussions:

**[discord.gg/krmUwwNhsp](https://discord.gg/krmUwwNhsp)**

## ✨ Features

- **📋 File-Level Intent Documents**: Creates structured templates explaining what each file does and why
- **🔗 Claude Code Integration**: Works seamlessly as a post-edit hook (Claude Code only)
- **📁 Organized Documentation**: Files stored in `.cogent/[filepath].md` mirroring your project structure
- **⚙️ Easy Configuration**: Simple setup with `cogent-config` tool
- **🎯 Context for Claude**: Helps Claude understand your project's architecture and decisions
- **🔄 Template-Based**: Consistent documentation structure across your project

## How It Works

1. **Edit files** using Claude Code as usual
2. **Hook triggers automatically** after file changes
3. **Template created** in `.cogent/[filepath].md` with structured sections
4. **Claude fills template** based on your code during the same session
5. **File-level context** available for future Claude interactions

## Value Proposition

Bridge Claude's knowledge gaps about your specific codebase. When Claude is unsure about a file, it can reference `.cogent/` documentation to understand the file's purpose, architecture decisions, and how it fits into your project.

## 📋 What Gets Documented

### Template Sections

- **File Purpose**: What this file does in your system
- **Implementation Overview**: Key functions and components  
- **Project Integration**: How it connects to other files
- **Usage Patterns**: How other parts of your code use this file
- **Architecture Decisions**: Why it was built this way

## 🛠️ Configuration

Use the configuration tool to customize settings:

```bash
cogent-config --interactive
```

Or if not installed globally:

```bash
.cogent/bin/cogent-config --interactive
```

### Configuration Options

- **Template Customization**: Edit documentation templates for your needs
- **Gitignore Management**: Control whether `.cogent/` is ignored in version control
- **File Pattern Exclusions**: Choose which file types to document
- **Version History**: Optionally save previous documentation versions

## 📁 Project Structure

```
your-project/
├── .claude/
│   └── settings.json          # Hook configuration
├── .cogent/
│   ├── bin/
│   │   └── cogent-config      # Configuration tool
│   ├── templates/             # Documentation templates
│   ├── create-documentation.sh # Documentation generator script
│   └── [your-project-structure-mirrored]/
│       └── *.md               # Generated documentation files
├── src/
│   └── components/
│       └── MyComponent.tsx    # Your actual code
```

## 🎯 Use Cases

### Development Context
- **Understanding unfamiliar code**: Quick context when working in new areas
- **Architectural decisions**: Document why code was structured a certain way
- **Future maintenance**: Remember the intent behind complex implementations
- **Code reviews**: Provide reviewers with file-level context

### Team Knowledge Sharing
- **Onboarding**: Help new team members understand existing code
- **Handoffs**: Transfer knowledge about specific files or modules
- **Cross-team collaboration**: Share context when working on shared codebases

## 🔧 Commands

### Configuration
```bash
cogent-config --interactive  # Interactive configuration menu
cogent-config --view        # Show current settings
cogent-config --help        # Show all available options
```

### File Operations
```bash
ls .cogent/                 # View all generated docs
find .cogent/ -name "*.md"  # Find documentation files
grep -r "keyword" .cogent/  # Search across documentation
```

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Report Issues**: Found a bug or have a feature request? [Open an issue](https://github.com/IsaacWLloyd/cogent-autodoc/issues)
2. **Improve Templates**: Submit better documentation templates for specific languages/frameworks
3. **Testing**: Help test across different environments and project types

### Development Setup

```bash
git clone https://github.com/IsaacWLloyd/cogent-autodoc.git
cd cogent-autodoc
# Test the installer
./install.sh --help
# Run in a test project
cd /path/to/test/project
/path/to/cogent-autodoc/install.sh
```

## 🔍 Troubleshooting

**Hook not triggering?**
- Check `.claude/settings.json` syntax
- Verify `.cogent/create-documentation.sh` has execute permissions
- Ensure you're using Claude Code (this only works with Claude Code)

**Installation fails?**
- Check internet connectivity for script download
- Verify write permissions in project directory
- Ensure required tools (curl/wget, grep, sed) are available

### Getting Help

- 💬 **Discord**: [discord.gg/krmUwwNhsp](https://discord.gg/krmUwwNhsp)
- 🐛 **Issues**: [GitHub Issues](https://github.com/IsaacWLloyd/cogent-autodoc/issues)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Ready to help Claude understand your codebase better?**

```bash
curl -fsSL https://raw.githubusercontent.com/IsaacWLloyd/cogent-autodoc/main/install.sh | bash
```

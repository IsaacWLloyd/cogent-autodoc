# Cogent AutoDoc

**Automated Documentation Generation for Claude Code Projects**

Transform your development workflow with AI-powered documentation that writes itself. Cogent AutoDoc integrates seamlessly with Claude Code to generate comprehensive, intelligent documentation every time you create or modify files.

## ✨ Features

- **🤖 AI-Generated Documentation**: Claude analyzes your code and generates detailed, contextual documentation
- **⚡ Zero Developer Overhead**: No need to write inline comments or maintain docs manually
- **🔄 Automatic Updates**: Documentation stays current with your code changes
- **🎯 Context-Aware**: Understands business logic, architecture patterns, and cross-file relationships
- **📚 Comprehensive Coverage**: Documents functions, classes, dependencies, usage examples, and more
- **🌍 Multi-Language Support**: Works with TypeScript, Python, Rust, Go, Java, and more
- **🚀 One-Line Installation**: Get started in seconds with our installer script

## 🚀 Quick Start

### Installation

Run this command in your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/cogent-autodoc/main/install.sh | bash
```

Or for manual installation:

```bash
wget https://raw.githubusercontent.com/yourusername/cogent-autodoc/main/install.sh
chmod +x install.sh
./install.sh
```

### How It Works

1. **Create or edit files** using Claude Code as usual
2. **Hook automatically triggers** when you save changes
3. **Documentation template** is created in `.cogent/[filepath].md`
4. **Claude fills in details** based on your actual code
5. **Ready-to-use docs** appear instantly

### Example Workflow

```bash
$ claude-code
> Create a new React component for user authentication
```

**Result**: Not only do you get your component, but also:
- Complete API documentation in `.cogent/components/AuthComponent.tsx.md`
- Usage examples and integration guidelines
- Security considerations and error handling details
- Dependency mapping and performance notes

## 📋 What Gets Documented

### Automatically Generated Sections

- **File Overview**: Purpose, functionality, and system role
- **Intent**: Why the file exists and what problems it solves
- **Project Integration**: Dependencies and architectural relationships
- **Key Components**: Classes, functions, and important variables
- **Usage Examples**: Basic and advanced implementation patterns
- **API Documentation**: Complete parameter and return type details
- **Error Handling**: Exception patterns and recovery strategies
- **Performance Notes**: Optimizations and bottlenecks
- **Security Considerations**: Validation, authentication, and risk assessment

### Smart Analysis Features

- 🔍 **Cross-file Analysis**: Maps relationships between components
- 🧠 **Business Logic Understanding**: Explains the "why" behind technical decisions
- 📊 **Data Flow Documentation**: Traces how information moves through your system
- 🔒 **Security Pattern Recognition**: Identifies and documents security implementations
- ⚡ **Performance Impact Assessment**: Notes optimization opportunities and bottlenecks

## 🛠️ Configuration

### Basic Setup

The installer automatically configures:
- `.cogent/` directory for documentation storage
- `.claude/settings.json` with hook configuration
- `.gitignore` entries for proper version control

### Advanced Configuration

#### Interactive Setup
```bash
./install.sh
# Choose 'y' for interactive setup to customize:
# - Documentation verbosity level (1-3)
# - Custom file exclusions
# - Project-specific templates
```

#### Manual Customization

Edit `.cogent/create-documentation.sh` to:
- Modify documentation templates
- Add custom sections
- Adjust file exclusion patterns
- Customize output formatting

#### Project-Specific Instructions

Add to your `CLAUDE.md`:
```markdown
## Documentation
- Check `.cogent/[filepath].md` for existing documentation before editing
- Generated docs provide context for architectural decisions
- Update documentation templates in `.cogent/create-documentation.sh` if needed
```

## 📁 Project Structure

```
your-project/
├── .claude/
│   └── settings.json          # Hook configuration
├── .cogent/
│   ├── create-documentation.sh # Documentation generator script
│   ├── config.json            # User preferences
│   └── [your-project-structure-mirrored]/
│       └── *.md               # Generated documentation files
├── src/
│   └── components/
│       └── MyComponent.tsx    # Your actual code
```

## 🎯 Use Cases

### For Individual Developers
- **Code Reviews**: Reviewers understand context immediately
- **Future Self**: Remember why you made specific decisions
- **Debugging**: Quickly understand complex codebases
- **Learning**: Document patterns as you implement them

### For Teams
- **Onboarding**: New developers get comprehensive context
- **Knowledge Sharing**: Architectural decisions are preserved
- **Code Handoffs**: Complete context transfers automatically
- **Technical Debt**: Document known issues and improvement plans

### For Projects
- **API Documentation**: Always up-to-date interface docs
- **Architecture Documentation**: Living system documentation
- **Compliance**: Automated security and performance documentation
- **Maintenance**: Clear upgrade and modification guidelines

## 🔧 Commands

### Installation Commands
```bash
./install.sh --help     # Show help information
./install.sh --version  # Display version
./install.sh            # Run installation
./install.sh --uninstall # Remove from project
```

### File Operations
```bash
# Documentation is generated automatically, but you can:
ls .cogent/              # View all generated docs
find .cogent/ -name "*.md" | head -10  # Find recent docs
grep -r "security" .cogent/  # Search across documentation
```

## 🚫 File Exclusions

By default, these files are **not** documented:
- Configuration files (`.json`, `.yml`, `.toml`)
- Documentation files (`.md`)
- Build artifacts (`dist/`, `node_modules/`, `__pycache__/`)
- Hidden directories (`.git/`, `.cogent/`, `.claude/`)

Customize exclusions in the interactive setup or by editing the hook script.

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Report Issues**: Found a bug or have a feature request? [Open an issue](https://github.com/yourusername/cogent-autodoc/issues)
2. **Improve Templates**: Submit better documentation templates for specific languages/frameworks
3. **Add Language Support**: Extend file type detection and templates
4. **Testing**: Help test across different environments and project types

### Development Setup

```bash
git clone https://github.com/yourusername/cogent-autodoc.git
cd cogent-autodoc
# Test the installer
./install.sh --help
# Run in a test project
cd /path/to/test/project
/path/to/cogent-autodoc/install.sh
```

## 📚 Examples

### React Component Documentation

Input file: `src/components/UserProfile.tsx`
```typescript
interface UserProfileProps {
  userId: string;
  onUpdate: (user: User) => void;
}

const UserProfile: React.FC<UserProfileProps> = ({ userId, onUpdate }) => {
  // Component implementation...
};
```

Generated documentation includes:
- Component purpose and UI responsibilities
- Props interface with detailed parameter descriptions
- Usage examples with different prop combinations
- Integration patterns with state management
- Performance considerations for re-renders
- Accessibility implementation notes

### Python Class Documentation

Input file: `src/services/database.py`
```python
class DatabaseManager:
    def __init__(self, connection_string: str):
        self.connection = create_connection(connection_string)
    
    def execute_query(self, query: str, params: dict) -> List[dict]:
        # Implementation...
```

Generated documentation includes:
- Class architecture and design patterns
- Method signatures with parameter and return types
- Error handling and exception scenarios
- Connection management and resource cleanup
- Performance optimization strategies
- Security considerations for SQL injection prevention

## 🔍 Troubleshooting

### Common Issues

**Hook not triggering?**
- Check `.claude/settings.json` syntax
- Verify `.cogent/create-documentation.sh` has execute permissions
- Ensure Claude Code is properly configured

**Documentation quality issues?**
- Larger files generate better context
- Add descriptive variable names and function signatures
- Consider adding a brief comment explaining complex business logic

**Installation fails?**
- Check internet connectivity for script download
- Verify write permissions in project directory
- Ensure required tools (curl/wget, grep, sed) are available

### Getting Help

- 📖 **Documentation**: Check the generated docs in `.cogent/`
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/cogent-autodoc/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/cogent-autodoc/discussions)
- 📧 **Email**: [your-email@example.com](mailto:your-email@example.com)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Built for the [Claude Code](https://claude.ai/code) ecosystem
- Inspired by the need for living, intelligent documentation
- Thanks to all contributors and early adopters

---

**Ready to transform your development workflow?**

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/cogent-autodoc/main/install.sh | bash
```

*Start generating intelligent documentation in under 30 seconds.*
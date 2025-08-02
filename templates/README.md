# Documentation Template: Default

This is the default documentation template used by Cogent AutoDoc. You can customize this template by modifying the `create_documentation_template()` function in `scripts/create-documentation.sh`.

## Template Variables

The following variables are automatically replaced when generating documentation:

- `{{FILENAME}}` - The filename of the documented file
- `{{FILE_TYPE}}` - The detected file type (e.g., "TypeScript", "Python")
- `{{TIMESTAMP}}` - UTC timestamp when documentation was generated
- `{{FILE_PATH}}` - Full path to the documented file
- `{{LANGUAGE}}` - Language identifier for code blocks

## Template Structure

Each generated documentation file includes these sections:

1. **File Overview** - High-level purpose and functionality
2. **Intent** - Why the file exists and what problems it solves
3. **Project Integration** - How it fits into the larger system
4. **Recent Changes** - What was modified in the latest edit
5. **Key Components** - Classes, functions, and important variables
6. **Dependencies** - Internal and external dependencies
7. **Usage Examples** - Basic and advanced usage patterns
8. **API Documentation** - Complete interface documentation
9. **Testing** - Testing approach and considerations
10. **Error Handling** - Error patterns and recovery strategies
11. **Performance Considerations** - Optimizations and bottlenecks
12. **Security Considerations** - Security implications and patterns
13. **Notes** - Additional important information

## Customizing Templates

To create project-specific templates:

1. Copy this template file
2. Modify the sections and prompts
3. Update the `create_documentation_template()` function
4. Test with sample files

## Language-Specific Templates

Future versions will support language-specific templates:

- `react.md` - React component template
- `python.md` - Python module template
- `rust.md` - Rust crate template
- `api.md` - API endpoint template

## AI Prompt Guidelines

The `[AI: ...]` placeholders are designed to:

- Provide specific, actionable instructions to Claude
- Request comprehensive but concise information
- Focus on practical, useful documentation
- Encourage examples and real-world usage patterns

## Contributing Templates

To contribute new templates:

1. Create a template file in this directory
2. Test it with various file types
3. Submit a pull request with examples
4. Include documentation on when to use the template
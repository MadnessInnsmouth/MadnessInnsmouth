# Contributing to FM26 Accessibility Mod

Thank you for your interest in contributing to making Football Manager 2026 accessible! This guide will help you get started.

## Ways to Contribute

### 🐛 Report Bugs
Found a problem? [Open an issue](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues/new) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (Windows version, screen reader, FM26 version)
- BepInEx log file (if applicable)

### 💡 Suggest Features
Have an idea? [Open an issue](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues/new) with:
- Clear description of the feature
- Why it would be useful
- How it might work
- Any examples from other games/apps

### 📝 Improve Documentation
Documentation improvements are always welcome:
- Fix typos or unclear instructions
- Add examples
- Translate to other languages
- Improve installation guides

### 💻 Write Code
Contributions to the codebase are highly valued:
- Fix bugs
- Implement new features
- Improve performance
- Add tests

### 🧪 Test
Help test the mod:
- Try new features
- Test on different configurations
- Verify bug fixes
- Test with different screen readers

## Getting Started

### Prerequisites

- Git
- Visual Studio 2019+ or Visual Studio Code with C# extension
- .NET Framework 4.8 SDK
- Football Manager 2026 (for testing)
- A screen reader (NVDA recommended for testing)

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/MadnessInnsmouth.git
   cd MadnessInnsmouth
   ```

2. **Setup Dependencies**
   ```bash
   # Run the build script which downloads required libraries
   cd build
   ./build.ps1
   ```

3. **Open in IDE**
   - Visual Studio: Open `src/FM26AccessibilityPlugin/FM26AccessibilityPlugin.csproj`
   - VS Code: Open the root folder

### Building

```bash
# Using the build script (recommended)
./build/build.ps1

# Or using dotnet CLI directly
dotnet build src/FM26AccessibilityPlugin/FM26AccessibilityPlugin.csproj --configuration Release
```

### Testing Your Changes

1. **Build the plugin**
2. **Copy to FM26**: 
   ```powershell
   Copy-Item "src/FM26AccessibilityPlugin/bin/Release/net48/FM26AccessibilityPlugin.dll" `
             "C:\Path\To\FM26\BepInEx\plugins\" -Force
   ```
3. **Launch FM26** and test
4. **Check logs**: `C:\Path\To\FM26\BepInEx\LogOutput.log`

### Debugging

**Using Visual Studio:**
1. Set FM26 as the external program to launch
2. Set breakpoints in your code
3. Press F5 to start debugging
4. Visual Studio will attach when the plugin loads

**Using Logs:**
```csharp
AccessibilityPlugin.Log("Debug message");
AccessibilityPlugin.LogWarning("Warning message");
AccessibilityPlugin.LogError("Error message");
```

## Code Standards

### Style Guide

- **Indentation**: 4 spaces (no tabs)
- **Braces**: Opening brace on same line
- **Naming**:
  - Classes: `PascalCase`
  - Methods: `PascalCase`
  - Fields: `camelCase`
  - Constants: `UPPER_CASE`
  - Private fields: `camelCase` or `_camelCase`

### Example

```csharp
public class MyAccessibilityFeature : MonoBehaviour
{
    private const int DEFAULT_TIMEOUT = 5000;
    private string currentElement;
    
    public void Initialize(string startingElement)
    {
        currentElement = startingElement;
        ProcessElement();
    }
    
    private void ProcessElement()
    {
        if (string.IsNullOrEmpty(currentElement))
        {
            AccessibilityPlugin.LogWarning("No element to process");
            return;
        }
        
        // Implementation
    }
}
```

### Code Organization

- **One class per file** (exceptions: small helper classes)
- **Logical grouping**: Related functionality should be together
- **Comments**: Explain WHY, not WHAT
- **XML docs**: For public APIs

```csharp
/// <summary>
/// Announces a UI element to the screen reader.
/// </summary>
/// <param name="element">The GameObject to announce</param>
/// <param name="interrupt">Whether to interrupt current speech</param>
public void AnnounceElement(GameObject element, bool interrupt = true)
{
    // Implementation
}
```

## Pull Request Process

### Before Submitting

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/my-awesome-feature
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes**
   - Write clear, focused commits
   - Follow the code style guide
   - Add comments where needed
   - Test your changes

3. **Test thoroughly**
   - Build succeeds
   - Plugin loads without errors
   - Feature works as expected
   - No new bugs introduced

4. **Update documentation** if needed
   - Update README.md
   - Add to TECHNICAL.md if relevant
   - Update CHANGELOG.md

### Submitting

1. **Push your branch**
   ```bash
   git push origin feature/my-awesome-feature
   ```

2. **Open a Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing Done
- [ ] Tested on Windows 10/11
- [ ] Tested with NVDA
- [ ] Tested with JAWS
- [ ] Tested with Narrator
- [ ] No errors in BepInEx log

## Screenshots/Logs
(if applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. **Automated checks** will run (build, linting)
2. **Maintainers will review** your code
3. **Address feedback** if any
4. **Merge** once approved

## Commit Message Guidelines

### Format

```
type(scope): Short description

Longer description if needed.
Can be multiple lines.

Closes #123
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Build process, tools, etc.

### Examples

```
feat(ui): Add support for dropdown menus

Adds detection and announcement of Unity Dropdown components.
Includes role announcement and current selected value.

Closes #42
```

```
fix(speech): Fix race condition in speech queue

Previous implementation could skip announcements if multiple
elements were focused rapidly. Now uses a proper queue.

Fixes #38
```

## Community Guidelines

### Be Respectful

- Be kind and considerate
- Respect different viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community

### Be Patient

- Reviewers are volunteers
- Complex features take time to review
- Response time varies

### Ask for Help

- Don't hesitate to ask questions
- Use GitHub Discussions for general questions
- Use Issues for bug reports and feature requests

## Recognition

All contributors will be:
- Listed in the project README
- Credited in release notes
- Appreciated by the community! 🎉

## Getting Help

- **Questions**: [GitHub Discussions](https://github.com/MadnessInnsmouth/MadnessInnsmouth/discussions)
- **Bugs**: [GitHub Issues](https://github.com/MadnessInnsmouth/MadnessInnsmouth/issues)
- **Security**: Email security concerns privately (see SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to making gaming more accessible! 🎮♿

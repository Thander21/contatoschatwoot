# Contributing to Chatwoot Contact Manager

First off, thank you for considering contributing to Chatwoot Contact Manager! 🎉

It's people like you that make this tool better for everyone in the Chatwoot community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by our commitment to:

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Collaborative**: Work together constructively
- **Be Professional**: Keep discussions focused and productive
- **Be Inclusive**: Welcome people of all backgrounds and experience levels

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.5.3+
- [Git](https://git-scm.com/downloads)
- A code editor ([VS Code](https://code.visualstudio.com/) recommended with Flutter extension)
- A Chatwoot account for testing

### Fork & Clone

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/contatoschatwoot.git
   cd contatoschatwoot
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/original-owner/contatoschatwoot.git
   ```

### Install Dependencies

```bash
flutter pub get
```

### Verify Setup

```bash
flutter analyze
flutter doctor
```

---

## 🤝 How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When reporting bugs, use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- **Clear title**: Brief, descriptive summary
- **Steps to reproduce**: Detailed steps to recreate the issue
- **Expected vs actual behavior**: What should happen vs what does happen
- **Environment details**: OS, Flutter version, app version
- **Screenshots/logs**: Visual evidence or error logs
- **Minimal test case**: Simplest code that demonstrates the issue

### 💡 Suggesting Features

We love feature suggestions! Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

Good feature requests include:

- **Problem statement**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Use case**: Real-world scenario
- **Alternatives considered**: Other approaches you thought of
- **Mockups/examples**: Visual representation if applicable

### 📝 Improving Documentation

Documentation improvements are always welcome:

- Fix typos or clarify unclear sections
- Add examples or use cases
- Translate to other languages
- Add screenshots or diagrams
- Update outdated information

### 💻 Contributing Code

Looking for a place to start? Check issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `bug` - Something isn't working
- `enhancement` - New feature or request

---

## 🛠️ Development Setup

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── contact_management_routes.dart
├── models/                      # Data models
├── services/                    # Business logic
└── screens/                     # UI screens
```

### Running the App

```bash
# Development mode with hot reload
flutter run -d windows  # or linux/macos

# With verbose logging
flutter run -d windows -v
```

### Code Organization

- **Models**: Data structures in `lib/models/`
- **Services**: Business logic in `lib/services/`
- **Screens**: UI components in `lib/screens/`
- **Routes**: Navigation in `contact_management_routes.dart`

---

## 📐 Coding Standards

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// ✅ Good
class ContactService {
  Future<List<Contact>> fetchContacts() async {
    // Implementation
  }
}

// ❌ Bad
class contactService {
  Future<List<Contact>> FetchContacts() async {
    // Implementation
  }
}
```

### Code Formatting

Run before committing:

```bash
dart format lib/
```

### Linting

Ensure no warnings:

```bash
flutter analyze
```

### Best Practices

#### Null Safety

Always handle null cases:

```dart
// ✅ Good
final email = contact.email ?? 'no-email@example.com';

// ❌ Bad
final email = contact.email!; // Can crash
```

#### Async/Await

Use async/await for asynchronous operations:

```dart
// ✅ Good
Future<void> loadContacts() async {
  try {
    final contacts = await _service.fetchContacts();
    setState(() => _contacts = contacts);
  } catch (e) {
    _logger.severe('Error loading contacts', e);
  }
}

// ❌ Bad
void loadContacts() {
  _service.fetchContacts().then((contacts) {
    setState(() => _contacts = contacts);
  }).catchError((e) {
    print(e);
  });
}
```

#### Error Handling

Always use try-catch with logging:

```dart
// ✅ Good
try {
  await _service.updateContact(contact);
  _showSuccess('Contact updated');
} catch (e) {
  _logger.severe('Failed to update contact', e);
  _showError('Update failed: $e');
}

// ❌ Bad
await _service.updateContact(contact);
```

#### Logging

Use package:logging instead of print:

```dart
// ✅ Good
final _logger = Logger('MyService');
_logger.info('Operation started');
_logger.severe('Error occurred', error, stackTrace);

// ❌ Bad
print('Operation started');
print('Error: $error');
```

#### Comments

Write self-documenting code, use comments for complex logic:

```dart
// ✅ Good
/// Calculates completeness score based on filled fields
/// Returns value from 0.0 (empty) to 1.0 (complete)
double calculateCompleteness(Contact contact) {
  // Implementation
}

// ❌ Bad
// This function does something
double calc(Contact c) {
  // Implementation
}
```

---

## 📝 Commit Guidelines

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Feature
git commit -m "feat(phone): add validation for international numbers"

# Bug fix
git commit -m "fix(dashboard): resolve crash when no contacts loaded"

# Documentation
git commit -m "docs(readme): add installation instructions for macOS"

# Refactor
git commit -m "refactor(cache): simplify cache invalidation logic"
```

### Good Commit Messages

```
✅ feat(auth): add session-based credential storage

- Store credentials in memory only
- Clear credentials on app exit
- Add validation for URL and token
- Update documentation

Closes #123
```

```
❌ updated stuff
```

---

## 🔄 Pull Request Process

### Before Submitting

1. **Update your fork**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Write code
   - Add tests
   - Update documentation
   - Run tests and linting

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

### Creating the PR

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill out the PR template completely
5. Link related issues
6. Request review

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] Self-reviewed the code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] No new warnings from `flutter analyze`
- [ ] Added/updated tests
- [ ] All tests pass locally
- [ ] Linked related issues

### Review Process

1. **Automated checks**: CI/CD runs tests and linting
2. **Code review**: Maintainers review your code
3. **Feedback**: Address review comments
4. **Approval**: At least one maintainer approves
5. **Merge**: Maintainer merges your PR

### After Merge

1. **Delete your branch**:
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

2. **Update your main branch**:
   ```bash
   git checkout main
   git pull upstream main
   ```

---

## 🧪 Testing Guidelines

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/contacts_service_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

Create test files in `test/` directory:

```dart
// test/services/phone_formatter_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:contatoschatwoot/services/phone_formatter_service.dart';

void main() {
  group('PhoneFormatterService', () {
    late PhoneFormatterService service;

    setUp(() {
      service = PhoneFormatterService();
    });

    test('adds country code to phone without it', () {
      final result = service.formatPhone('11987654321');
      expect(result, '+5511987654321');
    });

    test('validates Brazilian DDD', () {
      expect(service.isValidDDD(11), true);
      expect(service.isValidDDD(99), false);
    });
  });
}
```

### Test Coverage

Aim for:

- **Services**: 80%+ coverage
- **Models**: 90%+ coverage
- **Critical paths**: 100% coverage

---

## 🎨 UI/UX Guidelines

### Material Design

Follow Material Design 3 principles:

- Use Material components
- Consistent spacing (8px grid)
- Proper color contrast
- Accessibility considerations

### Responsive Design

Test on different screen sizes:

- Minimum: 800x600
- Recommended: 1024x768
- Large: 1920x1080

### User Feedback

Always provide feedback for user actions:

```dart
// ✅ Good
Future<void> saveContact() async {
  setState(() => _isLoading = true);
  try {
    await _service.save(contact);
    _showSnackbar('Contact saved successfully', success: true);
  } catch (e) {
    _showSnackbar('Failed to save: $e', success: false);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## 🔒 Security Considerations

### Never Commit

- API tokens or credentials
- Personal data or test accounts
- .env files with secrets

### Sensitive Data

- Validate all user input
- Sanitize data before API calls
- Use secure storage for credentials (in-memory only)

### Code Review Focus

- SQL injection risks
- XSS vulnerabilities
- Improper error handling exposing internals

---

## 📚 Additional Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [Chatwoot API Docs](https://www.chatwoot.com/docs/product/channels/api/client-apis)

### Tools

- [DartPad](https://dartpad.dev/) - Online Dart editor
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview) - Debugging tools
- [VS Code Extensions](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) - Flutter extension

---

## 🎯 Priority Areas

We especially welcome contributions in these areas:

1. **Testing**: Add unit and integration tests
2. **Internationalization**: Add support for multiple languages
3. **Performance**: Optimize large contact list handling
4. **Mobile**: Create iOS/Android version
5. **Documentation**: Improve guides and examples

---

## ❓ Questions?

- **General questions**: Open a [Discussion](https://github.com/yourusername/contatoschatwoot/discussions)
- **Bug reports**: Create an [Issue](https://github.com/yourusername/contatoschatwoot/issues)
- **Security concerns**: Email directly (see SECURITY.md)

---

## 🙏 Thank You!

Your contributions, no matter how small, make this project better for everyone. We appreciate your time and effort!

Happy coding! 🚀

---

<div align="center">

**Made with ❤️ by the Community**

[⬆ Back to Top](#contributing-to-chatwoot-contact-manager)

</div>

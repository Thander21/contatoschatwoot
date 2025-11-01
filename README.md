# 📞 Chatwoot Contact Manager

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.3+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5.3+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-2.2-blue)

**A professional desktop application for comprehensive Chatwoot contact management**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🎯 About

Chatwoot Contact Manager is a powerful Flutter desktop application designed to help Chatwoot users maintain clean, organized contact databases. It provides intelligent tools for data validation, deduplication, formatting, and bulk operations - all with a focus on Brazilian phone number standards.

### Why This App?

- **🔒 Secure**: No hardcoded credentials - session-based authentication
- **🚀 Fast**: Smart caching eliminates redundant API calls
- **🇧🇷 Brazilian-Focused**: Complete validation for Brazilian phone numbers (81 DDDs)
- **🔄 Intelligent**: Smart duplicate detection with completeness scoring
- **📊 Analytics**: Real-time dashboard with data quality metrics
- **💾 Safe**: Excel backup before any destructive operations

---

## ✨ Features

### 🏠 Dashboard & Analytics
- Real-time statistics of your contact database
- Data quality metrics at a glance
- Quick access to all management tools
- No auto-loading - instant startup

### 📱 Phone Number Management
- **Format Correction**: Add country codes (+55), remove old formats, normalize DDDs
- **Brazilian Validation**: Validates against all 81 Brazilian state DDDs
- **Invalid Detection**: Identifies and explains invalid phone numbers
- **Batch Operations**: Process hundreds of contacts at once

### 👥 Duplicate Management
- **Smart Detection**: Groups contacts by normalized phone numbers
- **Intelligent Scoring**: Keeps the most complete and recent contact
- **Safe Merging**: Automatically preserves best information from duplicates
- **Bulk Processing**: Select and process multiple duplicate groups

### 🏢 Company Management
- **Pattern Detection**: Recognizes 4 company name patterns
- **Auto-Suggestions**: Extracts company from email domains
- **Manual Editing**: Full control over company assignments
- **Smart Filtering**: 3-way filter (all, suggested, in-name)

### 💾 Backup & Export
- **Excel Export**: Complete contact data with timestamps
- **Automatic Naming**: Timestamped files prevent overwrites
- **Full Data**: ID, Name, Email, Phone, Company, dates

### 🔐 Security & Privacy
- **No Hardcoded Credentials**: You provide your own API credentials
- **Session-Only Storage**: Credentials stored in memory, cleared on exit
- **Secure Dialog**: Password-style token input with visibility toggle
- **Auto-Cleanup**: Credentials automatically wiped when app closes

---

## 📋 Requirements

### System Requirements
- **OS**: Windows 10+, macOS 10.14+, or Ubuntu 20.04+
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 200MB free space

### Software Requirements
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.5.3 or higher
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Platform-specific build tools:
  - **Windows**: Visual Studio 2022 with C++ Desktop Development
  - **macOS**: Xcode 13 or higher
  - **Linux**: GCC, CMake, GTK development libraries

### Chatwoot Requirements
- Active Chatwoot account (self-hosted or cloud)
- API Access Token (get from: Settings → Profile → API Access)
- Account ID (usually `1` for single-account instances)

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/contatoschatwoot.git
cd contatoschatwoot
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor
```

Ensure all checkmarks are green for your target platform.

### 4. Run the Application

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

## 🔧 Configuration

### First-Time Setup

1. **Launch the application**
   ```bash
   flutter run -d windows  # or macos/linux
   ```

2. **Click the refresh button (⟳)** on the dashboard

3. **Enter your Chatwoot credentials** when prompted:
   - **API URL**: Your Chatwoot instance URL (e.g., `https://app.chatwoot.com` or `https://chat.yourdomain.com`)
   - **API Token**: Your personal access token from Chatwoot

4. **Start managing contacts!**

### Getting Your API Token

1. Log into your Chatwoot account
2. Navigate to **Settings** → **Profile**
3. Scroll to **API Access** section
4. Copy your **Access Token**

> **🔒 Security Note**: Your credentials are stored only in memory during the session. When you close the app, they are automatically cleared. You'll need to re-enter them next time you launch.

---

## 📖 Usage

### Basic Workflow

```
1. Launch App → Dashboard appears (empty, no auto-load)
2. Click ⟳ Refresh → Enter credentials if first time
3. View Statistics → Identify data quality issues
4. Select Feature → Choose the operation you need
5. Batch Select → Check contacts to process
6. Execute → Process with progress feedback
7. Review Results → Check success/error counts
```

### Feature Guides

#### 📱 Format Phone Numbers

**Use Case**: Add country codes, fix old formats, normalize Brazilian numbers

1. Click **"Corrigir Telefones"** from dashboard
2. Review contacts with formatting issues
3. Use filters to select specific problem types:
   - Without +55
   - Old format (leading 0)
   - Missing DDD
   - Missing 9th digit
4. Select contacts (individually or "Selecionar Todos")
5. Click **"Formatar Selecionados"**
6. Confirm and wait for completion

> **Note**: Only valid phone numbers appear here. Invalid ones go to the separate "Invalid Phones" screen.

#### 🗑️ Remove Invalid Phones

**Use Case**: Clean up contacts with invalid Brazilian phone numbers

1. Click **"Telefones Inválidos"** from dashboard
2. Review contacts with invalid phones
3. See **specific reason** for each invalid number:
   - Invalid DDD (not in 81 valid codes)
   - Too short (< 10 digits)
   - Too long (> 11 digits)
   - Empty phone
4. Select contacts to delete
5. Click **"Excluir Selecionados"**
6. **Confirm** (this is irreversible!)

> **⚠️ Warning**: Make a backup first! This operation cannot be undone.

#### 👥 Remove Duplicates

**Use Case**: Merge contacts with duplicate phone numbers

1. Click **"Limpar Duplicados"** from dashboard
2. Review duplicate groups (grouped by phone)
3. See which contact will be kept (⭐ marked)
4. Select groups to process
5. Click **"Remover Duplicados Selecionados"**
6. System keeps the best contact automatically

**How "Best" Contact is Chosen**:
- ✅ Has country code (+55)
- ✅ Most complete (name, email, company, phone)
- ✅ Most recent update
- ✅ Highest completeness score

#### 🏢 Manage Companies

**Use Case**: Extract or add company information to contacts

1. Click **"Gerenciar Empresas"** from dashboard
2. Choose filter:
   - **Todos**: All without company
   - **Com sugestão**: Auto-detected from email/name
   - **Empresa no nome**: Has pattern like "Name - Company"
3. Review suggestions or edit manually
4. Select contacts to process
5. Click **"Salvar Empresas"**

**Supported Name Patterns**:
- `João Silva - Acme Corp` → Extracts "Acme Corp"
- `Maria (Tech Inc)` → Extracts "Tech Inc"
- `Pedro @ Startup XYZ` → Extracts "Startup XYZ"
- `Ana | Company Name` → Extracts "Company Name"

**Email Domain Extraction**:
- `contact@acmecorp.com` → Suggests "Acme Corp"
- `user@gmail.com` → Ignored (generic provider)

#### 💾 Create Backup

**Use Case**: Export all contacts to Excel before operations

1. Click **"Fazer Backup"** button (📦 icon)
2. Wait for export to complete
3. Find file in: `Documents/backup_contatos_[timestamp].xlsx`

**Exported Data**:
- Contact ID
- Name
- Email
- Phone Number
- Company
- Created Date (DD/MM/YYYY HH:MM)
- Updated Date (DD/MM/YYYY HH:MM)

---

## 🏗️ Architecture

### Design Patterns

- **Service Layer**: Business logic separated from UI
- **Singleton**: Cache service shared across app
- **Observer**: Automatic screen updates via listeners
- **Factory**: Flexible JSON parsing for API responses
- **Immutability**: Safe data updates with `copyWith()`

### Project Structure

```
lib/
├── main.dart                         # Entry point, lifecycle management
├── contact_management_routes.dart    # Named routes
├── models/
│   └── contact.dart                  # Contact data model
├── services/
│   ├── credentials_service.dart      # Secure credential management
│   ├── api_config.dart               # Dynamic API configuration
│   ├── contacts_cache_service.dart   # Singleton cache with listeners
│   ├── contacts_service.dart         # API client (CRUD, stats)
│   ├── phone_formatter_service.dart  # Phone validation & formatting
│   ├── company_service.dart          # Company extraction logic
│   ├── duplicates_service.dart       # Duplicate detection & merging
│   └── backup_service.dart           # Excel export
└── screens/
    ├── dashboard_screen.dart         # Main dashboard
    ├── auth_dialog.dart              # Authentication UI
    ├── contacts_list_screen.dart     # Full contact listing
    ├── phone_format_screen.dart      # Phone correction
    ├── invalid_phones_screen.dart    # Invalid phone detection
    ├── duplicate_contacts_screen.dart# Deduplication
    └── company_management_screen.dart# Company management
```

### Data Flow

```
User Action → Check Cache → API Call (if needed) → Update Cache → Notify Listeners → Update UI
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.5.3+ |
| Language | Dart 3.5.3+ |
| HTTP Client | `http` ^1.1.0 |
| Excel Export | `excel` ^4.0.6 |
| File System | `path_provider` ^2.1.1 |
| Window Manager | `window_manager` ^0.5.1 |
| Logging | `logging` ^1.2.0 |
| Date Format | `intl` ^0.20.2 |

---

## 🔐 Security & Privacy

### What We Store

**In Memory (During Session)**:
- ✅ API URL
- ✅ API Token
- ✅ Cached contacts

**On Disk (Never)**:
- ❌ Credentials
- ❌ API tokens
- ❌ Cached contacts

### How It Works

1. **Credential Input**: Validated before storage
2. **Session Storage**: Kept in RAM only
3. **Auto-Cleanup**: Cleared when app closes/pauses
4. **No Persistence**: Fresh credentials required each session

### Security Features

- 🔒 **No Hardcoded Secrets**: All credentials provided by user
- 🔒 **Memory-Only Storage**: Never written to disk
- 🔒 **Lifecycle Observers**: Auto-wipe on app exit/pause
- 🔒 **Input Validation**: URL and token verified
- 🔒 **Visibility Toggle**: Token hidden by default
- 🔒 **Safe for Version Control**: No secrets in code

### .gitignore Protection

The repository includes protections against accidentally committing:
- `.env` files
- Credential JSON files
- Backup Excel files with contact data

---

## 🇧🇷 Brazilian Phone Validation

### Supported DDDs (81 Total)

The app validates against all official Brazilian area codes:

| Region | DDDs |
|--------|------|
| **São Paulo** | 11, 12, 13, 14, 15, 16, 17, 18, 19 |
| **Rio de Janeiro** | 21, 22, 24 |
| **Espírito Santo** | 27, 28 |
| **Minas Gerais** | 31, 32, 33, 34, 35, 37, 38 |
| **Paraná** | 41, 42, 43, 44, 45, 46 |
| **Santa Catarina** | 47, 48, 49 |
| **Rio Grande do Sul** | 51, 53, 54, 55 |
| **Distrito Federal** | 61 |
| **Goiás** | 62, 64 |
| **Tocantins** | 63 |
| **Mato Grosso** | 65, 66 |
| **Mato Grosso do Sul** | 67 |
| **Acre** | 68 |
| **Rondônia** | 69 |
| **Bahia** | 71, 73, 74, 75, 77 |
| **Sergipe** | 79 |
| **Pernambuco** | 81, 87 |
| **Alagoas** | 82 |
| **Paraíba** | 83 |
| **Rio Grande do Norte** | 84 |
| **Ceará** | 85, 88 |
| **Piauí** | 86, 89 |
| **Pará** | 91, 93, 94 |
| **Amazonas** | 92, 97 |
| **Roraima** | 95 |
| **Amapá** | 96 |
| **Maranhão** | 98, 99 |

### Validation Rules

**Valid Format**: `+55 [DDD] [8-9 digits]`

Examples:
- ✅ `+5511987654321` (São Paulo mobile)
- ✅ `+552134567890` (Rio de Janeiro landline)
- ❌ `5511987654321` (missing +)
- ❌ `+5599987654321` (invalid DDD 99 for mobile)
- ❌ `+55119876543` (too short)

---

## 📊 Statistics & Metrics

The dashboard tracks these data quality metrics:

| Metric | Description |
|--------|-------------|
| **Total Contacts** | Total count in database |
| **Without Country Code** | Missing +55 prefix |
| **Duplicate Groups** | Contacts sharing phone numbers |
| **Without Company** | Empty company field |
| **Invalid Phone** | Wrong DDD, length, or format |
| **Invalid Email** | Failed regex validation |
| **Without Name** | Empty name field |

---

## 🛠️ Development

### Building from Source

```bash
# Clone
git clone https://github.com/yourusername/contatoschatwoot.git
cd contatoschatwoot

# Install dependencies
flutter pub get

# Run tests (when available)
flutter test

# Build for production
flutter build windows --release  # or macos/linux

# Output location
build/windows/runner/Release/contatoschatwoot.exe
```

### Code Analysis

```bash
# Check for issues
flutter analyze

# Format code
dart format lib/
```

### Logging

The app uses structured logging via `package:logging`. All logs appear in the console during development:

```dart
Logger.root.level = Level.ALL;  // See all logs
Logger.root.level = Level.INFO;  // Production level
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Contribution Guidelines

- Follow Dart style guide
- Add tests for new features
- Update documentation
- Keep commits atomic and descriptive
- Ensure `flutter analyze` passes

### Areas for Improvement

- [ ] Add unit tests for services
- [ ] Implement undo/redo functionality
- [ ] Add multi-language support (i18n)
- [ ] Create mobile version (iOS/Android)
- [ ] Add dark mode toggle
- [ ] Implement persistent cache (SQLite)
- [ ] Add custom validation rules
- [ ] Create comprehensive test suite

---

## 📝 Changelog

### Version 2.2 (Current) - Secure Authentication
- 🔐 Removed all hardcoded credentials
- 🖥️ Added authentication dialog with validation
- 👁️ Token field with visibility toggle
- 💾 Session-based credential storage
- 🔒 Auto-cleanup on app exit
- 📝 Updated documentation

### Version 2.1 - Brazilian Phone Validation
- 📱 Added invalid phones screen
- ✅ Validation for 81 Brazilian DDDs
- 📊 Detailed invalidation reasons
- 🗑️ Bulk deletion with confirmation

### Version 2.0 - Cache System
- ⚡ Singleton cache service
- 🔄 Observer pattern listeners
- 📈 Eliminated redundant API calls
- 🎯 No auto-loading on startup

### Version 1.0 - Initial Release
- 📊 Dashboard with statistics
- 📱 Phone formatting
- 👥 Duplicate detection
- 🏢 Company management
- 💾 Excel export

---

## ⚠️ Known Limitations

1. **Credentials**: Must re-enter each session (security by design)
2. **Cache**: Lost on app restart (use backup for persistence)
3. **Undo**: No transaction rollback (make backups!)
4. **Account ID**: Hardcoded to '1' (most installations)
5. **Network**: Requires internet for API operations

---

## 🐛 Troubleshooting

### App won't start
- Ensure Flutter SDK is installed: `flutter doctor`
- Check platform-specific build tools
- Try: `flutter clean && flutter pub get`

### Can't connect to API
- Verify URL format: `https://your-domain.com` (no /api/v1)
- Check token is correct (from Chatwoot Settings → Profile)
- Ensure Chatwoot instance is accessible
- Check firewall/network settings

### Credentials keep asking
- Expected behavior (security feature)
- Credentials cleared on each app restart
- Consider this a feature, not a bug

### Export fails
- Check write permissions to Documents folder
- Ensure sufficient disk space
- Verify no file is already open in Excel

### Phone validation issues
- Only Brazilian numbers supported
- Ensure DDD is valid (check table above)
- Format must be +55 [DDD] [8-9 digits]

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Chatwoot Contact Manager Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Chatwoot** - For the excellent open-source CRM platform
- **Brazilian Developers** - For feedback on DDD validation
- **Open Source Community** - For inspiration and support

---

## 📞 Support & Contact

### Get Help

- 📖 [Read the Documentation](#-documentation)
- 🐛 [Report a Bug](https://github.com/yourusername/contatoschatwoot/issues/new?template=bug_report.md)
- 💡 [Request a Feature](https://github.com/yourusername/contatoschatwoot/issues/new?template=feature_request.md)
- 💬 [Chatwoot Community](https://chatwoot.com/community)

### Resources

- [Chatwoot API Documentation](https://www.chatwoot.com/docs/product/channels/api/client-apis)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)

---

## ⭐ Show Your Support

If this project helped you, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs
- 💡 Suggesting features
- 🤝 Contributing code
- 📢 Sharing with others

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ Back to Top](#-chatwoot-contact-manager)

</div>

import 'package:logging/logging.dart';
import '../models/contact.dart';

/// Serviço para gerenciamento de empresas e renomeação de contatos
class CompanyService {
  final _logger = Logger('CompanyService');

  /// Padrões comuns de empresa no nome
  static final _companyPatterns = [
    RegExp(r'\s+-\s+(.+)$'), // "Nome - Empresa"
    RegExp(r'\s+\((.+)\)$'), // "Nome (Empresa)"
    RegExp(r'\s+@\s+(.+)$'), // "Nome @ Empresa"
    RegExp(r'\s+\|\s+(.+)$'), // "Nome | Empresa"
  ];

  /// Extrai o nome da empresa do nome do contato
  String? extractCompanyFromName(String fullName) {
    for (var pattern in _companyPatterns) {
      final match = pattern.firstMatch(fullName);
      if (match != null && match.groupCount > 0) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extrai apenas o nome limpo (sem empresa)
  String extractCleanName(String fullName) {
    for (var pattern in _companyPatterns) {
      final match = pattern.firstMatch(fullName);
      if (match != null) {
        return fullName.substring(0, match.start).trim();
      }
    }
    return fullName.trim();
  }

  /// Formata nome no padrão "Nome - Empresa"
  String formatNameWithCompany(String name, String company) {
    final cleanName = extractCleanName(name);
    return '$cleanName - $company';
  }

  /// Verifica se o nome já tem empresa formatada
  bool hasCompanyInName(String name) {
    return _companyPatterns.any((pattern) => pattern.hasMatch(name));
  }

  /// Processa um contato para extrair e preencher empresa
  Contact processContactCompany(Contact contact) {
    // Se já tem empresa no campo, mantém
    if (contact.hasCompany) {
      return contact;
    }

    // Tenta extrair do nome
    final extractedCompany = extractCompanyFromName(contact.name);
    if (extractedCompany != null) {
      return contact.copyWith(
        company: extractedCompany,
        customAttributes: {
          ...?contact.customAttributes,
          'company_extracted': true,
          'company_extracted_at': DateTime.now().toIso8601String(),
        },
      );
    }

    return contact;
  }

  /// Renomeia um contato adicionando empresa ao nome
  Contact renameContactWithCompany(Contact contact, String company) {
    final newName = formatNameWithCompany(contact.name, company);

    return contact.copyWith(
      name: newName,
      company: company,
      customAttributes: {
        ...?contact.customAttributes,
        'company_added': true,
        'company_added_at': DateTime.now().toIso8601String(),
        'original_name': contact.name,
      },
    );
  }

  /// Filtra contatos sem empresa
  List<Contact> getContactsWithoutCompany(List<Contact> contacts) {
    return contacts.where((contact) => !contact.hasCompany).toList();
  }

  /// Filtra contatos com empresa no nome mas não no campo
  List<Contact> getContactsWithCompanyInName(List<Contact> contacts) {
    return contacts.where((contact) {
      final hasInName = hasCompanyInName(contact.name);
      return hasInName && !contact.hasCompany;
    }).toList();
  }

  /// Agrupa contatos por empresa
  Map<String, List<Contact>> groupByCompany(List<Contact> contacts) {
    final grouped = <String, List<Contact>>{};

    for (var contact in contacts) {
      final company = contact.company ?? 'Sem empresa';
      grouped.putIfAbsent(company, () => []).add(contact);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
  }

  /// Sugere empresa baseado em padrões comuns
  String? suggestCompany(Contact contact) {
    // Tenta extrair do nome
    final fromName = extractCompanyFromName(contact.name);
    if (fromName != null) return fromName;

    // Tenta extrair do email (domínio)
    if (contact.email != null && contact.email!.contains('@')) {
      final domain = contact.email!.split('@').last;
      final companyName = domain.split('.').first;

      // Ignora emails genéricos
      if (!['gmail', 'hotmail', 'outlook', 'yahoo'].contains(companyName.toLowerCase())) {
        return _capitalizeCompany(companyName);
      }
    }

    return null;
  }

  /// Capitaliza nome da empresa
  String _capitalizeCompany(String company) {
    return company
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Obtém estatísticas de empresas
  Map<String, dynamic> getCompanyStatistics(List<Contact> contacts) {
    final withCompany = contacts.where((c) => c.hasCompany).length;
    final withoutCompany = contacts.length - withCompany;
    final withCompanyInName = getContactsWithCompanyInName(contacts).length;
    final companies = groupByCompany(contacts);

    return {
      'total': contacts.length,
      'withCompany': withCompany,
      'withoutCompany': withoutCompany,
      'withCompanyInName': withCompanyInName,
      'uniqueCompanies': companies.length - 1, // -1 para remover "Sem empresa"
      'topCompanies': companies.entries
          .where((e) => e.key != 'Sem empresa')
          .take(10)
          .map((e) => {'name': e.key, 'count': e.value.length})
          .toList(),
    };
  }

  /// Identifica tipo de problema relacionado a empresa
  CompanyIssueType identifyCompanyIssue(Contact contact) {
    if (contact.hasCompany) return CompanyIssueType.valid;
    if (hasCompanyInName(contact.name)) return CompanyIssueType.inNameOnly;

    final suggested = suggestCompany(contact);
    if (suggested != null) return CompanyIssueType.canSuggest;

    return CompanyIssueType.missing;
  }

  /// Obtém descrição do tipo de problema
  String getIssueDescription(CompanyIssueType type) {
    switch (type) {
      case CompanyIssueType.missing:
        return 'Empresa não encontrada';
      case CompanyIssueType.inNameOnly:
        return 'Empresa apenas no nome';
      case CompanyIssueType.canSuggest:
        return 'Empresa pode ser sugerida';
      case CompanyIssueType.valid:
        return 'Empresa definida';
    }
  }
}

/// Tipos de problemas relacionados a empresa
enum CompanyIssueType {
  missing,
  inNameOnly,
  canSuggest,
  valid,
}

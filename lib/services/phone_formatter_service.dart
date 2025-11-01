import '../models/contact.dart';

/// Serviço para formatação de números de telefone
class PhoneFormatterService {

  /// Formata um número de telefone para o padrão brasileiro +55
  String formatPhoneNumber(String phone, {String defaultDDD = '11'}) {
    if (phone.isEmpty) return '';

    // Remove todos os caracteres não numéricos
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Se já tem +55 no formato correto
    if (phone.startsWith('+55') && digits.startsWith('55')) {
      return phone;
    }

    // Remove 55 do início se já existir
    if (digits.startsWith('55') && digits.length > 2) {
      digits = digits.substring(2);
    }

    // Remove 0 do início (formato antigo 011...)
    if (digits.startsWith('0') && digits.length > 1) {
      digits = digits.substring(1);
    }

    // Casos específicos de formatação
    if (digits.length <= 9) {
      // Apenas o número sem DDD - adiciona DDD padrão (11 - SP)
      return '+55$defaultDDD$digits';
    } else if (digits.length == 10) {
      // DDD + número (telefone fixo: XX XXXX-XXXX)
      return '+55$digits';
    } else if (digits.length == 11) {
      // DDD + número com 9 (celular: XX 9XXXX-XXXX)
      return '+55$digits';
    } else {
      // Formato não reconhecido - retorna com +55 na frente
      return '+55$digits';
    }
  }

  /// Valida se um número de telefone é válido
  bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D+'), '');
    final cleanDigits = digits.startsWith('55') ? digits.substring(2) : digits;

    // Telefone brasileiro deve ter pelo menos 10 dígitos (DDD + número)
    // Celular: 11 dígitos, Fixo: 10 dígitos
    return cleanDigits.length >= 10 && cleanDigits.length <= 11;
  }

  /// Identifica o tipo de problema do telefone
  PhoneIssueType identifyPhoneIssue(String phone) {
    if (phone.isEmpty) return PhoneIssueType.empty;

    final hasCountryCode = phone.startsWith('+55') || phone.startsWith('55');
    final digits = phone.replaceAll(RegExp(r'\D+'), '');
    final cleanDigits = digits.startsWith('55') ? digits.substring(2) : digits;

    if (!hasCountryCode) return PhoneIssueType.missingCountryCode;
    if (phone.startsWith('0')) return PhoneIssueType.oldFormat;
    if (cleanDigits.length < 10) return PhoneIssueType.tooShort;
    if (cleanDigits.length > 11) return PhoneIssueType.tooLong;

    return PhoneIssueType.valid;
  }

  /// Formata um contato com número corrigido
  Contact formatContact(Contact contact, {String defaultDDD = '11'}) {
    final formattedPhone = formatPhoneNumber(contact.phoneNumber, defaultDDD: defaultDDD);
    return contact.copyWith(phoneNumber: formattedPhone);
  }

  /// Filtra contatos que precisam de formatação
  List<Contact> getContactsNeedingFormat(List<Contact> contacts) {
    return contacts.where((contact) {
      final issue = identifyPhoneIssue(contact.phoneNumber);
      return issue != PhoneIssueType.valid;
    }).toList();
  }

  /// Agrupa contatos por tipo de problema
  Map<PhoneIssueType, List<Contact>> groupByIssueType(List<Contact> contacts) {
    final grouped = <PhoneIssueType, List<Contact>>{};

    for (var contact in contacts) {
      final issue = identifyPhoneIssue(contact.phoneNumber);
      grouped.putIfAbsent(issue, () => []).add(contact);
    }

    return grouped;
  }

  /// Obtém descrição legível do tipo de problema
  String getIssueDescription(PhoneIssueType type) {
    switch (type) {
      case PhoneIssueType.missingCountryCode:
        return 'Sem código do país (+55)';
      case PhoneIssueType.oldFormat:
        return 'Formato antigo (começa com 0)';
      case PhoneIssueType.tooShort:
        return 'Número muito curto (menos de 10 dígitos)';
      case PhoneIssueType.tooLong:
        return 'Número muito longo (mais de 11 dígitos)';
      case PhoneIssueType.empty:
        return 'Telefone vazio';
      case PhoneIssueType.valid:
        return 'Telefone válido';
    }
  }

  /// Obtém estatísticas de formatação
  Map<String, dynamic> getFormatStatistics(List<Contact> contacts) {
    final grouped = groupByIssueType(contacts);

    return {
      'total': contacts.length,
      'needsFormat': contacts.length - (grouped[PhoneIssueType.valid]?.length ?? 0),
      'missingCountryCode': grouped[PhoneIssueType.missingCountryCode]?.length ?? 0,
      'oldFormat': grouped[PhoneIssueType.oldFormat]?.length ?? 0,
      'tooShort': grouped[PhoneIssueType.tooShort]?.length ?? 0,
      'tooLong': grouped[PhoneIssueType.tooLong]?.length ?? 0,
      'empty': grouped[PhoneIssueType.empty]?.length ?? 0,
      'valid': grouped[PhoneIssueType.valid]?.length ?? 0,
    };
  }

  /// Valida se o telefone segue o padrão brasileiro correto
  /// Padrão: +55 [DDD com 2 dígitos] [Número com 8 ou 9 dígitos]
  /// Exemplo: +55 11 98765-4321 ou +55 21 3456-7890
  bool isValidBrazilianPhone(String phone) {
    if (phone.isEmpty) return false;

    // Remove todos os caracteres não numéricos
    String digits = phone.replaceAll(RegExp(r'\D+'), '');

    // Remove código do país se existir
    if (digits.startsWith('55')) {
      digits = digits.substring(2);
    }

    // Deve ter exatamente 10 ou 11 dígitos (DDD + número)
    if (digits.length != 10 && digits.length != 11) {
      return false;
    }

    // Extrai DDD (primeiros 2 dígitos)
    final ddd = int.tryParse(digits.substring(0, 2));
    if (ddd == null) return false;

    // Lista de DDDs válidos no Brasil
    final validDDDs = [
      11, 12, 13, 14, 15, 16, 17, 18, 19, // SP
      21, 22, 24, // RJ
      27, 28, // ES
      31, 32, 33, 34, 35, 37, 38, // MG
      41, 42, 43, 44, 45, 46, // PR
      47, 48, 49, // SC
      51, 53, 54, 55, // RS
      61, // DF
      62, 64, // GO
      63, // TO
      65, 66, // MT
      67, // MS
      68, // AC
      69, // RO
      71, 73, 74, 75, 77, // BA
      79, // SE
      81, 87, // PE
      82, // AL
      83, // PB
      84, // RN
      85, 88, // CE
      86, 89, // PI
      91, 93, 94, // PA
      92, 97, // AM
      95, // RR
      96, // AP
      98, 99, // MA
    ];

    return validDDDs.contains(ddd);
  }

  /// Filtra contatos com telefones inválidos (não seguem padrão brasileiro)
  List<Contact> getContactsWithInvalidPhones(List<Contact> contacts) {
    return contacts.where((contact) {
      return !isValidBrazilianPhone(contact.phoneNumber);
    }).toList();
  }
}

/// Tipos de problemas identificados em telefones
enum PhoneIssueType {
  missingCountryCode,
  oldFormat,
  tooShort,
  tooLong,
  empty,
  valid,
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import 'api_config.dart';

/// Serviço centralizado para operações de contatos na API
class ContactsService {
  final _logger = Logger('ContactsService');

  /// Busca todos os contatos de todas as páginas
  Future<List<Contact>> fetchAllContacts({
    Function(String)? onStatusUpdate,
    Function(double)? onProgressUpdate,
  }) async {
    final allContacts = <Contact>[];
    int currentPage = 1;
    bool hasMorePages = true;

    try {
      while (hasMorePages) {
        onStatusUpdate?.call('Carregando página $currentPage...');

        final response = await http.get(
          Uri.parse(
              '${ApiConfig.contactsEndpoint}?page=$currentPage&per_page=100'),
          headers: ApiConfig.headers,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> payload = data['payload'] ?? [];

          if (payload.isEmpty) {
            hasMorePages = false;
          } else {
            for (var json in payload) {
              try {
                allContacts.add(Contact.fromJson(json));
              } catch (e) {
                _logger.warning('Erro ao processar contato: $e');
              }
            }

            _logger.info(
                'Página $currentPage carregada: ${payload.length} contatos');
            currentPage++;
          }
        } else {
          throw Exception(
              'Erro na API: ${response.statusCode} - ${response.body}');
        }
      }

      onStatusUpdate
          ?.call('${allContacts.length} contatos carregados com sucesso');
      onProgressUpdate?.call(1.0);

      return allContacts;
    } catch (e) {
      _logger.severe('Erro ao buscar contatos', e);
      onStatusUpdate?.call('Erro ao carregar contatos: $e');
      rethrow;
    }
  }

  /// Busca contatos de uma página específica
  Future<List<Contact>> fetchContactsPage(int page, {int perPage = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.contactsEndpoint}?page=$page&per_page=$perPage'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> payload = data['payload'] ?? [];
        return payload.map((json) => Contact.fromJson(json)).toList();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Erro ao buscar página $page', e);
      rethrow;
    }
  }

  /// Atualiza um contato existente
  Future<Contact> updateContact(Contact contact) async {
    if (contact.id == null) {
      throw Exception('ID do contato é obrigatório para atualização');
    }

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.contactEndpoint(contact.id.toString())),
        headers: ApiConfig.headers,
        body: jsonEncode(contact.toJson()),
      );

      if (response.statusCode == 200) {
        _logger.info('Contato ${contact.id} atualizado com sucesso');
        final data = jsonDecode(response.body);
        return Contact.fromJson(data['payload'] ?? data);
      } else {
        throw Exception(
            'Erro ao atualizar: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Erro ao atualizar contato ${contact.id}', e);
      rethrow;
    }
  }

  /// Atualiza múltiplos contatos
  Future<Map<String, dynamic>> updateMultipleContacts(
    List<Contact> contacts, {
    Function(String)? onStatusUpdate,
    Function(double)? onProgressUpdate,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    final errors = <String, String>{};

    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];

      try {
        onStatusUpdate?.call(
            'Atualizando ${i + 1} de ${contacts.length}: ${contact.name}');
        await updateContact(contact);
        successCount++;
      } catch (e) {
        errorCount++;
        errors[contact.id?.toString() ?? 'unknown'] = e.toString();
        _logger.warning('Falha ao atualizar contato ${contact.id}: $e');
      }

      onProgressUpdate?.call((i + 1) / contacts.length);
    }

    onStatusUpdate?.call(
        'Atualização concluída: $successCount sucesso, $errorCount erros');

    return {
      'success': successCount,
      'errors': errorCount,
      'errorDetails': errors,
    };
  }

  /// Deleta um contato
  Future<bool> deleteContact(int contactId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.contactEndpoint(contactId.toString())),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        _logger.info('Contato $contactId excluído com sucesso');
        return true;
      } else {
        throw Exception(
            'Erro ao deletar: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Erro ao deletar contato $contactId', e);
      rethrow;
    }
  }

  /// Deleta múltiplos contatos
  Future<Map<String, dynamic>> deleteMultipleContacts(
    List<int> contactIds, {
    Function(String)? onStatusUpdate,
    Function(double)? onProgressUpdate,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    final errors = <String, String>{};

    for (int i = 0; i < contactIds.length; i++) {
      final contactId = contactIds[i];

      try {
        onStatusUpdate?.call('Excluindo ${i + 1} de ${contactIds.length}...');
        await deleteContact(contactId);
        successCount++;
      } catch (e) {
        errorCount++;
        errors[contactId.toString()] = e.toString();
      }

      onProgressUpdate?.call((i + 1) / contactIds.length);
    }

    onStatusUpdate
        ?.call('Exclusão concluída: $successCount sucesso, $errorCount erros');

    return {
      'success': successCount,
      'errors': errorCount,
      'errorDetails': errors,
    };
  }

  /// Busca estatísticas dos contatos
  Future<ContactsStatistics> getStatistics(List<Contact> contacts) async {
    return ContactsStatistics.fromContacts(contacts);
  }

  /// Busca conversas de um contato
  Future<List<dynamic>> getContactConversations(int contactId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/accounts/${ApiConfig.accountId}/contacts/$contactId/conversations'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payload'] ?? [];
      } else {
        throw Exception('Erro ao buscar conversas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Erro ao buscar conversas do contato $contactId', e);
      rethrow;
    }
  }
}

/// Estatísticas dos contatos
class ContactsStatistics {
  final int total;
  final int withoutCountryCode;
  final int duplicates;
  final int withoutCompany;
  final int invalidPhone;
  final int invalidEmail;
  final int withoutName;

  ContactsStatistics({
    required this.total,
    required this.withoutCountryCode,
    required this.duplicates,
    required this.withoutCompany,
    required this.invalidPhone,
    required this.invalidEmail,
    required this.withoutName,
  });

  factory ContactsStatistics.fromContacts(List<Contact> contacts) {
    // Agrupa por telefone normalizado para detectar duplicados
    final phoneGroups = <String, List<Contact>>{};
    for (var contact in contacts) {
      final normalized = contact.normalizedPhone;
      // Ignora telefones vazios ou muito curtos para fins de duplicação
      if (normalized.length >= 8) {
        phoneGroups.putIfAbsent(normalized, () => []).add(contact);
      }
    }

    // Conta TOTAL de contatos que são duplicados (ex: 3 contatos iguais = 3 duplicados)
    final duplicateCount = phoneGroups.values
        .where((list) => list.length > 1)
        .fold(0, (sum, list) => sum + list.length);

    // Conta telefones inválidos usando validação brasileira completa
    int invalidPhoneCount = 0;
    int withoutCountryCodeCount = 0;

    for (var contact in contacts) {
      final phone = contact.phoneNumber;

      // Ignora vazios nas estatísticas específicas de formato (ficam como "Inválido" ou "Sem nome" se aplicável?)
      // Na verdade, telefone vazio conta como inválido?
      // O codigo original contava length < 10 como inválido (incluindo vazio).
      // Vamos manter vazio como inválido, mas NÃO como "Sem código +55"

      final digits = phone.replaceAll(RegExp(r'\D+'), '');
      final cleanDigits =
          digits.startsWith('55') ? digits.substring(2) : digits;

      // Logica para "Sem código +55"
      // Só conta se tiver numeros suficientes para ser um telefone, mas nao tem o 55
      if (digits.isNotEmpty && !contact.hasCountryCode) {
        withoutCountryCodeCount++;
      }

      // Inválido se:
      // - Muito curto (< 10 dígitos)
      // - Muito longo (> 11 dígitos)
      // - DDD inválido
      if (cleanDigits.length < 10 || cleanDigits.length > 11) {
        invalidPhoneCount++;
      } else if (cleanDigits.length >= 2) {
        final ddd = int.tryParse(cleanDigits.substring(0, 2));
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
        if (ddd == null || !validDDDs.contains(ddd)) {
          invalidPhoneCount++;
        }
      }
    }

    return ContactsStatistics(
      total: contacts.length,
      withoutCountryCode: withoutCountryCodeCount,
      duplicates: duplicateCount,
      withoutCompany: contacts.where((c) => !c.hasCompany).length,
      invalidPhone: invalidPhoneCount,
      invalidEmail:
          contacts.where((c) => c.email != null && !c.hasValidEmail).length,
      withoutName: contacts.where((c) => c.name.isEmpty).length,
    );
  }

  bool get hasIssues =>
      withoutCountryCode > 0 ||
      duplicates > 0 ||
      withoutCompany > 0 ||
      invalidPhone > 0 ||
      invalidEmail > 0 ||
      withoutName > 0;
}

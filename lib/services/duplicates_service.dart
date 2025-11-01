import '../models/contact.dart';

/// Serviço para detecção e gerenciamento de contatos duplicados
class DuplicatesService {

  /// Agrupa contatos duplicados por telefone normalizado
  Map<String, List<Contact>> findDuplicateGroups(List<Contact> contacts) {
    final phoneGroups = <String, List<Contact>>{};

    for (var contact in contacts) {
      final normalized = contact.normalizedPhone;
      if (normalized.isEmpty) continue;

      phoneGroups.putIfAbsent(normalized, () => []).add(contact);
    }

    // Remove grupos com apenas 1 contato (não são duplicados)
    phoneGroups.removeWhere((_, contacts) => contacts.length <= 1);

    // Ordena cada grupo por data de atualização (mais recente primeiro)
    for (var group in phoneGroups.values) {
      group.sort((a, b) {
        if (a.updatedAt == null && b.updatedAt == null) return 0;
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });
    }

    // Ordena grupos por quantidade de duplicatas (maior primeiro)
    final sorted = Map.fromEntries(
      phoneGroups.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );

    return sorted;
  }

  /// Obtém o contato principal de um grupo (mais recente e completo)
  Contact getPrimaryContact(List<Contact> group) {
    if (group.isEmpty) throw Exception('Grupo vazio');
    if (group.length == 1) return group.first;

    // Ordena por prioridade:
    // 1. Mais recente (updatedAt)
    // 2. Com mais informações preenchidas
    // 3. Com código +55
    group.sort((a, b) {
      // Prioriza com código +55
      if (a.hasCountryCode && !b.hasCountryCode) return -1;
      if (!a.hasCountryCode && b.hasCountryCode) return 1;

      // Prioriza mais completo (com empresa, email, etc)
      final aScore = _getCompletenessScore(a);
      final bScore = _getCompletenessScore(b);
      if (aScore != bScore) return bScore.compareTo(aScore);

      // Prioriza mais recente
      if (a.updatedAt == null && b.updatedAt == null) return 0;
      if (a.updatedAt == null) return 1;
      if (b.updatedAt == null) return -1;
      return b.updatedAt!.compareTo(a.updatedAt!);
    });

    return group.first;
  }

  /// Calcula pontuação de completude do contato
  int _getCompletenessScore(Contact contact) {
    int score = 0;
    if (contact.name.isNotEmpty) score++;
    if (contact.email != null && contact.email!.isNotEmpty) score++;
    if (contact.hasCompany) score++;
    if (contact.hasCountryCode) score++;
    if (contact.hasValidPhone) score++;
    return score;
  }

  /// Mescla informações de múltiplos contatos duplicados
  Contact mergeContacts(List<Contact> duplicates) {
    if (duplicates.isEmpty) throw Exception('Lista vazia');
    if (duplicates.length == 1) return duplicates.first;

    final primary = getPrimaryContact(duplicates);

    // Mescla informações dos outros contatos
    String? bestEmail = primary.email;
    String? bestCompany = primary.company;
    Map<String, dynamic>? mergedAttributes = Map.from(primary.customAttributes ?? {});

    for (var contact in duplicates) {
      if (contact.id == primary.id) continue;

      // Usa email mais completo
      if (bestEmail == null || bestEmail.isEmpty) {
        bestEmail = contact.email;
      }

      // Usa empresa mais completa
      if (bestCompany == null || bestCompany.isEmpty) {
        bestCompany = contact.company;
      }

      // Mescla atributos customizados
      if (contact.customAttributes != null) {
        mergedAttributes.addAll(contact.customAttributes!);
      }
    }

    return primary.copyWith(
      email: bestEmail,
      company: bestCompany,
      customAttributes: {
        ...mergedAttributes,
        'merged_from': duplicates.where((c) => c.id != primary.id).map((c) => c.id).toList(),
        'merged_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Obtém contatos para excluir (mantendo apenas o principal)
  List<Contact> getContactsToDelete(List<Contact> group, {Contact? keepContact}) {
    if (group.length <= 1) return [];

    final primary = keepContact ?? getPrimaryContact(group);
    return group.where((c) => c.id != primary.id).toList();
  }

  /// Filtra apenas contatos duplicados
  List<Contact> getDuplicateContacts(List<Contact> contacts) {
    final groups = findDuplicateGroups(contacts);
    return groups.values.expand((group) => group).toList();
  }

  /// Obtém estatísticas de duplicados
  Map<String, dynamic> getDuplicateStatistics(List<Contact> contacts) {
    final groups = findDuplicateGroups(contacts);
    final totalDuplicates = groups.values.fold<int>(0, (sum, group) => sum + group.length);
    final duplicatesToRemove = groups.values.fold<int>(0, (sum, group) => sum + (group.length - 1));

    return {
      'totalGroups': groups.length,
      'totalDuplicates': totalDuplicates,
      'duplicatesToRemove': duplicatesToRemove,
      'largestGroup': groups.values.isEmpty ? 0 : groups.values.first.length,
      'averagePerGroup': groups.isEmpty ? 0 : (totalDuplicates / groups.length).toStringAsFixed(1),
    };
  }

  /// Compara dois contatos para verificar similaridade
  double compareSimilarity(Contact a, Contact b) {
    double score = 0.0;

    // Telefones normalizados são iguais
    if (a.normalizedPhone == b.normalizedPhone) score += 0.5;

    // Nomes similares
    final nameSimilarity = _calculateStringSimilarity(a.name.toLowerCase(), b.name.toLowerCase());
    score += nameSimilarity * 0.3;

    // Emails iguais
    if (a.email != null && b.email != null && a.email == b.email) {
      score += 0.2;
    }

    return score;
  }

  /// Calcula similaridade entre duas strings (Levenshtein simplificado)
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    if (longer.contains(shorter)) return 0.7;

    // Similaridade básica por caracteres comuns
    final common = shorter.split('').where((char) => longer.contains(char)).length;
    return common / longer.length;
  }
}

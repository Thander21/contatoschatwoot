/// Modelo de dados para Contato
class Contact {
  final int? id;
  final String name;
  final String? email;
  final String phoneNumber;
  final String? company;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? customAttributes;
  final Map<String, dynamic>? additionalAttributes;

  Contact({
    this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    this.company,
    this.createdAt,
    this.updatedAt,
    this.customAttributes,
    this.additionalAttributes,
  });

  /// Cria um Contact a partir de JSON da API
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString() ?? '',
      company: json['company']?.toString() ??
               json['custom_attributes']?['company']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      customAttributes: json['custom_attributes'] as Map<String, dynamic>?,
      additionalAttributes: json['additional_attributes'] as Map<String, dynamic>?,
    );
  }

  /// Converte Contact para JSON para enviar à API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (email != null) 'email': email,
      'phone_number': phoneNumber,
      if (company != null) 'company': company,
      if (customAttributes != null) 'custom_attributes': customAttributes,
      if (additionalAttributes != null) 'additional_attributes': additionalAttributes,
    };
  }

  /// Cria uma cópia do contato com campos modificados
  Contact copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? company,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
    Map<String, dynamic>? additionalAttributes,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customAttributes: customAttributes ?? this.customAttributes,
      additionalAttributes: additionalAttributes ?? this.additionalAttributes,
    );
  }

  /// Verifica se o telefone tem código +55
  bool get hasCountryCode {
    return phoneNumber.startsWith('+55') || phoneNumber.startsWith('55');
  }

  /// Verifica se o contato tem empresa definida
  bool get hasCompany {
    return company != null && company!.isNotEmpty;
  }

  /// Extrai empresa do nome (se houver padrão "Nome - Empresa")
  String? extractCompanyFromName() {
    final parts = name.split(' - ');
    if (parts.length >= 2) {
      return parts.sublist(1).join(' - ').trim();
    }
    return null;
  }

  /// Extrai apenas o nome (remove empresa se existir)
  String extractCleanName() {
    final parts = name.split(' - ');
    return parts.first.trim();
  }

  /// Telefone normalizado (apenas dígitos)
  String get normalizedPhone {
    final digits = phoneNumber.replaceAll(RegExp(r'\D+'), '');
    return digits.startsWith('55') ? digits.substring(2) : digits;
  }

  /// Verifica se o telefone é válido (pelo menos 10 dígitos)
  bool get hasValidPhone {
    return normalizedPhone.length >= 10;
  }

  /// Verifica se o email é válido
  bool get hasValidEmail {
    if (email == null || email!.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email!);
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phoneNumber, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/contacts_list_screen.dart';
import 'screens/phone_format_screen.dart';
import 'screens/duplicate_contacts_screen.dart';
import 'screens/company_management_screen.dart';

class ContactManagementRoutes {
  // Rotas principais
  static const String dashboard = '/';
  static const String contactsList = '/contacts-list';
  static const String phoneFormat = '/phone-format';
  static const String duplicates = '/duplicates';
  static const String companyManagement = '/company-management';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case contactsList:
        return MaterialPageRoute(builder: (_) => const ContactsListScreen());
      case phoneFormat:
        return MaterialPageRoute(builder: (_) => const PhoneFormatScreen());
      case duplicates:
        return MaterialPageRoute(builder: (_) => const DuplicateContactsScreen());
      case companyManagement:
        return MaterialPageRoute(builder: (_) => const CompanyManagementScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não definida: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

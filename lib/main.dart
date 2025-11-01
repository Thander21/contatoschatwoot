import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'contact_management_routes.dart';
import 'services/credentials_service.dart';

void main() async {
  // Configuração de logs
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Inicialização da janela (para desktop)
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768), // Tamanho maior para melhor visualização
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ContactsManagementApp());
}

class ContactsManagementApp extends StatefulWidget {
  const ContactsManagementApp({super.key});

  @override
  State<ContactsManagementApp> createState() => _ContactsManagementAppState();
}

class _ContactsManagementAppState extends State<ContactsManagementApp> with WidgetsBindingObserver {
  final _credentialsService = CredentialsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Limpa as credenciais ao fechar o app
    _credentialsService.clearCredentials();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Limpa credenciais quando o app é fechado ou pausado
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      _credentialsService.clearCredentials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Contatos Chatwoot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: ContactManagementRoutes.dashboard,
      onGenerateRoute: ContactManagementRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

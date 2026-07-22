import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';

/// Serviço para backup e exportação de contatos
class BackupService {
  final _logger = Logger('BackupService');

  /// Exporta contatos para arquivo Excel
  Future<String> exportToExcel(
    List<Contact> contacts, {
    String? customFileName,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Preparando arquivo Excel...');

      final excel = Excel.createExcel();
      final sheet = excel['Contatos'];

      // Remove a planilha padrão se houver
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Adiciona cabeçalhos com estilo
      final headers = [
        'ID',
        'Nome',
        'Email',
        'Telefone',
        'Empresa',
        'Criado em',
        'Atualizado em',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      onStatusUpdate?.call('Exportando ${contacts.length} contatos...');

      // Adiciona dados dos contatos
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];

        sheet.appendRow([
          TextCellValue(contact.id?.toString() ?? ''),
          TextCellValue(contact.name),
          TextCellValue(contact.email ?? ''),
          TextCellValue(contact.phoneNumber),
          TextCellValue(contact.company ?? ''),
          TextCellValue(contact.createdAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(contact.createdAt!)
              : ''),
          TextCellValue(contact.updatedAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(contact.updatedAt!)
              : ''),
        ]);

        if ((i + 1) % 100 == 0) {
          onStatusUpdate?.call('Exportando ${i + 1} de ${contacts.length}...');
        }
      }

      // Salva o arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = customFileName ?? 'backup_contatos_$timestamp.xlsx';
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      onStatusUpdate?.call('Backup salvo com sucesso!');
      _logger.info('Backup criado: $filePath');

      return filePath;
    } catch (e) {
      _logger.severe('Erro ao criar backup', e);
      onStatusUpdate?.call('Erro ao criar backup: $e');
      rethrow;
    }
  }

  /// Exporta apenas contatos com problemas específicos
  Future<String> exportProblematicContacts(
    List<Contact> contacts,
    String category, {
    Function(String)? onStatusUpdate,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'contatos_${category.toLowerCase()}_$timestamp.xlsx';
    return exportToExcel(contacts, customFileName: fileName, onStatusUpdate: onStatusUpdate);
  }

  /// Lista todos os backups existentes
  Future<List<FileSystemEntity>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((file) =>
              file.path.endsWith('.xlsx') &&
              (file.path.contains('backup_contatos') ||
                  file.path.contains('contatos_')))
          .toList();

      // Ordena por data de modificação (mais recente primeiro)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return files;
    } catch (e) {
      _logger.severe('Erro ao listar backups', e);
      return [];
    }
  }

  /// Deleta um backup
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Backup deletado: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Erro ao deletar backup', e);
      return false;
    }
  }

  /// Obtém o tamanho do arquivo em formato legível
  String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Obtém informações do backup
  Map<String, dynamic> getBackupInfo(FileSystemEntity fileEntity) {
    final file = File(fileEntity.path);
    final stat = file.statSync();
    final fileName = fileEntity.path.split(Platform.pathSeparator).last;

    return {
      'path': fileEntity.path,
      'name': fileName,
      'size': getFileSize(file),
      'modified': stat.modified,
      'modifiedFormatted': DateFormat('dd/MM/yyyy HH:mm').format(stat.modified),
    };
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('ContactsFunctions');

List<Map<String, dynamic>> contacts = [];

Future<void> fetchContacts(int pages, Function(String) updateStatus,
    Function(double) updateProgress) async {
  contacts = [];
  updateStatus('Baixando contatos...');
  updateProgress(0.0);

  for (int page = 1; page <= pages; page++) {
    updateStatus('Baixando página $page de $pages...');
    updateProgress(page /
        pages /
        2); // Dividimos por 2 porque consideramos que o download é metade do processo

    try {
      final response = await http.get(
        Uri.parse(
            'https://chat.sampati.com.br/api/v1/accounts/1/contacts?sort=-name&page=$page'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'api_access_token': 'Gc2kxzGj98mPECbBf7fMByKo',
          'Cookie':
              '_chatwoot_session=SVxdrBo4O6ojpcY9NAWtzK%2Fo62EWSkW1GG6%2B0ybUNmdSaxb0mrhKDvbh0uRQ5RAltRFHUqDNHWKobgydT8llc901qXGRK7r3Ltd9HaUPy8e9W1%2F3ZLd5904GidPJ64j0AazF1aD5B4Xrv4ckGwrNvRE%2FvILZkmlv%2F8%2FvGeEbCS0brynQIDGMIdwk0pFobOWRect6LK7NMe0e4Kgv6NWQAz86VqW2XY38VXy7JtsvFMcJb7EsqYbGEVq%2BZuGhDFnB3uetSWIjBGTG0fVJsAjOr7mxHhjUgVu3LQ%3D%3D--6nPtUFG08bFoBbHk--tPzH2Ju6hKaVS%2B9RDb4VKA%3D%3D',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> pageContacts = responseData['payload'];
        contacts.addAll(pageContacts.map((item) => {
              'email': item['email'],
              'name': item['name'],
              'phone_number': item['phone_number'],
            }));
      } else {
        throw Exception(
            'Resposta da API não foi bem-sucedida. Status code: ${response.statusCode}');
      }
    } catch (e) {
      updateStatus('Erro ao carregar contatos da página $page: $e');
      _logger.severe('Erro detalhado: $e');
      return;
    }
  }

  updateStatus('Contatos baixados. Gerando arquivo Excel...');
  updateProgress(0.5); // Download completo, começando a geração do arquivo

  await saveToExcel(updateStatus, updateProgress);
}

Future<void> saveToExcel(
    Function(String) updateStatus, Function(double) updateProgress) async {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Contatos'];

  // Adicionar cabeçalhos
  sheetObject.appendRow(['Nome', 'Email', 'Telefone']);

  // Adicionar dados
  for (var i = 0; i < contacts.length; i++) {
    var contact = contacts[i];
    sheetObject.appendRow(
        [contact['name'], contact['email'], contact['phone_number']]);
    updateProgress(0.5 +
        (i + 1) /
            contacts.length /
            2); // A segunda metade do progresso é para a geração do arquivo
  }

  try {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final String path = '${directory.path}/contatos.xlsx';
    final File file = File(path);
    await file.writeAsBytes(excel.encode()!);

    updateStatus('Arquivo Excel salvo em: $path');
    updateProgress(1.0); // Processo completo
  } catch (e) {
    updateStatus('Erro ao salvar o arquivo Excel: $e');
    _logger.severe('Erro ao salvar o arquivo Excel: $e');
  }
}

import 'package:flutter/material.dart';
import 'contacts_functions.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  ContactsPageState createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  final TextEditingController _pagesController = TextEditingController();
  String status = '';
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baixar Contatos')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _pagesController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Número de páginas',
                                labelStyle: TextStyle(fontSize: 18),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  int pages =
                                      int.tryParse(_pagesController.text) ?? 0;
                                  if (pages > 0) {
                                    fetchContacts(
                                        pages, updateStatus, updateProgress);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Por favor, insira um número válido de páginas.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Baixar Contatos',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  void updateStatus(String newStatus) {
    setState(() {
      status = newStatus;
    });
  }

  void updateProgress(double newProgress) {
    setState(() {
      progress = newProgress;
    });
  }
}

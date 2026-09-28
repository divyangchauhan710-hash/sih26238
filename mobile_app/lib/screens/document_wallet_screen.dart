import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class DocumentWalletScreen extends StatelessWidget {
  const DocumentWalletScreen({Key? key}) : super(key: key);

  void _handleReuseDocument(BuildContext context, String docType, String digilockerUri) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.studentId == null) return;

    final success = await state.api.uploadDocument(
      studentId: state.studentId!,
      docType: docType,
      digilockerUri: digilockerUri,
      reusedFromApplicationId: state.applications.isNotEmpty ? state.applications.first.id : null,
    );

    if (success) {
      await state.loadDocuments();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "$docType" attached and reused successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final docs = state.documents;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Digital Document Wallet'),
      ),
      body: docs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No DigiLocker documents in wallet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final isReused = doc.reusedFromApplicationId != null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Color(0xFF0D47A1), size: 28),
                    ),
                    title: Text(
                      doc.docType.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('URI: ${doc.digilockerUri}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (isReused) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Reused from previous application',
                              style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        ]
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _handleReuseDocument(context, doc.docType, doc.digilockerUri),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.repeat, size: 14),
                      label: const Text('Reuse', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

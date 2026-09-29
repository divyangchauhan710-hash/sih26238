import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DocumentWalletScreen extends StatefulWidget {
  const DocumentWalletScreen({Key? key}) : super(key: key);

  @override
  State<DocumentWalletScreen> createState() => _DocumentWalletScreenState();
}

class _DocumentWalletScreenState extends State<DocumentWalletScreen> {
  final _docTypeController = TextEditingController(text: 'INCOME_CERTIFICATE');

  void _handleUploadDocument() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.studentId == null) return;

    final docType = _docTypeController.text.trim();
    final digilockerUri = 'in.gov.digilocker.doc.${DateTime.now().millisecondsSinceEpoch}';

    final success = await state.api.uploadDocument(
      studentId: state.studentId!,
      docType: docType,
      digilockerUri: digilockerUri,
    );

    if (success) {
      await state.loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DigiLocker document "$docType" uploaded & verified!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  void _handleReuseDocument(String docType, String digilockerUri) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.studentId == null) return;

    final appId = state.applications.isNotEmpty ? state.applications.first.id : null;
    final success = await state.api.uploadDocument(
      studentId: state.studentId!,
      docType: docType,
      digilockerUri: digilockerUri,
      reusedFromApplicationId: appId,
    );

    if (success) {
      await state.loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "$docType" attached and reused across applications!'),
            backgroundColor: AppTheme.accentTeal,
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
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Digital Document Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Add DigiLocker Document',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Fetch DigiLocker Verified Certificate',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _docTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Document Type (e.g. ST_CASTE_CERTIFICATE)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleUploadDocument();
                        },
                        icon: const Icon(Icons.cloud_download_rounded),
                        label: const Text('Fetch & Persist Document'),
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: docs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text('No DigiLocker documents attached yet', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final isReused = doc.reusedFromApplicationId != null;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.infoBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: AppTheme.primaryBlue, size: 26),
                    ),
                    title: Text(
                      doc.docType.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('URI: ${doc.digilockerUri}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        if (isReused) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Reused across applications',
                              style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        ]
                      ],
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: () => _handleReuseDocument(doc.docType, doc.digilockerUri),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.repeat_rounded, size: 14),
                      label: const Text('Reuse', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

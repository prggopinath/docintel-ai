import 'package:flutter/material.dart';

import '../../../shared/widgets/section_title.dart';
import '../widgets/ai_feature_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_documents.dart';
import '../../scan/screens/document_type_screen.dart';
import '../../pdf/screens/pdf_tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _documentsRefreshKey = 0;

  Future<void> _openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DocumentTypeScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _documentsRefreshKey++;
    });
  }

  void _openPdfTools() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PdfToolsScreen(),
      ),
    );
  }

  void _openImageTools() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image tools coming soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.document_scanner_outlined,
                      title: 'Scan',
                      onTap: _openScan,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'PDF',
                      onTap: _openPdfTools,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.image_outlined,
                      title: 'Image',
                      onTap: _openImageTools,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const SectionTitle(
                title: 'AI Workspace',
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AIFeatureCard(
                    icon: Icons.summarize_outlined,
                    title: 'Summary',
                  ),
                  AIFeatureCard(
                    icon: Icons.notes_outlined,
                    title: 'Notes',
                  ),
                  AIFeatureCard(
                    icon: Icons.quiz_outlined,
                    title: 'Flashcards',
                  ),
                  AIFeatureCard(
                    icon: Icons.translate_outlined,
                    title: 'Translate',
                  ),
                  AIFeatureCard(
                    icon: Icons.smart_toy_outlined,
                    title: 'Ask AI',
                  ),
                  AIFeatureCard(
                    icon: Icons.analytics_outlined,
                    title: 'Insights',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const SectionTitle(
                title: 'Recent Documents',
              ),

              const SizedBox(height: 16),

              RecentDocuments(
                key: ValueKey(_documentsRefreshKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
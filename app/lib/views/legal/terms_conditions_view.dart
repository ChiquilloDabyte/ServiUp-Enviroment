import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimensions.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class TermsConditionsView extends StatefulWidget {
  const TermsConditionsView({super.key});

  @override
  State<TermsConditionsView> createState() => _TermsConditionsViewState();
}

class _TermsConditionsViewState extends State<TermsConditionsView> {
  String _terms = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final text = await rootBundle.loadString('lib/assets/legal/terms.txt');
    if (!mounted) return;

    setState(() {
      _terms = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 840,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Términos y Condiciones',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Última actualización: Julio de 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SelectableText(
                    _terms,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

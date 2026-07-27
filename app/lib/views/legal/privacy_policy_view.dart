import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimensions.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  String _privacy = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    final text = await rootBundle.loadString('lib/assets/legal/privacy.txt');
    if (!mounted) return;

    setState(() {
      _privacy = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
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
                  'Política de Privacidad',
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
                    _privacy,
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

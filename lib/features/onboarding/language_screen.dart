import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class LanguageScreen extends ConsumerWidget {
  final VoidCallback onDone;
  const LanguageScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: KColors.saffron,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('KiranaBook',
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 28,
                      fontWeight: FontWeight.w800, color: KColors.ink)),
              const SizedBox(height: 8),
              const Text('Apni Bhasha Chuniye\nChoose your language',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 16,
                      color: KColors.inkSoft)),
              const SizedBox(height: 48),

              // Hinglish option
              _LangOption(
                flag: '🇮🇳',
                title: 'Hinglish',
                subtitle: 'Hindi + English\n(Recommended)',
                onTap: () => _select(ref, 'hi', onDone),
              ),
              const SizedBox(height: 16),

              // English option
              _LangOption(
                flag: '🇬🇧',
                title: 'English',
                subtitle: 'Full English',
                onTap: () => _select(ref, 'en', onDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, String lang, VoidCallback onDone) async {
    HapticFeedback.mediumImpact();
    await ref.read(languageProvider.notifier).setLanguage(lang);
    await ref.read(languageProvider.notifier).markSetupDone();
    onDone();
  }
}

class _LangOption extends StatelessWidget {
  final String flag, title, subtitle;
  final VoidCallback onTap;
  const _LangOption({required this.flag, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KColors.border, width: 1.5),
          boxShadow: [BoxShadow(color: KColors.ink.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontFamily: 'Baloo2',
                fontSize: 18, fontWeight: FontWeight.w800, color: KColors.ink)),
            Text(subtitle, style: const TextStyle(fontFamily: 'Baloo2',
                fontSize: 13, color: KColors.inkSoft)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: KColors.inkGhost, size: 16),
        ]),
      ),
    );
  }
}

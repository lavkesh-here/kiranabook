import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onClear;

  const KSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft),
            prefixIcon: const Icon(Icons.search, color: KColors.inkSoft),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: KColors.inkSoft, size: 18),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

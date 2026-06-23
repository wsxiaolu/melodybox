import 'dart:ui';
import 'package:flutter/material.dart';

/// 自定义搜索栏（毛玻璃风格）
class MelodySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;

  const MelodySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hintText = '搜索歌曲、艺人、专辑...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(38),
                Colors.white.withAlpha(10),
              ],
            ),
            border: Border.all(color: Colors.white.withAlpha(51)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            autofocus: autofocus,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
              suffixIcon: controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        controller.clear();
                        onClear?.call();
                        onChanged('');
                      },
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

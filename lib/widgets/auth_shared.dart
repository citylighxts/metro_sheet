import 'package:flutter/cupertino.dart';

class AuthAppLogo extends StatelessWidget {
  const AuthAppLogo({super.key, required this.primary, required this.subtitle});
  final Color primary;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const SizedBox(
              width: 72,
              height: 72,
              child: Icon(CupertinoIcons.music_note_2, color: CupertinoColors.white, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text('MetroSheet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel)),
        ],
      );
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.error, {super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final red = CupertinoColors.systemRed.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: red.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(error.toString(), style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

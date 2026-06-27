import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/settings/settings.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_text_field.dart';

/// Sheet for entering/validating the Groq API key. Stored in secure storage,
/// never persisted to SharedPreferences or logged.
Future<void> showGroqKeySheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<void>(
    context,
    builder: (context) => const _GroqKeySheet(),
  );
}

class _GroqKeySheet extends ConsumerStatefulWidget {
  const _GroqKeySheet();

  @override
  ConsumerState<_GroqKeySheet> createState() => _GroqKeySheetState();
}

class _GroqKeySheetState extends ConsumerState<_GroqKeySheet> {
  final _key = TextEditingController();
  bool _validating = false;
  String? _status;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    ref.read(settingsProvider.notifier).groqKey().then((v) {
      if (v != null && mounted) _key.text = v;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _validating = true;
      _status = 'Validating…';
    });
    final client = ref.read(groqClientProvider);
    final valid = await client.validateKey(key);
    if (!mounted) return;
    if (valid) {
      await ref.read(settingsProvider.notifier).setGroqKey(key);
      ref.invalidate(groqKeyProvider);
      setState(() {
        _validating = false;
        _ok = true;
        _status = 'Connected! AI assistant unlocked.';
      });
    } else {
      setState(() {
        _validating = false;
        _ok = false;
        _status = 'Couldn\'t validate that key. Check it and try again.';
      });
    }
  }

  Future<void> _remove() async {
    await ref.read(settingsProvider.notifier).clearGroqKey();
    ref.invalidate(groqKeyProvider);
    _key.clear();
    setState(() => _status = 'Key removed.');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
            title: 'Groq API key',
            subtitle:
                'Bring your own key from console.groq.com. Stored encrypted on-device — it never leaves your phone except to call Groq.',
          ),
          AppTextField(
            controller: _key,
            label: 'API KEY',
            hint: 'gsk_…',
            icon: Icons.key_outlined,
            obscure: true,
          ),
          if (_status != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                    _ok
                        ? Icons.check_circle_outline
                        : (_validating
                            ? Icons.hourglass_empty
                            : Icons.info_outline),
                    size: 16,
                    color: _ok ? c.income : c.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_status!,
                      style: AppType.bodySm.copyWith(
                          color: _ok ? c.income : c.textSecondary)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _validating ? 'Validating…' : 'Save & validate',
            loading: _validating,
            onTap: _save,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Remove key',
            kind: AppButtonKind.secondary,
            onTap: _remove,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text('Without a key, Aria still works with offline analysis.',
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: c.textTertiary)),
          ),
        ],
      ),
    );
  }
}

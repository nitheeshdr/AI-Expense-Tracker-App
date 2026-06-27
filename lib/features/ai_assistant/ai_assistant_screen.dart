import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pressable.dart';
import 'ai_controller.dart';

const _suggestions = [
  'How much did I spend on food this month?',
  'Where can I save money?',
  'Summarize this week',
  'Which subscriptions should I cancel?',
  'Compare this month with last month',
];

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(aiControllerProvider.notifier).send(text.trim());
    Future.delayed(const Duration(milliseconds: 120), _scrollToEnd);
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = ref.watch(aiControllerProvider).value ?? const AiState();

    return AppScaffold(
      child: Column(
        children: [
          _Header(),
          Expanded(
            child: state.messages.isEmpty
                ? _Empty(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                        AppSpacing.md, AppSpacing.screenH, AppSpacing.lg),
                    itemCount: state.messages.length + (state.thinking ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) {
                        return const _TypingBubble();
                      }
                      return _Bubble(message: state.messages[i]);
                    },
                  ),
          ),
          // Suggestion chips
          if (state.messages.isEmpty || !state.thinking)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH),
                children: [
                  for (final s in _suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Pressable(
                        onTap: () => _send(s),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                                color: c.accent.withValues(alpha: 0.25)),
                          ),
                          child: Text(s,
                              style: AppType.caption.copyWith(color: c.accent)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: BannerAdCard(),
          ),
          // Composer
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                AppSpacing.md, AppSpacing.screenH, 96),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _input,
                    hint: 'Ask Aria about your money…',
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Pressable(
                  onTap: () => _send(_input.text),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: c.accentGradient,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(Icons.arrow_upward,
                        color: Color(0xFFFFFFFF), size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: c.accentGradient,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFFFFFFFF), size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aria',
                    style: AppType.h2.copyWith(color: c.textPrimary)),
                Text('Your AI money assistant',
                    style:
                        AppType.caption.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          Pressable(
            onTap: () => ref.read(aiControllerProvider.notifier).clear(),
            child: Text('Clear',
                style: AppType.bodySm.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _Empty({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 52, color: c.accent),
            const SizedBox(height: AppSpacing.lg),
            Text('Ask me anything about your money',
                textAlign: TextAlign.center,
                style: AppType.h2.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'I read your real transactions to answer. Add a Groq key in Settings for deeper conversations.',
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessageEntity message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final isUser = message.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isUser ? c.accentGradient : null,
                color: isUser ? null : c.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadii.lg),
                  topRight: const Radius.circular(AppRadii.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadii.lg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadii.lg),
                ),
                border: isUser ? null : Border.all(color: c.hairline),
              ),
              child: Text(
                message.content,
                style: AppType.body.copyWith(
                  height: 1.45,
                  color: isUser ? const Color(0xFFFFFFFF) : c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: c.hairline),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: (0.3 +
                              0.7 *
                                  (0.5 +
                                      0.5 *
                                          ((_ctrl.value * 3 - i)
                                              .clamp(0, 1))))
                          .clamp(0.0, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: c.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

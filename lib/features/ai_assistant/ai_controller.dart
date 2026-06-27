import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/models.dart';
import '../../core/settings/settings.dart';

class AiState {
  final List<ChatMessageEntity> messages;
  final bool thinking;
  const AiState({this.messages = const [], this.thinking = false});

  AiState copyWith({List<ChatMessageEntity>? messages, bool? thinking}) =>
      AiState(
        messages: messages ?? this.messages,
        thinking: thinking ?? this.thinking,
      );
}

/// Owns the AI chat: persists history to SQLite, calls [GroqService] (which
/// falls back to a rule-based answer when no key is set), and exposes thinking
/// state for the typing indicator.
class AiController extends AsyncNotifier<AiState> {
  @override
  Future<AiState> build() async {
    final history = await ref.read(chatRepoProvider).all();
    return AiState(messages: history);
  }

  AiState get _current => state.value ?? const AiState();

  Future<void> send(String text) async {
    final repo = ref.read(chatRepoProvider);
    final userMsg = ChatMessageEntity(role: ChatRole.user, content: text);
    await repo.add(userMsg);

    state = AsyncData(_current.copyWith(
      messages: [..._current.messages, userMsg],
      thinking: true,
    ));

    final settings = ref.read(settingsProvider);
    final key = await ref.read(settingsProvider.notifier).groqKey();
    final service = ref.read(groqServiceProvider);

    final answer = await service.ask(
      question: text,
      history: _current.messages,
      currency: settings.currency,
      apiKey: key,
    );

    final aiMsg = ChatMessageEntity(role: ChatRole.assistant, content: answer);
    await repo.add(aiMsg);

    state = AsyncData(_current.copyWith(
      messages: [..._current.messages, aiMsg],
      thinking: false,
    ));

    // A completed AI exchange is a meaningful action → may show interstitial.
    await ref.read(adsManagerProvider).registerActionAndMaybeShow();
  }

  Future<void> clear() async {
    await ref.read(chatRepoProvider).clear();
    state = const AsyncData(AiState());
  }
}

/// Exposed as a plain value (with sensible defaults while loading) so the UI
/// can read `.messages` / `.thinking` without juggling AsyncValue everywhere.
final aiControllerProvider =
    AsyncNotifierProvider<AiController, AiState>(AiController.new);

extension AiStateX on WidgetRef {
  AiState watchAi() =>
      watch(aiControllerProvider).value ?? const AiState();
}

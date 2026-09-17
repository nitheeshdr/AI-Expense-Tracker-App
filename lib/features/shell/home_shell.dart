import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../app/providers.dart';
import '../../core/design/spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/settings/settings.dart';
import '../../core/widgets/app_sheet.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/review/review_prompt_sheet.dart';
import '../../services/updates/app_update_service.dart';
import '../../services/widget/home_widget_service.dart';
import '../add_expense/add_expense_sheet.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../merchants/merchants_screen.dart';
import '../sms_import/sms_import_controller.dart';
import '../sms_import/sms_import_sheet.dart';
import '../transactions/transactions_screen.dart';

/// Shell with a floating pill navigation bar (Home / Activity / + / Budgets /
/// Merchants), a floating AI button bottom-right, and a floating Profile
/// button top-right.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  // Tabs are only built once actually visited — otherwise every ad widget
  // on every tab (banners/native ads) would fire its ad request the moment
  // the app opens, regardless of whether the user ever looks at that tab.
  // That wastes ad inventory and is the main reason "requests" run well
  // ahead of "impressions" in AdMob: most loaded ads were never seen.
  final Set<int> _visitedTabs = {0};
  StreamSubscription<InstallStatus>? _updateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppUpdateService.instance.checkAndStartFlexibleUpdate();
    _updateSub = AppUpdateService.instance.installStatus.listen((status) {
      if (status == InstallStatus.downloaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(days: 1),
          content: const Text('Update downloaded'),
          action: SnackBarAction(
            label: 'Restart',
            onPressed: AppUpdateService.instance.completeUpdate,
          ),
        ));
      }
    });
    // Begin real-time SMS capture: new bank/UPI messages become transactions
    // automatically and pop a snackbar so the spend is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smsImportProvider.notifier).startRealtime((txn) {
        final currency = ref.read(settingsProvider).currency;
        final isIncome = txn.type.name == 'income';
        AppNotifications.instance.show(
          isIncome ? 'Money received' : 'Expense captured',
          '${Money.signed(isIncome ? txn.amount : -txn.amount, code: currency)} · ${txn.merchant}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Auto-captured ${Money.format(txn.amount, code: currency)} · ${txn.merchant}'),
          behavior: SnackBarBehavior.floating,
        ));
      });
      // Catch up on any bank SMS that arrived while the app was closed.
      ref.read(smsImportProvider.notifier).silentSync();
      _refreshWidget();
      _refreshLive();
      _handleWidgetLaunch();
      _handleNotificationLaunch();
      // Ask engaged users to review once per app open (the check itself is
      // frequency-capped and no-ops for new/light users) — delayed so it
      // never competes with the startup work above for the first frame.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) maybeShowReviewPrompt(context, ref);
      });
    });

    // Route live-notification action buttons (Add expense / Add income).
    AppNotifications.instance.onAction = _handleNotificationAction;

    // Keep the home-screen widget + live notification in sync with data changes.
    ref.listenManual(dataRevisionProvider, (_, _) {
      _refreshWidget();
      _refreshLive();
    });

    // Open the add flow when launched from the widget's "Add" button.
    HomeWidget.widgetClicked.listen(_onWidgetUri);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every time the app comes back to the foreground, silently pull any bank
    // SMS received in the meantime so the data is always current.
    if (state == AppLifecycleState.resumed) {
      ref.read(smsImportProvider.notifier).silentSync();
    }
  }

  Future<void> _refreshLive() async {
    final s = ref.read(settingsProvider);
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final repo = ref.read(transactionRepoProvider);
    final today = await repo.totals(dayStart, dayStart.add(const Duration(days: 1)));
    final month = await repo.totals(
        DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
    final budget = s.monthlyBudget;
    final pct = budget <= 0
        ? 0
        : ((month.expense / budget) * 100).clamp(0, 100).round();
    await AppNotifications.instance.showLive(
      'Today ${Money.format(today.expense, code: s.currency)} · month '
      '${Money.format(month.expense, code: s.currency)} of '
      '${Money.format(budget, code: s.currency)} ($pct%)',
      progress: pct,
    );
  }

  Future<void> _handleNotificationLaunch() async {
    final id = await AppNotifications.instance.launchActionId();
    if (id != null) _handleNotificationAction(id);
  }

  void _handleNotificationAction(String actionId) {
    if (!mounted) return;
    openAddExpense(context, ref, income: actionId == 'add_income');
  }

  Future<void> _handleWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _onWidgetUri(uri);
  }

  void _onWidgetUri(Uri? uri) {
    if (!mounted || uri == null) return;
    if (uri.host == 'add' || uri.path.contains('add')) {
      openAddExpense(context, ref);
    }
  }

  void _refreshWidget() {
    final s = ref.read(settingsProvider);
    HomeWidgetService.update(
      repo: ref.read(transactionRepoProvider),
      currency: s.currency,
    );
  }

  // Remembers the last real tab (Home/Activity/Budgets/Profile) so the nav
  // bar still shows a sensible selection while the AI screen (page 2, opened
  // via the floating AI button, not a bar destination) is open.
  int _lastMainTab = 0;

  // Page 2 (AI) and page 5 (Profile) are reached via floating buttons, not
  // the nav bar, so neither should be treated as the bar's "selected" tab.
  static bool _isSideTab(int i) => i == 2 || i == 5;

  void _openTab(int i) {
    Haptics.selection();
    setState(() {
      _index = i;
      _visitedTabs.add(i);
      if (!_isSideTab(i)) _lastMainTab = i;
    });
  }

  void _openActions() {
    Haptics.medium();
    showAppSheet<void>(
      context,
      builder: (sheetContext) => _ActionsSheet(
        onAddExpense: () {
          Navigator.of(sheetContext).pop();
          openAddExpense(context, ref);
        },
        onAddIncome: () {
          Navigator.of(sheetContext).pop();
          openAddExpense(context, ref, income: true);
        },
        onImportSms: () {
          Navigator.of(sheetContext).pop();
          showSmsImportSheet(context, ref);
        },
        onComingSoon: (title) {
          Navigator.of(sheetContext).pop();
          openComingSoon(context, ref, title, Icons.bolt_outlined);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onSeeAllTransactions: () => _openTab(1),
        onOpenTab: _openTab,
        onAddExpense: () => openAddExpense(context, ref),
        onImportSms: () => showSmsImportSheet(context, ref),
      ),
      const TransactionsScreen(),
      const AiAssistantScreen(),
      const BudgetsScreen(),
      const MerchantsScreen(),
      ProfileScreen(onBack: () => _openTab(_lastMainTab)),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < pages.length; i++)
                  _visitedTabs.contains(i) ? pages[i] : const SizedBox.shrink(),
              ],
            ),
          ),
          // Profile now lives here instead of the nav bar, floating
          // top-right — only on the Home tab, not sticky across every tab.
          if (_index == 0)
            Positioned(
              top: 0,
              right: AppSpacing.lg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: IconButton.filledTonal(
                    onPressed: () => _openTab(5),
                    icon: const Icon(Icons.person_outline),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Hidden on the AI screen itself so it never overlaps the composer.
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton(
              heroTag: 'aiFab',
              onPressed: () => _openTab(2),
              child: const Icon(Icons.auto_awesome),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            // Frosted-glass floating pill: blur what's behind it rather than
            // an opaque fill, so scrolled content shows through softly.
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: NavigationBar(
              height: 66,
              // A neutral frosted white/black glass (not theme-tinted) reads
              // as a true glass pane over whatever's scrolled beneath it.
              backgroundColor: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white)
                  .withValues(alpha: 0.6),
              selectedIndex: _isSideTab(_index) ? _lastMainTab : _index,
              onDestinationSelected: (i) {
                if (i == 2) {
                  _openActions();
                  return;
                }
                _openTab(i);
              },
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Activity'),
                NavigationDestination(
                    icon: Icon(Icons.add_circle_outline),
                    selectedIcon: Icon(Icons.add_circle),
                    label: 'Add'),
                NavigationDestination(
                    icon: Icon(Icons.savings_outlined),
                    selectedIcon: Icon(Icons.savings),
                    label: 'Budgets'),
                NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront),
                    label: 'Merchants'),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsSheet extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onImportSms;
  final ValueChanged<String> onComingSoon;

  const _ActionsSheet({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onImportSms,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeader(
            title: 'Quick add',
            subtitle: 'Log money, or pull transactions from your SMS.'),
        _Tile(
            icon: Icons.south_west,
            color: cs.onSurface,
            title: 'Add expense',
            onTap: onAddExpense),
        _Tile(
            icon: Icons.north_east,
            color: cs.onSurface,
            title: 'Add income',
            onTap: onAddIncome),
        _Tile(
            icon: Icons.sms_outlined,
            color: cs.primary,
            title: 'Import from SMS',
            subtitle: 'Auto-detect bank & UPI messages',
            onTap: onImportSms),
        _Tile(
            icon: Icons.document_scanner_outlined,
            color: cs.tertiary,
            title: 'Scan receipt',
            subtitle: 'Coming soon',
            onTap: () => onComingSoon('Receipt Scanning')),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.16),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/providers.dart';
import '../../core/design/spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/settings/settings.dart';
import '../../core/widgets/app_sheet.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/widget/home_widget_service.dart';
import '../add_expense/add_expense_sheet.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../sms_import/sms_import_controller.dart';
import '../sms_import/sms_import_sheet.dart';
import '../transactions/transactions_screen.dart';

/// Shell with a floating pill navigation bar (Home / Activity / + / Budgets /
/// Profile) and a separate round AI button floating on the right.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Begin real-time SMS capture: new bank/UPI messages become transactions
    // automatically and pop a snackbar so the spend is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotifications.instance.requestPermission();
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
      _refreshWidget();
      _refreshLive();
      _handleWidgetLaunch();
      _handleNotificationLaunch();
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

  Future<void> _refreshLive() async {
    final s = ref.read(settingsProvider);
    final range = (
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .add(const Duration(days: 1)),
    );
    final totals =
        await ref.read(transactionRepoProvider).totals(range.$1, range.$2);
    await AppNotifications.instance.showLive(
      'Spent ${Money.format(totals.expense, code: s.currency)} today · tap to add more',
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
      accentColor: s.accentColor,
    );
  }

  void _openTab(int i) {
    Haptics.selection();
    setState(() => _index = i);
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
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: _index, children: pages)),
          // Floating pill navigation
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FloatingNav(
                  index: _index,
                  onTap: _openTab,
                  onAdd: _openActions,
                ),
              ),
            ),
          ),
          // Round AI button on the right, floating clearly above the nav.
          // Hidden on the AI screen so it never overlaps the message composer.
          if (_index != 2)
            Positioned(
              right: AppSpacing.lg,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 92),
                  child: _AiButton(onTap: () => _openTab(2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The floating navigation pill. Four destinations with a highlighted center
/// add button.
class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  const _FloatingNav({
    required this.index,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              active: index == 0,
              onTap: () => onTap(0)),
          _NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'Activity',
              active: index == 1,
              onTap: () => onTap(1)),
          // Center add button
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.add, color: cs.onPrimary, size: 26),
                ),
              ),
            ),
          ),
          _NavItem(
              icon: Icons.savings_outlined,
              activeIcon: Icons.savings,
              label: 'Budgets',
              active: index == 3,
              onTap: () => onTap(3)),
          _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              active: index == 4,
              onTap: () => onTap(4)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AiButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary,
        ),
        child: Icon(Icons.auto_awesome, color: cs.onPrimary, size: 26),
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
            color: cs.error,
            title: 'Add expense',
            onTap: onAddExpense),
        _Tile(
            icon: Icons.north_east,
            color: const Color(0xFF12B98C),
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

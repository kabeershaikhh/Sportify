import 'package:flutter/material.dart';
import 'package:sportify/config/theme.dart';

/// Keeps forms readable on the web while letting mobile use the full width.
class PageLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const PageLayout({super.key, required this.child, this.maxWidth = 1120});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// A consistent section introduction for the app's collection pages.
class PageIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final String eyebrow;
  final IconData icon;
  const PageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eyebrow,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 100) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(constraints.maxWidth < 500 ? 18 : 22),
        decoration: BoxDecoration(
          gradient: AppColors.softBlueGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E7F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: constraints.maxWidth < 500 ? 24 : 28,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Centers a compact sticky action and clears Android's gesture area.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  const BottomActionBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.divider)),
      boxShadow: [
        BoxShadow(
          color: Color(0x08172A52),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
            child: ElevatedButtonTheme(
              data: ElevatedButtonThemeData(
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Keeps page actions compact on desktop while fitting narrow phone screens.
class CompactAction extends StatelessWidget {
  final Widget child;
  const CompactAction({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      child: OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        child: child,
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    this.icon = Icons.search_off_rounded,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                if (onAction != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel ?? 'Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Scrolls collection filters with their results when the viewport is short.
class CollectionPage extends StatelessWidget {
  final Widget header;
  final Widget body;
  const CollectionPage({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) => NestedScrollView(
    headerSliverBuilder: (context, innerBoxIsScrolled) => [
      SliverToBoxAdapter(child: header),
    ],
    body: body,
  );
}

/// Keeps a submitting button's label visible alongside its progress indicator.
class ActionLabel extends StatelessWidget {
  final bool busy;
  final String label;
  final String busyLabel;

  const ActionLabel({
    super.key,
    required this.busy,
    required this.label,
    required this.busyLabel,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (busy) ...[
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
      ],
      Flexible(child: Text(busy ? busyLabel : label)),
    ],
  );
}

/// Blocks repeat submissions while real work is pending. Remove this exact route
/// so an action that navigates cannot accidentally pop the destination page.
Future<T> withProgress<T>(
  BuildContext context,
  Future<T> Function() action, {
  String message = 'Working on it…',
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
  navigator.push(route);
  try {
    return await action();
  } finally {
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  }
}

Future<void> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  String loadingMessage = 'Working on it…',
}) async {
  try {
    await withProgress(context, action, message: loadingMessage);
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

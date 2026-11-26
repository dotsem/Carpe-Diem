import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ],
    );
  }
}

class _SettingsTileWrapper extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const _SettingsTileWrapper({required this.child, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(opacity: enabled ? 1 : 0.3, child: child),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Disables the tile and makes it visually appear disabled.
  ///
  /// Note: [SettingsTile] already uses the [_SettingsTileWrapper] internally,
  /// so if you want to use it yourself, put this value to `true`.
  final bool enabled;

  const SettingsTile({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.enabled = true,
  });

  static Widget wrap({required Widget child, required bool enabled}) {
    return _SettingsTileWrapper(enabled: enabled, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTileWrapper(
      enabled: enabled,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}

class SettingsCustomWidgetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool enabled;

  const SettingsCustomWidgetTile({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      enabled: enabled,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}

class SettingsCustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool enabled;

  const SettingsCustomListTile({
    required this.icon,
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTileWrapper(
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTile(
              icon: icon,
              title: title,
              subtitle: subtitle,
              trailing: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

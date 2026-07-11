import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class SettingsDropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      ),
    );
  }
}

class SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? labelBuilder;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: Text(
            labelBuilder?.call(value) ?? value.round().toString(),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ),
      ],
    );
  }
}

class SettingsCustomWidgetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const SettingsCustomWidgetTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child),
    );
  }
}

class SettingsCustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsCustomListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

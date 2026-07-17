import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/tags/data/models/tag_profile.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagProfileSelectionDialog extends ConsumerWidget {
  const TagProfileSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = TagProfile.predefinedProfiles;
    final theme = Theme.of(context);

    return SizedDialog(
      title: 'Import Tag Profile',
      showDefaultActions: false,
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      child: SizedBox(
        width: 550,
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Choose a profile to populate your tag library with relevant tags and matching icons.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: profiles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(profile.icon, color: theme.colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.description,
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: () async {
                                Navigator.pop(context);
                                await ref.read(tagProvider.notifier).populateProfile(profile);
                              },
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Import'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: profile.tags.map((tagItem) {
                            return Chip(
                              avatar: Icon(tagItem.icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              label: Text('#${tagItem.name}', style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.only(right: 6, left: 4),
                              backgroundColor: theme.colorScheme.surfaceContainerHigh,
                              side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

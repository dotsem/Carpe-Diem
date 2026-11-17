import 'package:carpe_diem/core/theme/app_breakpoints.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_insights_provider.dart';
import 'package:carpe_diem/features/history/presentation/screens/widgets/lead_time_card.dart';
import 'package:carpe_diem/features/history/presentation/screens/widgets/plan_accuracy_card.dart';
import 'package:carpe_diem/features/history/presentation/screens/widgets/section_header.dart';
import 'package:carpe_diem/features/history/presentation/screens/widgets/velocity_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabHistoryInsights extends ConsumerWidget {
  final DateTimeRange range;

  const TabHistoryInsights({super.key, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ref
        .watch(historyInsightsProvider(range))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              'Could not load insights',
              style: TextStyle(color: muted),
            ),
          ),
          data: (insights) {
            final losing = insights.velocity.where((v) => v.delta < 0).toList();
            final gaining = insights.velocity
                .where((v) => v.delta > 0)
                .toList();
            final gainingColumn = _pace('GAINING PACE', gaining, null, muted);
            final losingColumn = _pace(
              'LOSING PACE',
              losing,
              'No project is behind its usual pace.',
              muted,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sideBySide =
                        gaining.isNotEmpty &&
                        constraints.isAtLeast(AppBreakpoint.sm);
                    if (sideBySide) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: gainingColumn),
                            const VerticalDivider(
                              width: 25,
                              indent: 16,
                              endIndent: 16,
                            ),

                            Expanded(child: losingColumn),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        losingColumn,
                        if (gaining.isNotEmpty) ...[Divider(), gainingColumn],
                      ],
                    );
                  },
                ),
                if (insights.leadTimes != null)
                  LeadTimeCard(stats: insights.leadTimes!),
                PlanAccuracyCard(insights: insights),
              ],
            );
          },
        );
  }

  Widget _pace(
    String title,
    List<ProjectVelocity> items,
    String? emptyText,
    Color muted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        if (items.isEmpty)
          Text(emptyText ?? '', style: TextStyle(color: muted))
        else
          VelocityList(items: items),
      ],
    );
  }
}

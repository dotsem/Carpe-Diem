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
          data: (insights) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const SectionHeader('LOSING PACE'),
              if (insights.velocity.isEmpty)
                Text(
                  'No project is behind its usual pace.',
                  style: TextStyle(color: muted),
                )
              else
                VelocityList(items: insights.velocity),
              if (insights.leadTimes != null)
                LeadTimeCard(stats: insights.leadTimes!),
              PlanAccuracyCard(insights: insights),
            ],
          ),
        );
  }
}

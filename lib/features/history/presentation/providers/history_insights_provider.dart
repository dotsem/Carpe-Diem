import 'package:carpe_diem/core/utils/history_stats_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

final FutureProviderFamily<HistoryInsights, DateTimeRange<DateTime>>
historyInsightsProvider = FutureProvider.autoDispose
    .family<HistoryInsights, DateTimeRange>((ref, range) async {
      // why: survive tab switches; HistoryScreen invalidates on open and on filter or range change
      ref.keepAlive();
      final insightsRepo = ref.read(historyInsightsRepositoryProvider);
      final activeIds = ref
          .read(projectProvider)
          .projects
          .where((p) => p.isActive)
          .map((p) => p.id)
          .toSet();
      final firstCompleted = await ref
          .read(historyRepositoryProvider)
          .getFirstCompletedDate();
      final now = DateTime.now();

      // why: velocity looks at the trailing 63 days regardless of the picked range
      final velocityStart = now.subtract(
        const Duration(days: velocityBaselineDays + velocityRecentDays),
      );
      final completions = await insightsRepo.getCompletionsSince(velocityStart);
      final openCounts = await insightsRepo.getOpenCountsByProject();

      final velocity = projectVelocity(
        completions.where((c) => activeIds.contains(c.projectId)),
        openCounts,
        now: now,
      );

      // why: nothing happened before the first ever completion
      final rangeStart =
          firstCompleted != null && firstCompleted.isAfter(range.start)
          ? firstCompleted
          : range.start;
      final trackingSince = await insightsRepo.getTrackingStart();
      final tracked = trackingSince != null;

      return HistoryInsights(
        trackingSince: trackingSince,
        leadTimes: tracked
            ? leadTimes(
                await insightsRepo.getLeadTimeRows(rangeStart, range.end),
              )
            : null,
        slips: tracked
            ? slipStats(await insightsRepo.getSlipRows(rangeStart, range.end))
            : null,
        planAccuracy: tracked
            ? planAccuracy(
                await insightsRepo.getScheduleTimelines(rangeStart, range.end),
                start: rangeStart,
                end: range.end,
                trackingSince: trackingSince,
              )
            : null,
        velocity: velocity,
      );
    });

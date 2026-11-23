import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final FutureProvider<DateTime?> firstCompletedTaskDateProvider =
    FutureProvider.autoDispose<DateTime?>(
      (ref) => ref.watch(historyRepositoryProvider).getFirstCompletedDate(),
    );

import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagIconNotifier extends Notifier<Map<String, IconData>> {
  late final ITagIconRepository _repo;

  @override
  Map<String, IconData> build() {
    _repo = ref.watch(tagIconRepositoryProvider);
    return const {};
  }

  Future<void> loadIcons() async {
    final icons = await _repo.getAllIconDatas();
    state = icons;
  }

  Future<void> setIcon(String tagName, IconData iconData) async {
    final cleanName = tagName.trim().toLowerCase();
    await _repo.setIconDataForTag(cleanName, iconData);
    await loadIcons();
  }

  Future<void> deleteIcon(String tagName) async {
    final cleanName = tagName.trim().toLowerCase();
    await _repo.deleteIconDataForTag(cleanName);
    await loadIcons();
  }
}

final tagIconProvider = NotifierProvider<TagIconNotifier, Map<String, IconData>>(() => TagIconNotifier());

import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class TagState {
  final List<Tag> tags;
  final bool isLoading;

  const TagState({this.tags = const [], this.isLoading = false});

  TagState copyWith({List<Tag>? tags, bool? isLoading}) =>
      TagState(tags: tags ?? this.tags, isLoading: isLoading ?? this.isLoading);

  Tag? getById(String? id) {
    if (id == null) return null;
    try {
      return tags.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

class TagNotifier extends Notifier<TagState> {
  late final ITagRepository _repo;
  final _uuid = const Uuid();

  @override
  TagState build() {
    _repo = ref.watch(tagRepositoryProvider);
    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (previous != null && previous.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          loadTags();
        }
      }
    });

    return const TagState();
  }

  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true);
    final labels = await _repo.getAll();
    state = state.copyWith(tags: labels, isLoading: false);
  }

  Future<void> addTag(String name) async {
    final tag = Tag(id: _uuid.v4(), name: name);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(CreateCommand(repo: _repo, item: tag, id: tag.id, displayName: tag.name));
    await loadTags();
  }

  Future<void> updateTag(Tag tag) async {
    final oldTag = await _repo.getById(tag.id);
    if (oldTag == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: oldTag, next: tag, displayName: tag.name));
    await loadTags();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Future<void> deleteTag(String id) async {
    final tag = await _repo.getById(id);
    if (tag == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(DeleteCommand(repo: _repo, item: tag, id: tag.id, displayName: tag.name));
    await loadTags();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Tag? getById(String? id) {
    if (id == null) return null;
    try {
      return state.tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

final tagProvider = NotifierProvider<TagNotifier, TagState>(() => TagNotifier());

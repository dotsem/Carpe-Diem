import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/data/models/tag_profile.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/set_tag_icon_command.dart';
import 'package:carpe_diem/features/tags/presentation/utils/update_tag_command.dart';
import 'package:carpe_diem/features/tags/presentation/utils/delete_tag_command.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/widgets.dart';
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

  Future<Tag> addTag(String name, {IconData? icon}) async {
    final tag = Tag(id: _uuid.v4(), name: name);
    final commands = <Command>[
      CreateCommand(repo: _repo, item: tag, id: tag.id, displayName: tag.name),
    ];
    if (icon != null) {
      commands.add(SetTagIconCommand(
        repo: ref.read(tagIconRepositoryProvider),
        tagName: name,
        iconData: icon,
      ));
    }
    final compound = CompoundCommand(commands, 'Create Tag: "#$name"');
    await ref.read(undoRedoProvider.notifier).execute(compound);
    await loadTags();
    if (icon != null) {
      await ref.read(tagIconProvider.notifier).loadIcons();
    }
    return tag;
  }

  Future<void> updateTag(Tag tag, {IconData? icon}) async {
    final oldTag = await _repo.getById(tag.id);
    if (oldTag == null) return;
    final iconRepo = ref.read(tagIconRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final command = UpdateTagCommand(
      tagRepo: _repo,
      iconRepo: iconRepo,
      taskRepo: taskRepo,
      previousTag: oldTag,
      nextTag: tag,
      newIcon: icon,
    );
    await ref.read(undoRedoProvider.notifier).execute(command);
    await loadTags();
    await ref.read(tagIconProvider.notifier).loadIcons();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Future<void> deleteTag(String id) async {
    final tag = await _repo.getById(id);
    if (tag == null) return;
    final iconRepo = ref.read(tagIconRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final command = DeleteTagCommand(
      tagRepo: _repo,
      iconRepo: iconRepo,
      taskRepo: taskRepo,
      tag: tag,
    );
    await ref.read(undoRedoProvider.notifier).execute(command);
    await loadTags();
    await ref.read(tagIconProvider.notifier).loadIcons();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Future<void> populateProfile(TagProfile profile) async {
    final existingTags = state.tags.map((t) => t.name.toLowerCase()).toSet();
    final tagRepo = _repo;
    final iconRepo = ref.read(tagIconRepositoryProvider);

    final List<Command> commands = [];

    for (final tagInfo in profile.tags) {
      final name = tagInfo.name;
      final icon = tagInfo.icon;

      if (!existingTags.contains(name.toLowerCase())) {
        final tag = Tag(id: _uuid.v4(), name: name);
        commands.add(CreateCommand(repo: tagRepo, item: tag, id: tag.id, displayName: tag.name));
      }

      commands.add(SetTagIconCommand(repo: iconRepo, tagName: name, iconData: icon));
    }

    if (commands.isNotEmpty) {
      final compound = CompoundCommand(commands, 'Populate "${profile.name}" Profile');
      await ref.read(undoRedoProvider.notifier).execute(compound);
      await loadTags();
      await ref.read(tagIconProvider.notifier).loadIcons();
    }
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

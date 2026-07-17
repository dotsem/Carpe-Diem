import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

abstract class Command {
  Future<void> execute();
  Future<void> undo();
  String get description;
}

class CreateCommand<T> implements Command {
  final ICrudRepository<T> repo;
  final T item;
  final String id;
  final String displayName;
  CreateCommand({required this.repo, required this.item, required this.id, required this.displayName});
  @override
  Future<void> execute() => repo.insert(item);
  @override
  Future<void> undo() => repo.delete(id);
  @override
  String get description => 'Create ${repo.repositoryName}: "$displayName"';
}

// you gonna undo reading or what?

class UpdateCommand<T> implements Command {
  final ICrudRepository<T> repo;
  final T previous;
  final T next;
  final String displayName;
  UpdateCommand({required this.repo, required this.previous, required this.next, required this.displayName});
  @override
  Future<void> execute() => repo.update(next);
  @override
  Future<void> undo() => repo.update(previous);
  @override
  String get description => 'Update ${repo.repositoryName}: "$displayName"';
}

class DeleteCommand<T> implements Command {
  final ICrudRepository<T> repo;
  final T item;
  final String id;
  final String displayName;
  DeleteCommand({required this.repo, required this.item, required this.id, required this.displayName});
  @override
  Future<void> execute() => repo.delete(id);
  @override
  Future<void> undo() => repo.insert(item);
  @override
  String get description => 'Delete ${repo.repositoryName}: "$displayName"';
}

class CompoundCommand implements Command {
  final List<Command> commands;
  @override
  final String description;

  CompoundCommand(this.commands, this.description);

  @override
  Future<void> execute() async {
    for (final cmd in commands) {
      await cmd.execute();
    }
  }

  @override
  Future<void> undo() async {
    for (final cmd in commands.reversed) {
      await cmd.undo();
    }
  }
}


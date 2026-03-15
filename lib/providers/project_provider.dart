import 'package:carpe_diem/data/models/label.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/repositories/project_repository.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repo = ProjectRepository();
  final _uuid = const Uuid();

  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject({
    required String name,
    String? description,
    required Color color,
    Priority priority = Priority.none,
    List<String> labelIds = const [],
    DateTime? deadline,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      color: color,
      priority: priority,
      labelIds: labelIds,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _repo.insert(project);
    await loadProjects();
  }

  Future<void> updateProject(Project project) async {
    await _repo.update(project);
    await loadProjects();
  }

  Future<void> deleteProject(Project project) async {
    await _repo.delete(project.id);
    await loadProjects();
  }

  Project? getById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Label> getLabels(Project project, LabelProvider labelProvider) {
    return project.labelIds.map((id) => labelProvider.getById(id)).whereType<Label>().toList();
  }
}

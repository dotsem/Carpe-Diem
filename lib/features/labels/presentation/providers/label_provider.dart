import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class LabelProvider extends ChangeNotifier {
  final ILabelRepository _repo;
  final _uuid = const Uuid();

  LabelProvider(this._repo);

  List<Label> _labels = [];
  bool _isLoading = false;

  List<Label> get labels => _labels;
  bool get isLoading => _isLoading;

  Future<void> loadLabels() async {
    _isLoading = true;
    notifyListeners();

    _labels = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLabel({required String name, required Color color}) async {
    final label = Label(id: _uuid.v4(), name: name, color: color);
    await _repo.insert(label);
    await loadLabels();
  }

  Future<void> updateLabel(Label label) async {
    await _repo.update(label);
    await loadLabels();
  }

  Future<void> deleteLabel(String id) async {
    await _repo.delete(id);
    await loadLabels();
  }

  Label? getById(String? id) {
    if (id == null) return null;
    try {
      return _labels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

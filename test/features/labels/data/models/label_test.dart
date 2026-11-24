import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Label detects the empty label and round-trips through maps', () {
    const label = Label(id: '', name: '', color: Colors.transparent);
    expect(label.isEmpty, isTrue);
    expect(Label.fromMap(label.toMap()), label);
    expect(Label.empty(), label);
  });
}

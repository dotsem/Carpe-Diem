import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tags/presentation/constants/tag_icon_constants.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final Map<int, IconData> _availableIconMap = {
  for (final icon in availableIcons) icon.codePoint: icon,
};

class TagIconRepository implements ITagIconRepository {
  final Database db;

  TagIconRepository(this.db);

  @override
  Future<Map<String, IconData>> getAllIconDatas() async {
    final List<Map<String, dynamic>> maps = await db.query('tag_icons');
    final Map<String, IconData> result = {};
    for (final map in maps) {
      final name = map['tag_name'] as String;
      final codePoint = map['icon_code_point'] as int;
      result[name] = _availableIconMap[codePoint] ?? Icons.tag;
    }
    return result;
  }

  @override
  Future<void> setIconDataForTag(String tagName, IconData iconData) async {
    final cleanName = tagName.trim().toLowerCase();
    await db.insert('tag_icons', {
      'tag_name': cleanName,
      'icon_code_point': iconData.codePoint,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteIconDataForTag(String tagName) async {
    final cleanName = tagName.trim().toLowerCase();
    await db.delete('tag_icons', where: 'tag_name = ?', whereArgs: [cleanName]);
  }
}

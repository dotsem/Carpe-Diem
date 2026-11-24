import 'package:carpe_diem/core/utils/key_value_map_utils.dart';
import 'package:flutter_test/flutter_test.dart';

enum Choice { one, two }

void main() {
  test('typed map readers parse values and use defaults for invalid data', () {
    final values = <String, String>{
      'int': '12',
      'double': '1.5',
      'true': 'true',
      'false': 'false',
      'string': 'value',
      'enum': 'two',
      'invalid': 'nope',
    };

    expect(values.getInt('int', 0), 12);
    expect(values.getInt('invalid', 7), 7);
    expect(values.getDouble('double', 0), 1.5);
    expect(values.getDouble('invalid', 2.5), 2.5);
    expect(values.getBool('true', false), isTrue);
    expect(values.getBool('false', true), isFalse);
    expect(values.getBool('missing', true), isTrue);
    expect(values.getString('string', 'default'), 'value');
    expect(values.getString('missing', 'default'), 'default');
    expect(values.getEnum('enum', Choice.values, Choice.one), Choice.two);
    expect(values.getEnum('invalid', Choice.values, Choice.one), Choice.one);
    expect(values.getEnum('missing', Choice.values, Choice.one), Choice.one);
  });
}

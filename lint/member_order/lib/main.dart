import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:member_order/src/fields_before_constructors.dart';

final plugin = MemberOrderPlugin();

class MemberOrderPlugin extends Plugin {
  @override
  String get name => 'member_order';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(FieldsBeforeConstructors());
  }
}

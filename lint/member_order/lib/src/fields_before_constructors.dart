import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports fields declared after a constructor.
class FieldsBeforeConstructors extends AnalysisRule {
  FieldsBeforeConstructors()
    : super(
        name: 'fields_before_constructors',
        description: _code.problemMessage,
      );

  static const _code = LintCode(
    'fields_before_constructors',
    'Declare fields before constructors.',
    correctionMessage: 'Move this field above the constructors.',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addBlockClassBody(this, visitor)
      ..addEnumDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitBlockClassBody(BlockClassBody node) => _check(node.members);

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _check(node.body.members);

  void _check(List<ClassMember> members) {
    var seenConstructor = false;
    for (final member in members) {
      if (member is ConstructorDeclaration) seenConstructor = true;
      if (member is FieldDeclaration && seenConstructor)
        rule.reportAtNode(member);
    }
  }
}

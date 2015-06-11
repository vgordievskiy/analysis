library analysis.src.utils;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/// A wrapper for different types of function ASTs that reveals a standard API.
class FunctionDefinition {
  /// Positional arguments (both optional and non-optional).
  final List<FunctionParameter> positionalArguments;

  /// Named arguments.
  final Map<String, FunctionParameter> namedArguments;

  /// Wraps a constructor AST.
  factory FunctionDefinition.fromConstructor(
      ConstructorDeclaration constructor) {
    final positionalArgs = constructor.parameters.parameters.map((parameter) {
      return new FunctionParameter.fromFormalParameter(parameter);
    }).toList(growable: false);
    return new FunctionDefinition._(positionalArgs, const {});
  }

  FunctionDefinition._(this.positionalArguments, this.namedArguments);
}

/// A wrapper for different types of parameter ASTs that reveals a standard API.
class FunctionParameter {
  final DartType _dartType;

  factory FunctionParameter.fromFormalParameter(FormalParameter parameter) {
    return new FunctionParameter._(parameter.element.type);
  }

  FunctionParameter._(this._dartType);

  /// The originating library.
  String get originLibraryName => _dartType.element.library.name;

  /// Type name.
  String get typeName => _dartType.element.name;
}

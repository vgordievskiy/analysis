library analysis.src.visitor;

import 'package:analysis/src/resolver.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as path;

/// A source visitor, that helps statically analyze and visit Dart source files.
class SourceVisitor {
  static final _dartSdk = DirectoryBasedDartSdk.defaultSdk;

  final AnalysisContext _context;
  final SourceResolver _sourceResolver;

  /// Create a new source visitor.
  ///
  /// If [sourceResolver] is not specified, uses the default.
  factory SourceVisitor({
      bool analyzeFunctionBodies: false,
      int cacheSize: 256,
      bool preserveComments: false,
      SourceResolver sourceResolver}) {
    if (sourceResolver == null) {
      sourceResolver = new SourceResolver();
    }
    final analysisOptions = new AnalysisOptionsImpl()
      ..analyzeFunctionBodies = analyzeFunctionBodies
      ..cacheSize = cacheSize
      ..preserveComments = preserveComments;
    final analysisContext = AnalysisEngine.instance.createAnalysisContext();
    analysisContext.analysisOptions = analysisOptions;
    _dartSdk.context.analysisOptions = analysisOptions;
    final sourceFactory = sourceResolver.createSourceFactory(dartSdk: _dartSdk);
    analysisContext.sourceFactory = sourceFactory;
    return new SourceVisitor._(analysisContext, sourceResolver);
  }

  SourceVisitor._(this._context, this._sourceResolver);

  /// Returns a library context.
  Library visit({String path, Uri uri}) {
    if (uri != null) {
      path = _sourceResolver.find(uri);
    }
    final file = new JavaFile(path);
    final source = new FileBasedSource.con1(file);
    final changeSet = new ChangeSet()..addedSource(source);
    _context.applyChanges(changeSet);
    final library = _context.computeLibraryElement(source);
    final astUnit = _context.getResolvedCompilationUnit(source, library);
    return new Library._(
        library.name,
        astUnit,
        this,
        parts: _getDirectiveUris(
            astUnit,
            (e) => e is PartDirective,
            path),
        imports: _getDirectiveUris(astUnit, (e) => e is ImportDirective),
        exports: _getDirectiveUris(astUnit, (e) => e is ExportDirective));
  }

  String _getFileLocation(Uri uri, [String relativeTo]) {
    if (uri == null || uri.scheme == 'dart') {
      return null;
    } else if (uri.scheme == 'package') {
      return _sourceResolver.find(uri);
    } else {
      if (relativeTo != null) {
        return path.join(path.dirname(relativeTo), uri.toFilePath());
      } else {
        return path.absolute(uri.toFilePath());
      }
    }
  }

  List<String> _getDirectiveUris(
      CompilationUnit astUnit,
      bool test(Directive directive),
      [String relativeTo]) {
    return astUnit.directives.where(test).map((UriBasedDirective directive) {
      return _getFileLocation(directive.source.uri, relativeTo);
    }).toList(growable: false);
  }
}

class Library {
  final CompilationUnit _astUnit;
  final SourceVisitor _sourceVisitor;

  final List<String> exports;
  final List<String> imports;
  final String name;
  final List<String> parts;

  List<CompilationUnit> _resolvedAstUnits;

  Library._(
      this.name,
      this._astUnit,
      this._sourceVisitor, {
      this.exports: const [],
      this.imports: const [],
      this.parts: const []});

  List<CompilationUnit> astUnits({bool resolveParts: false}) {
    if (!resolveParts) {
      return [_astUnit];
    } else {
      if (_resolvedAstUnits == null) {
        _resolvedAstUnits = [_astUnit];
        parts.forEach((partFile) {
          _resolvedAstUnits.add(_sourceVisitor.visit(path: partFile)._astUnit);
        });
      }
      return _resolvedAstUnits;
    }
  }

  @override
  String toString() => 'Library ' + {
    'name': name,
    'exports': exports,
    'imports': imports,
    'parts': parts
  }.toString();
}

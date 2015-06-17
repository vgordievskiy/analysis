library analysis.src.visitor;

import 'package:analysis/src/resolver.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/core.dart';

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

  /// Returns a library context by visiting and analyzing.
  ///
  /// If [path] is specified it is used, otherwise, [uri] is used.
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
        path,
        astUnit,
        this,
        parts: _getDirectiveUris(
            astUnit,
            (e) => e is PartDirective,
            path),
        imports: _getDirectiveUris(astUnit, (e) => e is ImportDirective),
        exports: _getDirectiveUris(astUnit, (e) => e is ExportDirective));
  }

  /// Returns the absolute file location of [uri].
  ///
  /// If [relativeTo] is specified, relative URIs are resolved using it.
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

  /// Returns all directive URIs from [astUnit] that pass [test].
  ///
  /// If [relativeTo] is specified, it is passed to [_getFileLocation].
  List<String> _getDirectiveUris(
      CompilationUnit astUnit,
      bool test(Directive directive),
      [String relativeTo]) {
    return astUnit.directives.where(test).map((UriBasedDirective directive) {
      return _getFileLocation(directive.source.uri, relativeTo);
    }).toList(growable: false);
  }
}

/// A parsed library.
class Library {
  final CompilationUnit _astUnit;
  final SourceVisitor _sourceVisitor;

  /// URIs of exports.
  final List<String> exports;

  /// URIs of imports.
  final List<String> imports;

  /// The library name.
  final String name;

  /// The absolute file path.
  final String path;

  /// URIs of parts.
  final List<String> parts;

  List<CompilationUnit> _resolvedAstUnits;

  Library._(
      this.name,
      this.path,
      this._astUnit,
      this._sourceVisitor, {
      this.exports: const [],
      this.imports: const [],
      this.parts: const []});

  /// Returns a list of all ASTs in the library.
  ///
  /// If [resolveParts] is false, the [parts] are not parsed and resolved.
  List<CompilationUnit> astUnits({bool resolveParts: true}) {
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
  bool operator==(o) {
    if (o is! Library) return false;
    return o.name == name && o.path == path;
  }

  @override
  int get hashCode => hash2(name, path);

  /// Gets the declaration named [name].
  Declaration getDeclaration(String name) {
    return _astUnit.declarations.firstWhere(
        (d) => d.element.displayName == name);
  }

  /// Returns the URI of this library.
  Uri get uri {
    // TODO: Cache.
    return _sourceVisitor._sourceResolver.resolve(path);
  }

  @override
  String toString() => 'Library ' + {
    'name': name,
    'exports': exports,
    'imports': imports,
    'parts': parts
  }.toString();
}

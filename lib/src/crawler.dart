library analysis.src.crawler;

import 'dart:collection';
import 'dart:io';

import 'package:analysis/src/resolver.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as path;

abstract class SourceCrawler implements Function {
  factory SourceCrawler() => new SourceCrawlerImpl();

  /// Resolves and crawls [path], and all files imported (recursively). Returns
  /// an [Iterable] of all the ASTs parsed.
  Iterable<CompilationUnit> call(String path);
}

/// A source code crawler.
class SourceCrawlerImpl implements SourceCrawler {
  static final _dartSdk = DirectoryBasedDartSdk.defaultSdk;

  final AnalysisContextImpl _context;
  final SourceResolver _sourceResolver;

  factory SourceCrawlerImpl({
      bool analyzeFunctionBodies: false,
      int cacheSize: 256,
      bool includeDefaultPackageRoot: true,
      List<String> packageRoots,
      bool preserveComments: false}) {
    if (packageRoots == null) {
      packageRoots = [Platform.packageRoot];
    }
    // Configure analysis options.
    final analysisOptions = new AnalysisOptionsImpl()
      ..analyzeFunctionBodies = analyzeFunctionBodies
      ..cacheSize = 256
      ..preserveComments = preserveComments;

    // Create a resolver to use.
    final sourceResolver = new SourceResolver.fromPackageRoots(
        packageRoots, includeDefaultPackageRoot);

    // Create a new analysis context.
    final context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions =
        _dartSdk.context.analysisOptions =
        analysisOptions;

    // Configure how we can load source files.
    context.sourceFactory = new SourceFactory([
      new DartUriResolver(_dartSdk),
      new FileUriResolver(),
      sourceResolver.packageUriResolver
    ]);

    // Return an instance we can use.
    return new SourceCrawlerImpl._(context, sourceResolver);
  }

  SourceCrawlerImpl._(this._context, this._sourceResolver);

  /// Crawls, starting at [path], invoking [crawlFile] for each file.
  @override
  Iterable<LibraryTuple> call(String path) {
    return crawl(_sourceResolver(path));
  }

  /// Crawls the absolute [entryPointFile]
  Iterable<LibraryTuple> crawl(
      String entryPointLocation, [
      bool deep = true]) {
    final entryPointFile = new JavaFile(entryPointLocation);
    final source = new FileBasedSource.con1(entryPointFile);
    final changeSet = new ChangeSet()..addedSource(source);
    _context.applyChanges(changeSet);

    final rootLib = _context.computeLibraryElement(source);
    final astUnit = _context.getResolvedCompilationUnit(source, rootLib);
    final visitQueue = new Queue<LibraryTuple>()
      ..add(new LibraryTuple(astUnit,
          _getPackageUri(entryPointLocation, source),
          entryPointFile.toString()));

    final results = <LibraryTuple>[];
    while (visitQueue.isNotEmpty) {
      final visitNext = visitQueue.removeFirst();
      results.add(visitNext);
      if (deep) {
        visitNext.astUnit.directives
          .where((directive) =>
            directive.element is ImportElement ||
            directive.element is ExportElement)
          .map((directive) => directive.element)
          .forEach((UriReferencedElement import) {
            final astUnit = visitSource(visitNext.fileImportedBy, import.uri);
            visitQueue.add(new LibraryTuple(
                astUnit,
                _getPackageUri(import.uri,
                    new FileBasedSource.con1(new JavaFile(_getFileLocation(
                        visitNext.fileImportedBy, import.uri)))),
                visitNext.fileImportedBy));
          });
      }
    }

    return results;
  }

  String _getFileLocation(String relativeTo, String uri) {
    if (uri == null || uri.startsWith('dart:')) {
      return null;
    } else if (uri.startsWith('package:')) {
      return _sourceResolver(uri);
    } else {
      return path.join(path.dirname(relativeTo), uri);
    }
  }

  String _getPackageUri(String importUri, Source source) {
    if (importUri.startsWith('package:') ||
        importUri.startsWith('dart:')) {
      return importUri;
    } else {
      return _sourceResolver
        .packageUriResolver
        .restoreAbsolute(source)
        .toString();
    }
  }

  CompilationUnit visitSource(String relativeTo, String uri) {
    final path = _getFileLocation(relativeTo, uri);
    if (path == null) {
      return new CompilationUnit(null, null, const [], const [], null);
    } else {
      return crawl(path, false).first.astUnit;
    }
  }
}

class LibraryTuple {
  final CompilationUnit astUnit;
  final String fileImportedBy;
  final String packageUri;

  LibraryTuple(this.astUnit, [this.packageUri, this.fileImportedBy]);

  @override
  String toString() => 'Library {${packageUri}}';
}

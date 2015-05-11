library analysis.src.crawler;

import 'dart:io';

import 'package:analysis/src/resolver.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';

/// A source code crawler.
class SourceCrawler implements Function {
  static final _dartSdk = DirectoryBasedDartSdk.defaultSdk;

  final AnalysisOptions _analysisOptions;
  final List<String> _packageRoots;
  final SourceResolver _sourceResolver;

  factory SourceCrawler({
      bool analyzeFunctionBodies: false,
      int cacheSize: 256,
      List<String> packageRoots,
      bool preserveComments: false}) {
    if (packageRoots == null) {
      packageRoots = [Platform.packageRoot];
    }
    final analysisOptions = new AnalysisOptionsImpl()
      ..analyzeFunctionBodies = analyzeFunctionBodies
      ..cacheSize = 256
      ..preserveComments = preserveComments;
    final sourceCrawler = new SourceResolver.fromPackageRoots(packageRoots);
    return new SourceCrawler._(packageRoots, analysisOptions, sourceCrawler);
  }

  SourceCrawler._(
      this._packageRoots,
      this._analysisOptions,
      this._sourceResolver);

  @override
  void call(String path) {
    // Create a new analysis context.
    final context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions =
        _dartSdk.context.analysisOptions =
        _analysisOptions;

    final entryPointFile = new JavaFile(_sourceResolver(path));
    final source = new FileBasedSource.con1(entryPointFile);
    final changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);

    print('>>> $source');
    final rootLib = context.computeLibraryElement(source);
    final astUnit = context.getResolvedCompilationUnit(source, rootLib);
    print('>>> So far: $entryPointFile | $rootLib | \n $astUnit');
  }
}

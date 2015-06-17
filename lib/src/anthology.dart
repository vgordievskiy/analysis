library analysis.src.anthology;

import 'package:analysis/src/crawler.dart';
import 'package:analysis/src/resolver.dart';
import 'package:analysis/src/visitor.dart';
import 'package:analyzer/src/generated/element.dart';

// TODO: Consider pulling this into a separate library if it gets out of hand.

/// A utility class for analysis.
///
/// Handles both caching and canonization of an analyzed applications.
class Anthology implements SourceCrawler, SourceVisitor {
  final _cachedLibrariesByPath = <String, Library> {};
  final _resolvedDartTypes = <String, Library> {};
  final SourceResolver _sourceResolver;

  SourceCrawler _cachedSourceCrawler;
  SourceVisitor _cachedSourceVisitor;

  /// Create a new anthology using [resolver], creating one if not supplied.
  factory Anthology({SourceResolver resolver}) {
    if (resolver == null) {
      resolver = new SourceResolver();
    }
    return new Anthology._(resolver);
  }

  Anthology._(this._sourceResolver);

  /// Given a [dartType], returns the [Library] that declared it.
  Library getLibraryOfType(DartType dartType) {
    var cacheKey = dartType.element.library.name + '|' + dartType.displayName;
    var library = _resolvedDartTypes[cacheKey];
    if (library == null) {
      var typeSourcePath = dartType.element.library.source.toString();
      library = visit(path: typeSourcePath);
      _resolvedDartTypes[cacheKey] = library;
    }
    return library;
  }

  /// Lazy initialize and return a [SourceCrawler].
  SourceCrawler get _sourceCrawler {
    if (_cachedSourceCrawler == null) {
      _cachedSourceCrawler = new SourceCrawler(this);
    }
    return _cachedSourceCrawler;
  }

  /// Lazy initialize and return a [SourceVisitor].
  SourceVisitor get _sourceVisitor {
    if (_cachedSourceVisitor == null) {
      _cachedSourceVisitor = new SourceVisitor(sourceResolver: _sourceResolver);
    }
    return _cachedSourceVisitor;
  }

  @override
  Iterable<Library> crawl({String path, Uri uri}) {
    return _sourceCrawler.crawl(path: path, uri: uri);
  }

  @override
  Library visit({String path, Uri uri}) {
    // Optimizes over the normal source visitor by caching all paths.
    Library library;
    if (path == null) {
      path = _sourceResolver.find(uri);
    }
    library = _cachedLibrariesByPath[path];
    if (library == null) {
      library = _sourceVisitor.visit(path: path);
      _cachedLibrariesByPath[path] = library;
    }
    return library;
  }
}

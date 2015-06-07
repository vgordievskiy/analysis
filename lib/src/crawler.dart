library analysis.src.crawler;

import 'package:analysis/src/visitor.dart';

/// A utility for recursively visiting many files - see [crawl].
class SourceCrawler {
  final SourceVisitor _sourceVisitor;

  /// Create a new crawler.
  ///
  /// Optionally specify a specific [sourceVisitor] to use.
  factory SourceCrawler([SourceVisitor sourceVisitor]) {
    if (sourceVisitor == null) {
      sourceVisitor = new SourceVisitor();
    }
    return new SourceCrawler._(sourceVisitor);
  }

  SourceCrawler._(this._sourceVisitor);

  /// Visits the file specified at either [path] or [uri], and recursively
  /// visits all [Library.imports], a maximum of once.
  ///
  /// The returned iterable has every [Library] parsed.
  Iterable<Library> crawl({String path, Uri uri}) {
    final visited = <String, Library> {};
    final root = _sourceVisitor.visit(path: path, uri: uri);
    _visit(visited, root);
    return visited.values;
  }

  void _visit(Map<String, Library> visited, Library library) {
    visited[library.path] = library;
    library.imports.forEach((import) {
      // TODO: Figure out where this is coming from.
      if (import == null) return;
      if (!visited.containsKey(import)) {
        library = _sourceVisitor.visit(path: import);
        _visit(visited, library);
      }
    });
  }
}

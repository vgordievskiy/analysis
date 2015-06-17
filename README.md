analysis
===

[![Build Status](https://drone.io/github.com/matanlurey/analysis/status.png)](https://drone.io/github.com/matanlurey/analysis/latest)

A set of utility classes to make common use cases of using the Dart `analyzer`
package simpler and without needing intimate knowledge of the internals.

SourceResolver
---

### Creating a resolver.

```dart
// Create a default source resolver.
new SourceResolver();

// Create a source resolver with custom Dart package roots.
new SourceResolver(['/generated-files'])
```

### Resolving a file to it's absolute location.

```dart
// Example output: ~/git/analysis/packages/analysis/src/resolver.dart
sourceResolver.find(Uri.parse('package:analysis/src/resolver.dart'));
```

### Finding the package location

```dart
// Example output: package:analysis/src/resolver.dart
sourceResolver.resolve('~/git/analysis/packages/analysis/src/resolver.dart');
```

SourceVisitor
---

### Creating a visitor.

```dart
// Create a default source crawler.
new SourceVisitor();
```

### Crawl a file for libraries.

```dart
// Example output: [
//   new Library(..., 'package:analysis/src/test_data/test_data.dart'),
//   new Library(..., 'dart:collection'),
//   new Library(..., 'package:analysis/src/test_data/test_import.dart')
// ]
var uri = Uri.parse('package:analysis/src/test_data/test_data.dart');
sourceVisitor.visit(uri: uri)
```

SourceCrawler
---

Similar to `SourceVisitor`; recursively searches into imports of the visited
file, and returns an iterable of every library parsed.

```dart
// Example output: [
//   Library(name: foo.bar),
//   Library(name: foo.baz)
// ]
sourceCrawler.crawl('package:foo/foo.dart')
```

Anthology
---

**Experimental** API for application-wide analysis. Instead of using both
`SourceVisitor` and/or `SourceCrawler` directly, `Anthology` helps build a
collection of analyzed libraries.

```dart
// Create a new Anthology.
new Anthology(resolver: ...)
```

It exposes both the `SourceVisitor` and `SourceCrawler` APIs, but also caches
results whenever possible to make visiting and crawling the same packages
cheaper.

It's also possible to trace a type back to it's library:

```dart
anthology.getLibraryOfType(classAst.element.type)
```

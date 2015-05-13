analysis
===

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
sourceResolver('package:analysis/src/resolver.dart');
```

SourceCrawler
---

### Creating a crawler.

```dart
// Create a default source crawler.
new SourceCrawler();

// Create a source crawler with custom options.
new SourceCrawlerImpl(
    analyzeFunctionBodies: false,
    cacheSize: 256,
    packageRoots: ['/generated-files'],
    preserveComments: false);
```

### Crawl a file for libraries.

```dart
// Example output: [
//   new LibraryTuple(..., 'package:analysis/src/test_data/test_data.dart'),
//   new LibraryTuple(..., 'dart:collection'),
//   new LibraryTuple(..., 'package:analysis/src/test_data/test_import.dart')
// ]
sourceCrawler('package:analysis/src/test_data/test_data.dart')
```

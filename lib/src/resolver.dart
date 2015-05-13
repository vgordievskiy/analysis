library analysis.src.resolver;

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';

/// A source code file resolver.
class SourceResolver implements Function {
  static final _defaultPackageRoots = [Platform.packageRoot];
  static const _filePrefix = 'file:/';
  static const _packagePrefix = 'package:';

  // TODO: Make private.
  final PackageUriResolver packageUriResolver;

  /// Create a new default source resolver.
  factory SourceResolver() {
    return new SourceResolver.fromPackageRoots(_defaultPackageRoots);
  }

  /// Create a source resolver using the supplied as package roots.
  factory SourceResolver.fromPackageRoots(
      Iterable<String> packageRoots, [
      bool includeDefaultPackageRoot = true]) {
    final concatPackageRoots = packageRoots.toList();
    if (includeDefaultPackageRoot) {
      concatPackageRoots.addAll(_defaultPackageRoots);
    }
    return new SourceResolver._(_createResolver(concatPackageRoots));
  }

  SourceResolver._(this.packageUriResolver);

  /// Resolve and returns [path]. For example:
  ///     // Returns (for example) /home/ubuntu/user/libs/analysis/analysis.dart
  ///     resolver('package:analysis/analysis.dart')
  String call(String path) {
    // Translate path to an absolute path.
    if (path.startsWith(_packagePrefix)) {
      var uri = Uri.parse(path);
      path = packageUriResolver.resolveAbsolute(uri).toString();
      final filePathIndex = path.indexOf(_filePrefix);
      if (filePathIndex != -1) {
        path = path.substring(filePathIndex + _filePrefix.length - 1);
      }
    } else {
      throw new ArgumentError.value(path, 'path', 'Not in "package:" format.');
    }
    return new JavaFile(path).getAbsolutePath();
  }

  /// Creates and returns a URI resolver.
  static PackageUriResolver _createResolver([Iterable<String> packageRoots]) {
    final packageRootResolvers = packageRoots.map((packageRoot) {
      return new JavaFile.fromUri(new Uri.file(packageRoot));
    }).toList(growable: false);
    return new PackageUriResolver(packageRootResolvers);
  }
}

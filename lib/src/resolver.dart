library analysis.src.resolver;

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';

/// A source code file resolver.
class SourceResolver implements Function {
  static final _defaultPackageRoots = [Platform.packageRoot];
  static const _filePrefix = 'file:/';
  static const _packagePrefix = 'package:';

  final List<String> _packageRoots;

  /// Create a new default source resolver.
  factory SourceResolver() {
    return new SourceResolver.fromPackageRoots(_defaultPackageRoots);
  }

  /// Create a source resolver using the supplied as package roots.
  SourceResolver.fromPackageRoots(
      Iterable<String> packageRoots, [
      bool useDartSdk = true])
          : _packageRoots = useDartSdk ?
                ([]..addAll(packageRoots)..addAll(_defaultPackageRoots))
                : packageRoots.toList(growable: false);

  /// Resolve and returns [path]. For example:
  ///     // Returns (for example) /home/ubuntu/user/libs/analysis/analysis.dart
  ///     resolver('package:analysis/analysis.dart')
  String call(String path) {
    // Create and register URI resolvers.
    final packageRootResolvers = _packageRoots.map((packageRoot) {
      return new JavaFile.fromUri(new Uri.file(packageRoot));
    }).toList(growable: false);
    final packageUriResolver = new PackageUriResolver(packageRootResolvers);

    // Translate path to an absolute path.
    JavaFile file;
    if (path.startsWith(_packagePrefix)) {
      var uri = Uri.parse(path);
      path = packageUriResolver.resolveAbsolute(uri).toString();
      final filePathIndex = path.indexOf(_filePrefix);
      if (filePathIndex != -1) {
        path = path.substring(filePathIndex + _filePrefix.length - 1);
      }
      file = new JavaFile(path);
    } else {
      file = new JavaFile(path);
    }

    return file.getAbsolutePath();
  }
}

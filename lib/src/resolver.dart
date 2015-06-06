library analysis.src.resolver;

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/sdk.dart';

/// A source code file resolver.
class SourceResolver {
  static final _defaultPackageRoots = [Platform.packageRoot];

  final PackageUriResolver _packageUriResolver;

  /// Creates and returns a URI resolver from [packageRoots].
  static PackageUriResolver _createResolver([Iterable<String> packageRoots]) {
    final packageRootResolvers = packageRoots.map((packageRoot) {
      return new JavaFile.fromUri(new Uri.file(packageRoot));
    }).toList(growable: false);
    return new PackageUriResolver(packageRootResolvers);
  }

  /// Creates a default resolver, only using the platform package root.
  factory SourceResolver() => new SourceResolver.fromPackageRoots(const []);

  /// Creates a resolver form [packageRoots].
  factory SourceResolver.fromPackageRoots(
      Iterable<String> packageRoots, {
      bool includeDefaultPackageRoot: true}) {
    final concatPackageRoots = packageRoots.toList();
    if (includeDefaultPackageRoot) {
      concatPackageRoots.addAll(_defaultPackageRoots);
    }
    return new SourceResolver._(_createResolver(concatPackageRoots));
  }

  SourceResolver._(this._packageUriResolver);

  /// Return an instance of [SourceFactory] that uses the current package
  /// resolution logic and one for [dartSdk].
  SourceFactory createSourceFactory({
      Iterable<UriResolver> addUriResolvers: const [],
      DartSdk dartSdk,
      bool useFileResolver: true}) {
    final resolvers = <UriResolver> [];
    if (dartSdk != null) {
      resolvers.add(new DartUriResolver(dartSdk));
    }
    if (useFileResolver) {
      resolvers.add(new FileUriResolver());
    }
    resolvers.add(_packageUriResolver);
    resolvers.addAll(addUriResolvers);
    return new SourceFactory(resolvers);
  }

  /// Given a [uri], returns a fully qualified file path.
  ///
  /// Example:
  ///     resolve(new Uri('package:a/b/c.dart')) // ==> a/b/c.dart
  String find(Uri uri) {
    if (uri == null) {
      throw new ArgumentError.notNull();
    }
    // Translate uri to an absolute path.
    final source = _packageUriResolver.resolveAbsolute(uri);
    return source.toString();
  }

  /// Given an absolute file [path], returns the package [Uri].
  ///
  /// Example:
  ///     resolve('a/b/c.dart') // ==> package:a/b/c.dart
  Uri resolve(String path) {
    final source = new FileBasedSource.con1(new JavaFile(path));
    return _packageUriResolver.restoreAbsolute(source);
  }
}

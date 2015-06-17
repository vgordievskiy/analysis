library analysis.src.resolver;

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/sdk.dart';

/// A source code file resolver.
class SourceResolver {
  static final _defaultPackageRoots = [Platform.packageRoot];

  final _uriFromPathCache = <String, Uri> {};
  final PackageUriResolver _packageUriResolver;

  /// Creates and returns a URI resolver from [packageRoots].
  static PackageUriResolver _createResolver([Iterable<String> packageRoots]) {
    final packageRootResolvers = packageRoots.map((packageRoot) {
      return new JavaFile(packageRoot);
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

  /// Due to how pub run sets the package root, use this constructor to create
  /// a resolver that strictly deals with the default package root and applies
  /// light massaging in order to avoid environment errors.
  factory SourceResolver.forTesting() {
    // TODO: Find why this happens and remove this.
    var customPackageRoot = Platform.packageRoot.toString();
    customPackageRoot = customPackageRoot.replaceFirst('file://', '');
    final resolver = new SourceResolver.fromPackageRoots([
      customPackageRoot,
    ], includeDefaultPackageRoot: false);
    return resolver;
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
    var path = source.toString();

    // TODO: Figure out why this happens, and fix it.
    if (path.contains('file:')) {
      path = path.split('file:').last;
    }
    return path;
  }

  /// Given an absolute file [path], returns the package [Uri].
  ///
  /// Example:
  ///     resolve('a/b/c.dart') // ==> package:a/b/c.dart
  Uri resolve(String path) {
    var uri = _uriFromPathCache[path];
    if (uri == null) {
      final source = new FileBasedSource.con1(new JavaFile(path));
      uri = _packageUriResolver.restoreAbsolute(source);
      // TODO: Remove hack.
      if (uri.path.startsWith('packages')) {
        uri = new Uri(
            scheme: uri.scheme,
            path: uri.path.replaceFirst('packages/', ''));
      }
      _uriFromPathCache[path] = uri;
    }
    return uri;
  }
}

library analysis.test.resolver_test;

import 'dart:io';

import 'package:analysis/src/resolver.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('SourceResolver', () {
    final sourceResolver = new SourceResolver();
    final uri = Uri.parse('package:analysis/src/resolver.dart');

    test('can find the path to resolver.dart', () async {
      final absolutePath = sourceResolver.find(uri);
      expect(absolutePath, endsWith('resolver.dart'));
      final String file = await new File(absolutePath).readAsString();
      expect(file, startsWith('library analysis.src.resolver;'));
    });

    test('can find the URI based on a file path', () async {
      final absolutePath = path.normalize(path.join(
          path.current,
          'lib',
          'src',
          'resolver.dart'));
      expect(sourceResolver.resolve(absolutePath), uri);
    });
  });
}

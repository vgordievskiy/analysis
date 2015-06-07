library analysis.test.visitor_test;

import 'package:analysis/src/visitor.dart';
import 'package:test/test.dart';

void main() {
  group('SourceVisitor', () {
    SourceVisitor visitor;

    setUp(() {
      visitor = new SourceVisitor();
    });

    test('works as intended', () {
      final uri = Uri.parse('package:analysis/testing/library/a.dart');
      final lib = visitor.visit(uri: uri);
      expect(lib.name, 'lib_a');
      expect(lib.parts.single, endsWith('a_part.dart'));
      expect(lib.imports.first, endsWith('b.dart'));
      expect(lib.imports.last, endsWith('c.dart'));
      expect(lib.exports.single, endsWith('d.dart'));
    });

    test('can resolve all ASTs, including parts', () {
      final uri = Uri.parse('package:analysis/testing/library/a.dart');
      final lib = visitor.visit(uri: uri);
      return expect(lib.astUnits(resolveParts: true), hasLength(2));
    });
  });
}

library analysis.test.canonicalizer_test;

import 'package:analysis/src/anthology.dart';
import 'package:analysis/src/resolver.dart';
import 'package:analysis/src/utils.dart';
import 'package:analyzer/analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('Anthology', () {
    final uri = Uri.parse('package:analysis/testing/library/canon.dart');

    Anthology anthology;

    setUp(() {
      anthology = new Anthology(resolver: new SourceResolver.forTesting());
    });

    test('can resolve types to their library', () {
      var library = anthology.visit(uri: uri);
      var astUnit = library.astUnits().first;
      var fooType = getDartType(astUnit.declarations[1]);
      var libOfFoo = anthology.getLibraryOfType(fooType);
      expect(libOfFoo.name, 'canon_test_data');

      // Verify the result is cached.
      expect(identical(libOfFoo, anthology.getLibraryOfType(fooType)), isTrue);

      // Check the annotation.
      ClassDeclaration barClass = astUnit.declarations[2];
      var annotation = barClass.metadata.first;
      SimpleIdentifier metadataArgument = annotation.arguments.arguments.first;
      var mysteryType = metadataArgument.bestElement;

      // It should be Foo, which is the same library, again.
      expect(anthology.getLibraryOfType(mysteryType.type), libOfFoo);
    });

    test('can resolve types within imports', () {
      var library = anthology.visit(uri: uri);
      var astUnit = library.astUnits().first;
      var barClass = astUnit.declarations[2];
      var annotation = barClass.metadata.last;
      SimpleIdentifier metadataArgument = annotation.arguments.arguments.first;
      var mysteryType = metadataArgument.bestElement;

      var someLib = anthology.getLibraryOfType(mysteryType.type);
      expect(someLib.name, 'analysis.testing.library.canon_import');
      expect(someLib.path, endsWith('canon_import.dart'));
    });

    test('can resolve types within parts', () {
      var library = anthology.visit(uri: uri);
      var astUnit = library.astUnits().first;
      var fooClass = astUnit.declarations[1];
      var annotation = fooClass.metadata.first;
      SimpleIdentifier metadataArgument = annotation.arguments.arguments.first;
      var mysteryType = metadataArgument.bestElement;

      // It should be treated as if it is in the library, not part file.
      var someLib = anthology.getLibraryOfType(mysteryType.type);
      expect(someLib.name, 'canon_test_data');
    });
  });
}

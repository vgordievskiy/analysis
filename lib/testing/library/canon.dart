library canon_test_data;

import 'package:analysis/testing/library/canon_import.dart';

part 'canon_part.dart';

class Annotation {
  final Type type;
  const Annotation(this.type);
}

@Annotation(Buzz)
class Foo {}

@Annotation(Foo)
@Annotation(Baz)
class Bar {
  static void bar(Foo foo) {}
}

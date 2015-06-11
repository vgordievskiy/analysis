library lib_a;

import 'b.dart';
import 'package:analysis/testing/library/c.dart';
export 'package:analysis/testing/library/d.dart';

part 'a_part.dart';

class AClass implements APartClass, BClass {
  AClass(APartClass aInstance, BClass bInstance, List coreList);
}

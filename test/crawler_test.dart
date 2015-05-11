library analysis.test.resolver_test;

import 'package:analysis/src/crawler.dart';
import 'package:test/test.dart';

void main() {
  group('SourceCrawler', () {
    final sourceCrawler = new SourceCrawler();

    test('can run on test_data.dart', () async {
      sourceCrawler('package:analysis/src/test_data/test_data.dart');
    });
  });
}

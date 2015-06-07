library analysis.test.crawler_test;

import 'dart:io';

import 'package:analysis/src/crawler.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('SourceCrawler', () {
    final sourceCrawler = new SourceCrawler();

    test('can crawl a file', () {
      final uri = Uri.parse('package:analysis/testing/library/a.dart');
      final libraries = sourceCrawler.crawl(uri: uri).toList(growable: false);
      expect(libraries.map((e) => e.name), [
        'lib_a',
        'lib_b',
        'lib_c'
      ]);
    });
  });
}

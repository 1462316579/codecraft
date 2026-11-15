import 'package:flutter_test/flutter_test.dart';

import 'package:codecraft/data/capture/capture_models.dart';
import 'package:codecraft/data/capture/capture_store.dart';

void main() {
  test('超出上限后索引与主机统计保持一致', () {
    final store = CaptureStore(maxFlows: 3);
    for (var i = 0; i < 5; i++) {
      store.add(CaptureFlow(
        id: 'f$i',
        startedAt: DateTime.now(),
        method: 'GET',
        url: 'https://h$i.test/',
        host: 'h$i.test',
        path: '/',
      ));
    }
    // 只保留最近 3 条,被淘汰的不能再通过 id 查到。
    expect(store.count, 3);
    expect(store.get('f0'), isNull);
    expect(store.get('f4')?.id, 'f4');

    store.update(CaptureFlow(
      id: 'f4',
      startedAt: DateTime.now(),
      method: 'GET',
      url: 'https://h4.test/',
      host: 'h4.test',
      path: '/',
      statusCode: 200,
    ));
    expect(store.get('f4')?.statusCode, 200);

    store.remove('f2');
    expect(store.count, 2);
    expect(store.get('f3')?.id, 'f3');
    expect(store.hostCounts['h4.test'], 1);
    expect(store.hostCounts.containsKey('h2.test'), isFalse);
  });
}

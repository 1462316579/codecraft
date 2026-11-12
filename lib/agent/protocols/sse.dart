import 'dart:async';

/// SSE(Server-Sent Events)行流解析。
///
/// 输入是按行切分的响应体;输出是每个事件的 data 负载(多行 data 以换行拼接)。
/// 忽略注释行(`:` 开头)与其它字段(`event:` / `id:` / `retry:`),
/// 因为本项目依赖的三家 API 都会在 data 的 JSON 里自带事件类型字段。
///
/// 注意:这里刻意用 `StreamTransformer` 而不是 async* 生成器实现——
/// 生成器在「反复过滤、长时间不产出」的循环里无法及时响应订阅取消(实测会挂住),
/// 变换器则把 pause/resume/cancel 直接透传给上游流。
Stream<String> sseDataEvents(Stream<String> lines) {
  final buffer = StringBuffer();
  return lines.transform(
    StreamTransformer<String, String>.fromHandlers(
      handleData: (line, sink) {
        // LineSplitter 只按 \n 切分,CRLF 会留下行尾 \r
        final value = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
        if (value.isEmpty) {
          if (buffer.isNotEmpty) {
            sink.add(buffer.toString());
            buffer.clear();
          }
          return;
        }
        if (value.startsWith(':')) return;
        if (value.startsWith('data:')) {
          var payload = value.substring(5);
          if (payload.startsWith(' ')) payload = payload.substring(1);
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(payload);
        }
      },
      handleDone: (sink) {
        if (buffer.isNotEmpty) {
          sink.add(buffer.toString());
          buffer.clear();
        }
        sink.close();
      },
    ),
  );
}
/// 简单的字节队列，用于终端输出缓冲。
class ByteQueue {
  final List<int> _buffer = [];
  int _readIndex = 0;

  int get length => _buffer.length - _readIndex;
  bool get isEmpty => _readIndex >= _buffer.length;

  void write(int b) {
    _buffer.add(b & 0xFF);
  }

  void writeAll(List<int> bytes) {
    _buffer.addAll(bytes);
  }

  int read() {
    if (isEmpty) return -1;
    return _buffer[_readIndex++];
  }

  void clear() {
    _buffer.clear();
    _readIndex = 0;
  }

  // 定期压缩以避免列表无限增长
  void compact() {
    if (_readIndex > 0) {
      _buffer.removeRange(0, _readIndex);
      _readIndex = 0;
    }
  }
}

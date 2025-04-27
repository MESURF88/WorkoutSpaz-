class CircularBuffer<T> {
  final int size;
  final List<T?> _buffer;
  int _index = 0;
  bool _isFull = false;

  CircularBuffer(this.size) : _buffer = List<T?>.filled(size, null, growable: false);

  void add(T item) {
    _buffer[_index] = item;
    _index = (_index + 1) % size;
    if (_index == 0) {
      _isFull = true;
    }
  }

  List<T> toList() {
    if (!_isFull) {
      return _buffer.take(_index).whereType<T>().toList();
    } else {
      return (_buffer.sublist(_index) + _buffer.sublist(0, _index)).whereType<T>().toList();
    }
  }
}
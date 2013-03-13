/*
  Copyright (C) 2012 Daniel Rodriguez <seth.illgard@gmail.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

part of property_map;

/**
 * Wrapper around List<dynamic>.
 *
 * Only numbers, booleans, Strings, Lists(recursive), Maps(recursive) and types
 * that implement Serializable are allowed as entries on a PropertyContainer,
 * unless _allowNonSerializables is set to true ont he configuration object,
 * in which case, serialization is disabled.
 */
class PropertyList extends PropertyContainer implements List<dynamic> {

  // The actual list that holds the elements.
  List _objectData;

  /**
   *  Default constructor.
   */
  PropertyList([PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    _configuration = configuration;
    _objectData = new List();
  }

  /**
   * Contructs a PropertyList from any Iterable, creating a copy of it.
   */
  PropertyList._from(Iterable other, [PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    _configuration = configuration;
    _objectData = new List.from(other);
    for (var i = 0; i < _objectData.length; i++) {
      _objectData[i] = _validate(_objectData[i]);
    }
  }

  // Implementation of List
  forEach(func(dynamic value)) => _objectData.forEach(func);
  int get length => _objectData.length;
  bool get isEmpty => _objectData.isEmpty;
  clear() => _objectData.clear();
  bool every(bool f(element)) => _objectData.every(f);
  reduce(initialValue, combine(prevValue, element)) =>
      _objectData.reduce(initialValue, combine);
  bool contains(dynamic element) => _objectData.contains(element);
  void set length(int value) { _objectData.length = value; }
  dynamic get first => _objectData.first;
  dynamic get last => _objectData.last;
  void add(dynamic value) => _objectData.add(_validate(value));
  void addLast(dynamic value) => _objectData.add(_validate(value));
  void addAll(Collection<dynamic> collection) {
    for (var item in collection) {
      _objectData.add(_validate(item));
    }
  }
  void sort([Comparator compare = Comparable.compare]) =>
      _objectData.sort(compare);
  int indexOf(dynamic element, [int start = 0]) =>
      _objectData.indexOf(element, start);
  int lastIndexOf(dynamic element, [int start = 0]) =>
      _objectData.lastIndexOf(element, start);
  dynamic removeAt(int index) => _objectData.removeAt(index);
  dynamic removeLast() => _objectData.removeLast();
  List<dynamic> getRange(int start, int length) =>
      _objectData.getRange(start, length);
  void setRange(int start, int length, List<dynamic> from, [int startFrom]) =>
      _objectData.setRange(start, length, _validate(from), startFrom);
  void removeRange(int start, int length) =>
      _objectData.removeRange(start, length);
  void insertRange(int start, int length, [dynamic initialValue]) =>
      _objectData.insertRange(start, length, _validate(initialValue));
  operator [](int index) => _objectData[index];
  operator []=(int index, dynamic value) {
    _objectData[index] = _validate(value);
  }
  void remove(Object element) => _objectData.remove(element);
  void removeAll(Iterable<dynamic> elements) => _objectData.removeAll(elements);
  void retainAll(Iterable<dynamic> elements) => _objectData.retainAll(elements);
  void removeMatching(bool test(dynamic)) => _objectData.removeMatching(test);
  void retainMatching(bool test(dynamic)) => _objectData.retainMatching(test);
  Iterator<dynamic> get iterator => _objectData.iterator;
  dynamic get single => _objectData.single;
  Iterable<dynamic> mappedBy(dynamic f(dynamic)) => _objectData.map(f);
  Iterable<dynamic> map(dynamic f(dynamic)) => _objectData.map(f);
  Iterable<dynamic> where(bool f(dynamic)) => _objectData.where(f);
  String join([String separator]) => _objectData.join(separator);
  bool any(bool f(dynamic)) => _objectData.any(f);
  List<dynamic> toList({ bool growable: true }) => _objectData.toList(growable: growable);
  Set<dynamic> toSet() => _objectData.toSet();
  dynamic min([int compare(dynamic a, dynamic b)]) => _objectData.min(compare);
  dynamic max([int compare(dynamic a, dynamic b)]) => _objectData.max(compare);
  Iterable<dynamic> take(int n) => _objectData.take(n);
  Iterable<dynamic> takeWhile(bool test(dynamic)) =>
      _objectData.takeWhile(test);
  Iterable<dynamic> skip(int n) => _objectData.skip(n);
  Iterable<dynamic> skipWhile(bool test(dynamic)) =>
      _objectData.skipWhile(test);
  dynamic firstMatching(bool test(dynamic), {dynamic orElse()}) =>
      _objectData.firstMatching(test, orElse:orElse);
  dynamic lastMatching(bool test(dynamic), {dynamic orElse()}) =>
      _objectData.lastMatching(test, orElse:orElse);
  dynamic singleMatching(bool test(dynamic)) =>
      _objectData.singleMatching(test);
  dynamic elementAt(int index) => _objectData.elementAt(index);
  List<dynamic> get reversed => _objectData.reversed;


  /**
   * Adds an element at the end of the PropertyList. It can be then
   * repositioned.
   *
   * Use this to override the configuration object. Bear in mind that calling
   * this method will change the configuration to indicate that we can longer
   * guarantee serialization.
   */
  void addRawElement(dynamic value) {
    _hasRawElements = true;
    _objectData.add(value);
  }

  /**
   * Serialize.
   */
  String toJson() {
    if (_hasRawElements || !_configuration.canGuaranteeSerialization()) {
      throw 'Calling toString() on a PropertyList that allows arbitrary '
      'objects is not supported because we cannot gurantee that they will be '
      'Serializable. If you want Serialization enabled, make sure you are '
      'using the default configuration and not calling addRawElement()';
    }

    var buffer = new StringBuffer();
    buffer.write('[');
    for (var i = 0; i < _objectData.length ; i++) {
      if (i > 0) {
        buffer.write(',');
      }
      var value = _objectData[i];
      if (value is num || value is bool) {
        buffer.write(value);
      }
      else if (value is String) {
        buffer.write('"${value}"');
      }
      else if (value is Serializable) {
        buffer.write(value.toJson());
      }
      else {
        var mirror = reflect(value);
        throw 'Unexpected value found on a PropertyList. Type found: '
        '${mirror.type.simpleName}.';
      }
    }
    buffer.write(']');
    return buffer.toString();
  }

  dynamic toString() {
    return 'PropertyList:${_objectData.toString()}';
  }
}

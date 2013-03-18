/*
  Copyright (C) 2012 Daniel Rodr√≠guez <seth.illgard@gmail.com>

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
 * Wrapper around a Map<String, dynamic>.
 *
 * Only numbers, booleans, Strings, Lists(recursive), Maps(recursive) and types
 * that implement Serializable are allowed as entries on a PropertyContainer,
 * unless _allowNonSerializables is set to true ont he configuration object,
 * in which case, serialization is disabled.
 */
class PropertyMap extends PropertyContainer implements Map<String, dynamic> {

  // The actual map that holds the elements.
  Map<String, dynamic> _objectData;

  /**
   * Returns the passed value if it is a an acceptable entry for a
   * PropertyContainer given the specified configuration, a 'promoted' version
   * of the passed value (List->PropertyList, Map->PropertyMap), or a custom
   * object constructed using the passed value if a custom deserializer was
   * registred for its type.
   *
   * If the value is a Map or a List, it will be converted into a PropertyMap or
   * a PropertyList (recursively), unless specified otherwise onto the config
   * object.
   *
   * If the value is a Map with a '_type_' field, it will execute the registred
   * customDeserializer for that type, unless specified otherwise in the config
   * object.
   *
   * If the value is not a Map, List, String, bool, num, null, or an instance
   * implementing Serializable and the config does not allow nonSerializable
   * objects, it throws an exception.
   */
  static dynamic promote(dynamic value,
                       [PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    return PropertyContainer._promote(value, configuration);
  }

  /**
   * Parses a Json string and returns the object representation of it.
   *
   * Most likely it will return a PropertyMap, except if the top level map in
   * the string has a "_type_" field, in which it will return the object
   * returned by the custom deserializer registered for that type.
   */
  static dynamic parseJson(String json,
                           [PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    return promote(JSON.parse(json), configuration);
  }

  /**
   * Registers a new custom deserializer for a _type_
   */
  static void registerCustomDeserializer(String type,
                                         Deserializer deserializer) {
    PropertyContainer._registerCustomDeserializer(type, deserializer);
  }

  /**
   *  Default constructor.
   */
  PropertyMap([PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    _configuration = configuration;
    _objectData = new Map();
  }

  /**
   * Contructs a PropertyMap from another Map, creating a copy of it.
   *
   * Note: This constructor cannot use custom deserializers for the top level
   * map. Use parse PropertyMap.promote() if you need a custom deserializer for
   * the top level object.
   */
  PropertyMap._from(Map<String, dynamic> other,
                    [PropertyMapConfig configuration = null]) {
    if (configuration == null) {
      configuration = PropertyMapConfig.defaultValue;
    }
    _configuration = configuration;
    _objectData = new Map.from(other);
    for (var key in _objectData.keys) {
      assert(key is String);
      _objectData[key] = _validate(_objectData[key]);
    }
  }

  // Implementation of Map<String, dynamic>
  bool containsValue(dynamic value) => _objectData.containsValue(value);
  bool containsKey(String key) => _objectData.containsKey(key);
  forEach(func(String key, dynamic value)) => _objectData.forEach(func);
  Iterable<String> get keys => _objectData.keys;
  Iterable<dynamic> get values => _objectData.values;
  int get length => _objectData.length;
  bool get isEmpty => _objectData.isEmpty;
  putIfAbsent(String key,ifAbsent()) {
    _objectData.putIfAbsent(key, () {
      _validate(ifAbsent());
    });
  }
  clear() => _objectData.clear();
  remove(String key) => _objectData.remove(key);
  operator [](String key) => _objectData[key];
  operator []=(String key, dynamic value) {
    _objectData[key] = _validate(value);
  }

  /**
   * Adds an element at to this PropertyMap.
   *
   * Use this to override the configuration object. Bear in mind that calling
   * this method will change the configuration to indicate that we can longer
   * guarantee serialization.
   */
  void addRawElement(String key, dynamic value) {
    _hasRawElements = true;
    _objectData[key] = value;
  }

  /**
   * Implementing noSuchMethod allows invocations on this object in a more
   * natural way:
   *  - print(data.propertyName);
   *  - data.propertyName = value;
   * instead of:
   *  - print(data.get('propertyName'));
   *  - data.set('propertyName', value);
   */
  noSuchMethod(InvocationMirror mirror) {
    if (mirror.isGetter) {
      var property = mirror.memberName;
      if (this.containsKey(property)) {
        return this[property];
      }
    } else if (mirror.isSetter) {
      // Remove a nasty '=' that is always added at the end for some reason.
      var property = mirror.memberName.slice(0, -1);
      this[property] = mirror.positionalArguments[0];
      return this[property];
    }

    // The property does not exist.
    print("Not found: ${mirror.memberName} in $this");
    print("IsGetter: ${mirror.isGetter}");
    print("IsSetter: ${mirror.isSetter}");
    print("isAccessor: ${mirror.isAccessor}");
    super.noSuchMethod(mirror);
  }

  /**
   * Serialize.
   */
  String toJson() {
    if (_hasRawElements || !_configuration.canGuaranteeSerialization()) {
      throw 'Calling toString() on a PropertyMap that allows arbitrary '
      'objects is not supported because we cannot gurantee that they will be '
      'Serializable. If you want Serialization enabled, make sure you are '
      'using the default configuration and not calling addRawElement()';
    }

    var buffer = new StringBuffer();
    buffer.write('{');
    var first = true;
    for (var key in _objectData.keys) {
      first ? first = false : buffer.write(',');
      buffer.write('"${key}":');
      var value = _objectData[key];
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
        throw 'Unexpected value found on a PropertyMap. Type found: '
        '${mirror.type.simpleName}.';
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  dynamic toString() {
    return 'PropertyMap:${_objectData.toString()}';
  }
}
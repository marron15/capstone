// ignore_for_file: uri_does_not_exist

import 'dart:js_util' as js_util;

Object? getProperty(Object object, Object name) =>
    js_util.getProperty(object, name);

Object? callMethod(Object object, String method, List<Object?> args) =>
    js_util.callMethod(object, method, args);

Object jsify(Object object) => js_util.jsify(object);

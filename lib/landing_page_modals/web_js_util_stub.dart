Object? getProperty(Object object, Object name) => null;

Object? callMethod(Object object, String method, List<Object?> args) =>
    throw UnsupportedError('JS interop is not available on this platform.');

Object jsify(Object object) => object;

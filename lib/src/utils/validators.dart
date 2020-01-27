import 'package:validators/validators.dart' as validators;

bool isUrl(String url) {
  return validators.isURL(url);
}

bool isNumber(String str) {
  return validators.matches(str, "^[0-9]+(.[0-9]+)?\$");
}

bool isByteString(String byStr, {int length}) {
  var str = byStr.startsWith(new RegExp(r'0x', caseSensitive: false))
      ? byStr.substring(2)
      : byStr;
  return validators.matches(str, '^[0-9a-fA-F]{$length}') &&
      validators.isLength(str, length, length);
}

bool isHash(String str) {
  return isByteString(str, length: 64);
}

bool isAddress(String str) {
  return isByteString(str, length: 40);
}

bool isPublicKey(String str) {
  return isByteString(str, length: 66);
}

bool isSignature(String str) {
  return isByteString(str, length: 130);
}

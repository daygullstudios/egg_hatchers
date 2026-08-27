import 'package:web/web.dart' as web;

const _key = 'eggHatchersActiveAccountId';

String? readActiveAccountId() => web.window.sessionStorage.getItem(_key);

void writeActiveAccountId(String? value) {
  if (value == null) {
    web.window.sessionStorage.removeItem(_key);
  } else {
    web.window.sessionStorage.setItem(_key, value);
  }
}

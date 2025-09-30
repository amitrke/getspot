import 'package:web/web.dart' as web;

String getUserAgent() {
  return web.window.navigator.userAgent.toLowerCase();
}

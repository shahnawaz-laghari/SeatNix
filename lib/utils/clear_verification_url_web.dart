import 'package:web/web.dart' as web;

void clearVerificationQueryFromUrl() {
  final uri = Uri.base;
  final cleanUri = Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo.isEmpty ? null : uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  );
  web.window.history.replaceState(null, '', cleanUri.toString());
}

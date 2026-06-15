import 'dart:async';
import 'dart:io';

Future<bool> hasInternetAccess() async {
  const hosts = <String>[
    'jgpxdlkbuxhriltxezdc.supabase.co',
    'example.com',
    'cloudflare.com',
  ];

  for (final host in hosts) {
    try {
      final addresses = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 3));

      if (addresses.any((address) => address.rawAddress.isNotEmpty)) {
        return true;
      }
    } catch (_) {
      // Try the next host: mobile networks can block or delay a single DNS lookup.
    }
  }

  return false;
}

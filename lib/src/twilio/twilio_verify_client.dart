import 'dart:convert';

import 'package:http/http.dart' as http;

import 'otp_delivery_channel.dart';
import 'twilio_verify_config.dart';

/// Outcome of [TwilioVerifyClient.sendVerification].
class TwilioSendResult {
  const TwilioSendResult({
    required this.channel,
    this.verificationSid,
  });

  final OtpDeliveryChannel channel;
  final String? verificationSid;
}

/// Thin Twilio Verify v2 REST client (HTTPS + Basic auth).
///
/// See: https://www.twilio.com/docs/verify/api
class TwilioVerifyClient {
  TwilioVerifyClient({
    required TwilioVerifyConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _http = httpClient ?? http.Client();

  final TwilioVerifyConfig _config;
  final http.Client _http;

  static const _base = 'https://verify.twilio.com/v2';

  String get _authHeader {
    final raw = utf8.encode('${_config.accountSid}:${_config.authToken}');
    return 'Basic ${base64Encode(raw)}';
  }

  Uri _verificationsUri() => Uri.parse(
        '$_base/Services/${_config.serviceSid}/Verifications',
      );

  Uri _verificationCheckUri() => Uri.parse(
        '$_base/Services/${_config.serviceSid}/VerificationCheck',
      );

  Future<http.Response> _postForm(Uri url, Map<String, String> fields) {
    final body = fields.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return _http.post(
      url,
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
  }

  static String _twilioMessage(http.Response r) {
    try {
      final m = jsonDecode(r.body);
      if (m is Map<String, dynamic>) {
        final msg = m['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        final code = m['code'];
        if (code != null) return 'Twilio error: $code';
      }
    } catch (_) {}
    return 'HTTP ${r.statusCode}';
  }

  /// Sends a verification code. Tries WhatsApp first, then SMS on failure.
  Future<TwilioSendResult> sendVerification(String toE164) async {
    final to = normalizeToE164(toE164);
    for (final channel in [
      OtpDeliveryChannel.whatsapp,
      OtpDeliveryChannel.sms,
    ]) {
      final r = await _postForm(_verificationsUri(), {
        'To': to,
        'Channel': channel.name,
      });
      if (r.statusCode >= 200 && r.statusCode < 300) {
        String? sid;
        try {
          final m = jsonDecode(r.body);
          if (m is Map<String, dynamic>) {
            sid = m['sid'] as String?;
          }
        } catch (_) {}
        return TwilioSendResult(channel: channel, verificationSid: sid);
      }
      if (channel == OtpDeliveryChannel.whatsapp) {
        continue;
      }
      throw Exception(_twilioMessage(r));
    }
    throw Exception('Twilio Verify: could not send code.');
  }

  /// Validates the OTP for [toE164]. Throws if not approved.
  Future<void> checkVerification(String toE164, String code) async {
    final to = normalizeToE164(toE164);
    final digits = code.replaceAll(RegExp(r'\D'), '');
    final r = await _postForm(_verificationCheckUri(), {
      'To': to,
      'Code': digits,
    });
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_twilioMessage(r));
    }
    try {
      final m = jsonDecode(r.body);
      if (m is Map<String, dynamic>) {
        final valid = m['valid'] as bool?;
        final status = m['status'] as String?;
        if (valid == true || status == 'approved') {
          return;
        }
      }
    } catch (_) {}
    throw Exception(_twilioMessage(r));
  }

  /// Normalizes a phone string to E.164 (e.g. Egyptian 10 digits → +20…).
  static String normalizeToE164(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.startsWith('+')) return s;
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '+';
    if (d.length >= 12 && d.startsWith('20')) return '+$d';
    if (d.length == 10) return '+20$d';
    return '+$d';
  }
}

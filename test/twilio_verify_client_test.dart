import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:toukh_ui/toukh_ui.dart';

void main() {
  const config = TwilioVerifyConfig(
    accountSid: 'ACtest',
    authToken: 'token',
    serviceSid: 'VAtest',
  );

  group('TwilioVerifyClient.normalizeToE164', () {
    test('Egyptian 10 digits become +20…', () {
      expect(
        TwilioVerifyClient.normalizeToE164('1050442212'),
        '+201050442212',
      );
    });

    test('keeps existing +E.164', () {
      expect(
        TwilioVerifyClient.normalizeToE164('+201050442212'),
        '+201050442212',
      );
    });

    test('20-prefixed national digits become +20…', () {
      expect(
        TwilioVerifyClient.normalizeToE164('201050442212'),
        '+201050442212',
      );
    });
  });

  group('TwilioVerifyClient.sendVerification', () {
    test('WhatsApp success returns whatsappOrSms and does not call SMS',
        () async {
      var calls = 0;
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          calls++;
          expect(request.url.path, contains('/Verifications'));
          expect(request.body, contains('Channel=whatsapp'));
          expect(request.body, contains('ChannelConfiguration'));
          return http.Response(
            jsonEncode({'sid': 'VEwhatsapp', 'status': 'pending'}),
            201,
          );
        }),
      );

      final result = await client.sendVerification('1050442212');
      expect(result.channel, OtpDeliveryChannel.whatsappOrSms);
      expect(result.verificationSid, 'VEwhatsapp');
      expect(calls, 1);
    });

    test('WhatsApp fail then SMS success returns sms', () async {
      var calls = 0;
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          calls++;
          if (calls == 1) {
            expect(request.body, contains('Channel=whatsapp'));
            return http.Response(
              jsonEncode({
                'code': 68008,
                'message': 'Verify WhatsApp channel not configured',
              }),
              400,
            );
          }
          expect(request.body, contains('Channel=sms'));
          expect(request.body, isNot(contains('ChannelConfiguration')));
          return http.Response(
            jsonEncode({'sid': 'VEsms', 'status': 'pending'}),
            201,
          );
        }),
      );

      final result = await client.sendVerification('+201050442212');
      expect(result.channel, OtpDeliveryChannel.sms);
      expect(result.verificationSid, 'VEsms');
      expect(calls, 2);
    });

    test('both channels fail throws Twilio message', () async {
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'code': 60200, 'message': 'Invalid parameter'}),
            400,
          );
        }),
      );

      expect(
        () => client.sendVerification('+201050442212'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid parameter'),
          ),
        ),
      );
    });
  });

  group('TwilioVerifyClient.checkVerification', () {
    test('accepts valid true', () async {
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          expect(request.url.path, contains('/VerificationCheck'));
          expect(request.body, contains('Code=123456'));
          return http.Response(
            jsonEncode({'valid': true, 'status': 'approved'}),
            200,
          );
        }),
      );

      await client.checkVerification('+201050442212', '123456');
    });

    test('accepts status approved without valid flag', () async {
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'status': 'approved'}),
            200,
          );
        }),
      );

      await client.checkVerification('+201050442212', '999999');
    });

    test('rejects pending / invalid code', () async {
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'valid': false,
              'status': 'pending',
              'message': 'Invalid code',
            }),
            200,
          );
        }),
      );

      expect(
        () => client.checkVerification('+201050442212', '000000'),
        throwsA(isA<Exception>()),
      );
    });

    test('HTTP error throws Twilio message', () async {
      final client = TwilioVerifyClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'code': 60202, 'message': 'Max attempts reached'}),
            429,
          );
        }),
      );

      expect(
        () => client.checkVerification('+201050442212', '123456'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Max attempts reached'),
          ),
        ),
      );
    });
  });
}

// Offline tests against the known answers shared by every SDK:
// ../spec/test-vectors/php_known_answers.json, computed with the PHP samples
// from ABA's documentation (../spec/test-vectors/php_known_answers.php).
import { createHmac } from 'node:crypto';

import { describe, expect, it } from 'vitest';

import {
  PaywayError,
  PaywayMerchant,
  PaywayRequestBuilder,
  PaywayService,
  callbackSigningString,
  formatRequestTime,
} from '../src/index.js';
import {
  fixedClock,
  fixture,
  fullPurchase,
  kat,
  merchant,
  requestTime,
  rsaDecrypt,
} from './helpers.js';

const builder = new PaywayRequestBuilder(merchant, { clock: fixedClock });

describe('request time', () => {
  it('is UTC YYYYMMDDHHmmss, zero padded', () => {
    expect(formatRequestTime(new Date(Date.UTC(2026, 0, 2, 15, 4, 5)))).toBe(
      '20260102150405',
    );
    expect(formatRequestTime(new Date(Date.UTC(2026, 8, 3, 7, 8, 9)))).toBe(
      '20260903070809',
    );
    expect(builder.exchangeRate()['req_time']).toBe(requestTime);
  });

  it('a malformed request time is rejected', () => {
    expect(() => builder.checkTransaction('x', '2026-01-02')).toThrow(
      RangeError,
    );
  });
});

describe("hashes match ABA's PHP samples", () => {
  it('purchase with the required fields only', () => {
    expect(builder.purchase({ tranId: 'order-1001', amount: 6.5 })).toEqual({
      req_time: requestTime,
      merchant_id: 'ec000002',
      tran_id: 'order-1001',
      amount: '6.5',
      hash: kat['purchase_minimal'],
    });
  });

  it('purchase with every field', () => {
    const fields = builder.purchase(fullPurchase);
    expect(fields['hash']).toBe(kat['purchase_full']);
    expect(fields['items']).toBe(kat['purchase_full_items']);
    expect(fields['return_url']).toBe(kat['purchase_full_return_url']);
    expect(fields['return_deeplink']).toBe(
      kat['purchase_full_return_deeplink'],
    );
    expect(fields['payout']).toBe(kat['purchase_full_payout']);
    expect(fields['type']).toBe('pre-auth');
    expect(fields['shipping']).toBe('1');
    expect(fields['lifetime']).toBe('30');
    expect(fields['skip_success_page']).toBe('1');
    // sent, but not part of the hash
    expect(fields['view_type']).toBe('popup');
    expect(fields['payment_gate']).toBe('0');
    expect(Object.keys(fields).at(-1)).toBe('hash');
    expect(Object.keys(fields).slice(0, 4)).toEqual([
      'req_time',
      'merchant_id',
      'tran_id',
      'amount',
    ]);
  });

  it('check transaction, transaction detail and close transaction', () => {
    for (const body of [
      builder.checkTransaction('order-1001'),
      builder.transactionDetail('order-1001'),
      builder.closeTransaction('order-1001'),
    ]) {
      expect(body).toEqual({
        req_time: requestTime,
        merchant_id: 'ec000002',
        tran_id: 'order-1001',
        hash: kat['tran_id_hash'],
      });
    }
  });

  it('transaction list', () => {
    const body = builder.transactionList({
      fromDate: new Date(2026, 0, 1),
      toDate: new Date(2026, 0, 31, 23, 59, 59),
      fromAmount: 1,
      toAmount: 100,
      statuses: ['APPROVED', 'REFUNDED'],
      page: 2,
      pagination: 50,
    });
    expect(body['from_date']).toBe('2026-01-01 00:00:00');
    expect(body['to_date']).toBe('2026-01-31 23:59:59');
    expect(body['status']).toBe('APPROVED,REFUNDED');
    expect(body['hash']).toBe(kat['list_hash']);
  });

  it('an empty transaction list query signs the two required values', () => {
    const body = builder.transactionList({});
    expect(Object.keys(body)).toEqual(['req_time', 'merchant_id', 'hash']);
    expect(body['hash']).toBe(builder.sign([requestTime, 'ec000002']));
  });

  it('exchange rate', () => {
    expect(builder.exchangeRate()['hash']).toBe(kat['exchange_hash']);
  });
});

describe('refund', () => {
  it('merchant_auth is the RSA-encrypted refund, hashed with it', () => {
    const body = builder.refund('order-1001', 0.5);
    expect(Object.keys(body)).toEqual([
      'request_time',
      'merchant_id',
      'merchant_auth',
      'hash',
    ]);
    expect(
      JSON.parse(
        rsaDecrypt(body['merchant_auth']!, fixture('rsa_1024_private.pem')),
      ),
    ).toEqual({ mc_id: 'ec000002', tran_id: 'order-1001', refund_amount: 0.5 });
    const expected = createHmac('sha512', 'test-api-key')
      .update(`${requestTime}ec000002${body['merchant_auth']!}`)
      .digest('base64');
    expect(body['hash']).toBe(expected);
  });

  it('a payload longer than one block is encrypted in chunks', () => {
    const longId = 'x'.repeat(200);
    const body = builder.refund(longId, 1);
    // 1024 bit key: 128 byte blocks
    expect(Buffer.from(body['merchant_auth']!, 'base64').length).toBe(3 * 128);
    expect(
      JSON.parse(
        rsaDecrypt(body['merchant_auth']!, fixture('rsa_1024_private.pem')),
      ),
    ).toMatchObject({ tran_id: longId });
  });

  it('2048 bit, PKCS#1 and bare base64 keys work too', () => {
    const bare = fixture('rsa_1024_public.pem')
      .split('\n')
      .filter((l) => l !== '' && !l.startsWith('-----'))
      .join('');
    for (const [publicKey, privateKey] of [
      ['rsa_2048_public.pem', 'rsa_2048_private.pem'],
      ['rsa_1024_public_pkcs1.pem', 'rsa_1024_private_pkcs8.pem'],
    ] as const) {
      const other = new PaywayRequestBuilder(
        merchant.with({ rsaPublicKey: fixture(publicKey) }),
        { clock: fixedClock },
      );
      const body = other.refund('order-1001', 1);
      expect(
        JSON.parse(rsaDecrypt(body['merchant_auth']!, fixture(privateKey))),
      ).toMatchObject({ tran_id: 'order-1001' });
    }
    const body = new PaywayRequestBuilder(
      merchant.with({ rsaPublicKey: bare }),
    ).refund('order-1001', 1);
    expect(
      rsaDecrypt(body['merchant_auth']!, fixture('rsa_1024_private.pem')),
    ).toContain('order-1001');
  });

  it('without a usable RSA key it rejects with an encryption error', async () => {
    for (const rsaPublicKey of [undefined, '', 'not a key']) {
      const service = new PaywayService({
        merchant: new PaywayMerchant({
          merchantId: 'm',
          apiKey: 'k',
          referer: '',
          rsaPublicKey,
          baseUrl: 'https://payway.test',
        }),
        fetch: () => Promise.reject(new Error('must not be called')),
      });
      const error = (await service
        .refund('x', 1)
        .catch((e: unknown) => e)) as PaywayError;
      expect(error).toBeInstanceOf(PaywayError);
      expect(error.type).toBe('encryption');
      expect(error.isRetryable).toBe(false);
    }
  });
});

describe('callbacks', () => {
  const service = new PaywayService({ merchant });

  it('the documented sample callback verifies', () => {
    expect(
      service.verifyCallback(kat['callback_body']!, kat['callback_signature']),
    ).toBe(true);
    // header values may carry whitespace
    expect(
      service.verifyCallback(
        kat['callback_body']!,
        ` ${kat['callback_signature']!}\n`,
      ),
    ).toBe(true);
  });

  it('nested objects, unicode, booleans and null sign like PHP', () => {
    expect(
      service.verifyCallback(
        kat['callback2_body']!,
        kat['callback2_signature'],
      ),
    ).toBe(true);
    expect(
      callbackSigningString(
        JSON.parse(kat['callback2_body']!) as Record<string, unknown>,
      ),
    ).toBe(
      '[]{"url":"https:\\/\\/a\\/b","name":"\\u17a0\\u17b6\\u1784"}10["x","y"]101',
    );
  });

  it('numbers and nested values are converted like PHP 8', () => {
    // expected string printed by PHP 8.3 running ABA's sample loop
    const body = JSON.parse(
      '{"a":0.30000000000000004,"b":1.0e-5,"c":{"x":1.0e-5,"y":[]},' +
        '"d":{"0":"p","1":"q"},"e":false,"f":123456789.12345679,"g":1e20,' +
        '"h":"\\u0001/"}',
    ) as Record<string, unknown>;
    expect(callbackSigningString(body)).toBe(
      '0.31.0E-5{"x":1.0e-5,"y":[]}["p","q"]123456789.123461.0E+20\u0001/',
    );
  });

  it('an explicit key overrides the API key', () => {
    const other = new PaywayService({
      merchant: merchant.with({ apiKey: 'another-key' }),
    });
    expect(
      other.verifyCallback(kat['callback_body']!, kat['callback_signature']),
    ).toBe(false);
    expect(
      other.verifyCallback(
        kat['callback_body']!,
        kat['callback_signature'],
        'test-api-key',
      ),
    ).toBe(true);
  });

  it('a tampered body or wrong signature is rejected', () => {
    const tampered = kat['callback_body']!.replace('0.01', '1000');
    expect(service.verifyCallback(tampered, kat['callback_signature'])).toBe(
      false,
    );
    expect(service.verifyCallback(kat['callback_body']!, 'forged')).toBe(false);
    expect(service.verifyCallback(kat['callback_body']!, undefined)).toBe(
      false,
    );
    expect(service.verifyCallback('not json', 'x')).toBe(false);
    expect(service.verifyCallback('[]', 'x')).toBe(false);
  });

  it('parseCallback reads the documented fields', () => {
    const callback = service.parseCallback(kat['callback_body']!);
    expect(callback.tranId).toBe('9065703303');
    expect(callback.isSuccess).toBe(true);
    expect(callback.totalAmount).toBe(0.01);
    expect(callback.paymentType).toBe('ABA Pay');
    expect(callback.returnParams).toContain('order_id');
    for (const body of ['[]', 'not json', 'null']) {
      expect(() => service.parseCallback(body)).toThrow(
        expect.objectContaining({ type: 'invalidCallback' }),
      );
    }
  });
});

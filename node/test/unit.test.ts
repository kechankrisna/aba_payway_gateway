// Offline tests of the Node specifics: injected fetch, headers, parsing,
// errors and secrets.
import { readFileSync } from 'node:fs';
import { inspect } from 'node:util';

import { describe, expect, it } from 'vitest';

import {
  CHECK_TRANSACTION_PATH,
  PURCHASE_PATH,
  PaymentOption,
  PaymentStatus,
  PaymentStatusCode,
  PaywayError,
  PaywayMerchant,
  PaywayService,
  REFUND_PATH,
  SDK_VERSION,
  TRANSACTION_LIST_PATH,
  type PaywayServiceOptions,
} from '../src/index.js';
import {
  fakeFetch,
  fixedClock,
  fullPurchase,
  kat,
  merchant,
} from './helpers.js';

const serviceWith = (
  fetch: typeof globalThis.fetch,
  options: Partial<PaywayServiceOptions> = {},
) => new PaywayService({ merchant, fetch, clock: fixedClock, ...options });

const reply =
  (body: unknown, status = 200) =>
  () =>
    Response.json(body, { status });

const errorOf = (promise: Promise<unknown>) =>
  promise.catch((e: unknown) => e) as Promise<PaywayError>;

describe('PaywayService with an injected fetch', () => {
  it('purchase posts multipart form data and parses the deeplink reply', async () => {
    const fetch = fakeFetch(
      reply({
        status: { code: '00', message: 'Success!', tran_id: 'order-1001' },
        qr_string: '000201...',
        abapay_deeplink: 'abamobilebank://ababank.com?type=payway',
        checkout_qr_url: 'https://checkout-sandbox.payway.com.kh/qr',
      }),
    );

    const response = await serviceWith(fetch).purchase(fullPurchase);

    expect(response.isSuccess).toBe(true);
    expect(response.qrString).toBe('000201...');
    expect(response.abapayDeeplink).toMatch(/^abamobilebank:\/\//);
    expect(response.checkoutQrUrl).toContain('/qr');
    expect(response.status.tranId).toBe('order-1001');

    const request = fetch.requests[0]!;
    expect(request.url).toBe(`https://payway.test${PURCHASE_PATH}`);
    expect(request.method).toBe('POST');
    expect(request.headers.get('content-type')).toMatch(
      /^multipart\/form-data; boundary=/,
    );
    expect(request.headers.get('referer')).toBe('https://shop.test');
    expect(request.headers.get('user-agent')).toBe(
      `node-payway/${SDK_VERSION}`,
    );
    // parse the multipart body as sent on the wire
    const boundary = request.headers
      .get('content-type')!
      .replace(/^.*boundary=/, '');
    const fields: Record<string, string> = Object.fromEntries(
      (await request.text())
        .split(`--${boundary}`)
        .slice(1, -1)
        .map((part) => {
          const match = /name="([^"]+)"\r\n\r\n([\s\S]*)\r\n$/.exec(part);
          return [match![1]!, match![2]!];
        }),
    );
    expect(fields).toEqual(
      new PaywayService({
        merchant,
        clock: fixedClock,
      }).requestBuilder.purchase(fullPurchase),
    );
    expect(fields['hash']).toBe(kat['purchase_full']);
  });

  it("purchase reads production's camelCase fields too", async () => {
    // shape of a real production reply (values shortened)
    const fetch = fakeFetch(
      reply({
        qrString: '000201...',
        qrImage: 'data:image/png;base64,iVBORw0KGgo=',
        abapay_deeplink: 'abamobilebank://ababank.com?type=payway',
        app_store: 'https://itunes.apple.com/app/id968860649',
        play_store:
          'https://play.google.com/store/apps/details?id=com.paygo24.ibank',
        description: 'success',
        status: {
          version: 'v3',
          code: '00',
          message: 'Success!',
          tran_id: 'order-1001',
          lang: 'en',
          trace_id: '19b80de5',
        },
      }),
    );

    const response = await serviceWith(fetch).purchase(fullPurchase);

    expect(response.isSuccess).toBe(true);
    expect(response.qrString).toBe('000201...');
    expect(response.qrImage).toMatch(/^data:image\/png/);
    expect(response.appStore).toContain('itunes.apple.com');
    expect(response.playStore).toContain('com.paygo24.ibank');
    expect(response.checkoutQrUrl).toBeUndefined();
    expect(response.status.traceId).toBe('19b80de5');
  });

  it('purchase needs abapay_khqr_deeplink; others use checkoutHtml', async () => {
    const fetch = fakeFetch(reply({}));
    for (const paymentOption of [PaymentOption.cards, undefined]) {
      await expect(
        serviceWith(fetch).purchase({ tranId: 'x', amount: 1, paymentOption }),
      ).rejects.toThrow(TypeError);
    }
    expect(fetch.requests).toHaveLength(0);
  });

  it('check transaction posts JSON and lifts a status nested in data', async () => {
    const fetch = fakeFetch(
      reply({
        data: {
          payment_status_code: 0,
          payment_status: 'APPROVED',
          total_amount: '6.5',
          apv: '753786',
          status: { code: '00', message: 'Success!', tran_id: 'order-1001' },
        },
      }),
    );
    const service = serviceWith(fetch);

    const response = await service.checkTransaction('order-1001');

    expect(response.isSuccess).toBe(true);
    expect(response.isPaid).toBe(true);
    expect(response.status.tranId).toBe('order-1001');
    expect(response.data!.totalAmount).toBe(6.5);
    expect(response.data!.apv).toBe('753786');
    const request = fetch.requests[0]!;
    expect(new URL(request.url).pathname).toBe(CHECK_TRANSACTION_PATH);
    expect(request.headers.get('content-type')).toBe('application/json');
    expect(request.headers.get('accept')).toBe('application/json');
    expect(await request.json()).toEqual(
      service.requestBuilder.checkTransaction('order-1001'),
    );
  });

  it('a numeric status code is read as a string', async () => {
    const response = await serviceWith(
      fakeFetch(reply({ status: { code: 0, message: 'Success!' } })),
    ).closeTransaction('x');
    expect(response.status.code).toBe('0');
    expect(response.isSuccess).toBe(true);
  });

  it('a PayWay error status is returned, not thrown, whatever the HTTP status', async () => {
    const response = await serviceWith(
      fakeFetch(
        reply(
          {
            status: {
              code: '6',
              message: 'Transaction not found',
              tran_id: 'x',
            },
          },
          403,
        ),
      ),
    ).getTransactionDetail('x');
    expect(response.isSuccess).toBe(false);
    expect(response.status.code).toBe('6');
    expect(response.data).toBeUndefined();
  });

  it('transaction details parse operations', async () => {
    const response = await serviceWith(
      fakeFetch(
        reply({
          data: {
            transaction_id: '17394277693',
            payment_status_code: 0,
            payment_status: 'APPROVED',
            total_amount: 0.1,
            transaction_operations: [
              {
                status: 'Completed',
                amount: 0.1,
                transaction_date: '2025-02-13 13:55:25',
                bank_ref: 'FT1',
              },
            ],
          },
          status: { code: '00', message: 'Success!' },
        }),
      ),
    ).getTransactionDetail('17394277693');
    expect(response.data!.isApproved).toBe(true);
    expect(response.data!.transactionId).toBe('17394277693');
    expect(response.data!.transactionOperations[0]!.bankRef).toBe('FT1');
  });

  it('transaction list sends the query and parses pages', async () => {
    const fetch = fakeFetch(
      reply({
        data: [
          {
            transaction_id: 'a',
            payment_status_code: '2',
            total_amount: '10.5',
          },
        ],
        page: '1',
        pagination: 20,
        status: { code: '00', message: 'Success!' },
      }),
    );
    const response = await serviceWith(fetch).getTransactionList({
      statuses: [PaymentStatus.pending, PaymentStatus.declined],
      pagination: 20,
    });
    expect(response.data[0]!.paymentStatusCode).toBe(PaymentStatusCode.pending);
    expect(response.data[0]!.totalAmount).toBe(10.5);
    expect(response.page).toBe(1);
    expect(response.pagination).toBe(20);
    const request = fetch.requests[0]!;
    expect(new URL(request.url).pathname).toBe(TRANSACTION_LIST_PATH);
    expect(await request.json()).toMatchObject({
      status: 'PENDING,DECLINDED',
      pagination: '20',
    });
  });

  it('exchange rates are read from both documented layouts', async () => {
    const response = await serviceWith(
      fakeFetch(
        reply({
          status: { code: '00', message: 'Success' },
          exchange_rates: {
            USD: { sell: '4100', buy: 4090 },
            aud: { sell: '0.68', buy: 0.66 },
          },
          eur: { sell: 1.1, buy: 1.08 },
        }),
      ),
    ).getExchangeRates();
    expect(Object.keys(response.rates).sort()).toEqual(['aud', 'eur', 'usd']);
    expect(response.rates['usd']).toEqual({ sell: 4100, buy: 4090 });
    expect(response.rates['aud']!.sell).toBe(0.68);
  });

  it('refund posts to the merchant-portal endpoint', async () => {
    const fetch = fakeFetch(
      reply({
        grand_total: 1.5,
        total_refunded: 0.09,
        currency: 'USD',
        transaction_status: 'REFUNDED',
        status: { code: '00', message: 'Success!' },
      }),
    );
    const response = await serviceWith(fetch).refund('order-1001', 0.09);
    expect(response.isSuccess).toBe(true);
    expect(response.totalRefunded).toBe(0.09);
    expect(response.transactionStatus).toBe('REFUNDED');
    const request = fetch.requests[0]!;
    expect(new URL(request.url).pathname).toBe(REFUND_PATH);
    expect(Object.keys((await request.json()) as object)).toEqual([
      'request_time',
      'merchant_id',
      'merchant_auth',
      'hash',
    ]);
  });

  it('network failures are retryable connection errors', async () => {
    const error = await errorOf(
      serviceWith(
        fakeFetch(() => {
          throw new TypeError('fetch failed');
        }),
      ).closeTransaction('x'),
    );
    expect(error).toBeInstanceOf(PaywayError);
    expect(error.type).toBe('connection');
    expect(error.isRetryable).toBe(true);
    expect(error.cause).toBeInstanceOf(TypeError);
  });

  it('a rejected TLS certificate is typed', async () => {
    const error = await errorOf(
      serviceWith(
        fakeFetch(() => {
          throw new TypeError('fetch failed', {
            cause: Object.assign(new Error('expired'), {
              code: 'CERT_HAS_EXPIRED',
            }),
          });
        }),
      ).closeTransaction('x'),
    );
    expect(error.type).toBe('badCertificate');
    expect(error.isRetryable).toBe(false);
  });

  it('an HTML page instead of JSON is an unexpected response', async () => {
    const error = await errorOf(
      serviceWith(
        fakeFetch(
          () =>
            new Response('<html><body>Bad Gateway</body></html>', {
              status: 502,
              headers: { 'content-type': 'text/html' },
            }),
        ),
      ).getTransactionList(),
    );
    expect(error.type).toBe('unexpectedResponse');
    expect(error.statusCode).toBe(502);
    expect(error.isRetryable).toBe(true);

    const notStatus = await errorOf(
      serviceWith(
        fakeFetch(reply({ message: 'no status' }, 400)),
      ).getExchangeRates(),
    );
    expect(notStatus.type).toBe('unexpectedResponse');
    expect(notStatus.isRetryable).toBe(false);
  });

  it('an aborted call is cancelled', async () => {
    const controller = new AbortController();
    controller.abort();
    const error = await errorOf(
      serviceWith(fakeFetch(reply({}))).checkTransaction('x', {
        signal: controller.signal,
      }),
    );
    expect(error.type).toBe('cancelled');
    expect(error.isRetryable).toBe(false);
  });

  it('a slow reply times out', async () => {
    const fetch = fakeFetch(
      (request) =>
        new Promise((_, reject) => {
          request.signal.addEventListener('abort', () => {
            reject(
              request.signal.reason instanceof Error
                ? request.signal.reason
                : new Error('aborted'),
            );
          });
        }),
    );
    const error = await errorOf(
      serviceWith(fetch, { timeoutMs: 20 }).checkTransaction('x'),
    );
    expect(error.type).toBe('timeout');
    expect(error.isRetryable).toBe(true);
  });

  it('logs go to the injected logger only', async () => {
    const lines: string[] = [];
    await serviceWith(
      fakeFetch(reply({ status: { code: '00', message: 'ok' } })),
      { logger: (line) => lines.push(line) },
    ).closeTransaction('x');
    expect(lines).toHaveLength(2);
    expect(lines[0]).toContain('POST https://payway.test');
    expect(lines[1]).toContain('200');
    expect(lines.join('\n')).not.toContain('test-api-key');
  });

  it('no Referer header without a referer', async () => {
    const fetch = fakeFetch(reply({ status: { code: '00', message: 'ok' } }));
    await serviceWith(fetch, {
      merchant: merchant.with({ referer: '' }),
    }).closeTransaction('x');
    expect(fetch.requests[0]!.headers.has('referer')).toBe(false);
  });
});

describe('checkoutHtml', () => {
  const service = new PaywayService({ merchant, clock: fixedClock });

  it('auto-submits the signed purchase to PayWay', () => {
    const html = service.checkoutHtml(fullPurchase);
    expect(html).toContain(`action="https://payway.test${PURCHASE_PATH}"`);
    expect(html).toContain(`name="hash" value="${kat['purchase_full']!}"`);
    expect(html).toContain('name="view_type" value="popup"');
    expect(html).toContain('.submit()');
  });

  it('escapes every value', () => {
    const html = service.checkoutHtml({
      tranId: `x'&y`,
      amount: 1,
      firstName: '"><script>alert(1)</script>',
    });
    expect(html).not.toContain('<script>alert');
    expect(html).toContain('&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;');
    expect(html).toContain('value="x&#39;&amp;y"');
  });
});

describe('PaywayMerchant', () => {
  it('defaults to the sandbox', () => {
    const m = new PaywayMerchant({ merchantId: 'm', apiKey: 'k', referer: '' });
    expect(m.baseUrl).toBe(PaywayMerchant.SANDBOX_URL);
    expect(PaywayMerchant.SANDBOX_URL).toBe(
      'https://checkout-sandbox.payway.com.kh',
    );
    expect(PaywayMerchant.PRODUCTION_URL).toBe(
      'https://checkout.payway.com.kh',
    );
  });

  it('keeps the API key out of toString, inspect and JSON', () => {
    expect(merchant.apiKey).toBe('test-api-key');
    expect(String(merchant)).not.toContain('test-api-key');
    expect(inspect(merchant, { depth: 5 })).not.toContain('test-api-key');
    expect(inspect({ nested: { merchant } }, { depth: 5 })).not.toContain(
      'test-api-key',
    );
    expect(JSON.stringify(merchant)).not.toContain('test-api-key');
    expect(JSON.stringify({ merchant })).toContain('ec000002');
    expect(Object.keys(merchant)).not.toContain('apiKey');
    const service = new PaywayService({ merchant });
    expect(inspect(service, { depth: 5 })).not.toContain('test-api-key');
    expect(JSON.stringify(service)).not.toContain('test-api-key');
  });

  it('with() copies, keeping the key', () => {
    const copy = merchant.with({ referer: 'https://other.test' });
    expect(copy.apiKey).toBe('test-api-key');
    expect(copy.referer).toBe('https://other.test');
    expect(copy.merchantId).toBe(merchant.merchantId);
  });
});

it('SDK_VERSION matches package.json', () => {
  const pkg = JSON.parse(
    readFileSync(new URL('../package.json', import.meta.url), 'utf8'),
  ) as { version: string };
  expect(SDK_VERSION).toBe(pkg.version);
});

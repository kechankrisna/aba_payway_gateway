// Integration tests against PayWay checkout. They read merchant credentials
// from node/.env (see .env.example), from the file named by PAYWAY_ENV_FILE,
// or from ABA_PAYWAY_* environment variables, and are skipped without them:
//
//   npx vitest run test/integration.test.ts
//   PAYWAY_ENV_FILE=.env.production npx vitest run test/integration.test.ts
//
// They create a real transaction (0.10 USD, then closed), so credentials
// pointing at production (checkout.payway.com.kh) are refused unless you
// also set PAYWAY_ALLOW_PRODUCTION=true.
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { afterAll, describe, expect, it } from 'vitest';

import {
  PaymentStatus,
  PaymentStatusCode,
  PaywayMerchant,
  PaywayService,
  type CheckTransactionResponse,
} from '../src/index.js';

const nodeDir = fileURLToPath(new URL('..', import.meta.url));
const envFile = resolve(nodeDir, process.env['PAYWAY_ENV_FILE'] ?? '.env');
if (existsSync(envFile)) process.loadEnvFile(envFile);

const env = (key: string) => process.env[key] ?? '';
const baseUrl = env('ABA_PAYWAY_API_URL') || PaywayMerchant.SANDBOX_URL;
const isProduction =
  new URL(baseUrl).host === new URL(PaywayMerchant.PRODUCTION_URL).host;
const allowProduction = process.env['PAYWAY_ALLOW_PRODUCTION'] === 'true';
const hasCredentials =
  env('ABA_PAYWAY_MERCHANT_ID') !== '' && env('ABA_PAYWAY_API_KEY') !== '';

if (!hasCredentials) {
  console.info(`PayWay integration tests skipped: no credentials (${envFile})`);
} else if (isProduction && !allowProduction) {
  console.info(
    'PayWay integration tests skipped: the credentials point at production; ' +
      'set PAYWAY_ALLOW_PRODUCTION=true to run tests that create real transactions',
  );
}

describe.skipIf(!hasCredentials || (isProduction && !allowProduction))(
  `PayWay checkout (${new URL(baseUrl).host})`,
  () => {
    const payway = new PaywayService({
      merchant: new PaywayMerchant({
        merchantId: env('ABA_PAYWAY_MERCHANT_ID'),
        apiKey: env('ABA_PAYWAY_API_KEY'),
        rsaPublicKey: env('ABA_PAYWAY_RSA_PUBLIC_KEY') || undefined,
        referer: env('ABA_PAYWAY_REFERER_DOMAIN'),
        baseUrl,
      }),
      logger: (line) => {
        console.info(line);
      },
    });
    // max 20 characters
    const tranId = `node${String(Date.now())}`;

    // close only the transaction this run created, never someone else's
    afterAll(async () => {
      await payway.closeTransaction(tranId);
    });

    it('purchase with abapay_khqr_deeplink returns a KHQR', async () => {
      const response = await payway.purchase({
        tranId,
        amount: 0.1,
        currency: 'USD',
        paymentOption: 'abapay_khqr_deeplink',
        items: [{ name: 'test item', quantity: 1, price: 0.1 }],
      });
      expect(response.isSuccess, JSON.stringify(response.status)).toBe(true);
      expect(response.qrString).toBeTruthy();
    });

    it('the new transaction is pending in check and details', async () => {
      // a new transaction takes a moment to appear
      let check: CheckTransactionResponse | undefined;
      for (let attempt = 0; attempt < 10; attempt++) {
        check = await payway.checkTransaction(tranId);
        if (check.isSuccess) break;
        await new Promise((r) => setTimeout(r, 1000));
      }
      expect(check!.isSuccess, JSON.stringify(check!.status)).toBe(true);
      expect(check!.data!.paymentStatusCode).toBe(PaymentStatusCode.pending);

      const detail = await payway.getTransactionDetail(tranId);
      expect(detail.isSuccess, JSON.stringify(detail.status)).toBe(true);
      expect(detail.data!.totalAmount).toBe(0.1);
    });

    it('the new transaction is in the transaction list', async () => {
      const list = await payway.getTransactionList({
        statuses: [PaymentStatus.pending],
        pagination: 20,
      });
      expect(list.isSuccess, JSON.stringify(list.status)).toBe(true);
      expect(list.data.map((t) => t.transactionId)).toContain(tranId);
    });

    it('closing the new transaction succeeds', async () => {
      const closed = await payway.closeTransaction(tranId);
      expect(closed.isSuccess, JSON.stringify(closed.status)).toBe(true);
    });

    it('check transaction of an unknown id is reported, not thrown', async () => {
      const response = await payway.checkTransaction('node-unknown-0');
      expect(response.isSuccess).toBe(false);
    });

    it('exchange rates', async () => {
      const response = await payway.getExchangeRates();
      expect(response.isSuccess, JSON.stringify(response.status)).toBe(true);
      // rates are riel per unit
      expect(response.rates['usd']!.sell).toBeGreaterThan(1000);
    });
  },
);

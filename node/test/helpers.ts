import { constants, privateDecrypt, createPrivateKey } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { PaywayMerchant, type Purchase } from '../src/index.js';

const spec = (path: string) =>
  fileURLToPath(new URL(`../../spec/${path}`, import.meta.url));

/** a key of spec/fixtures (throwaway test keys, not ABA keys) */
export function fixture(name: string): string {
  return readFileSync(spec(`fixtures/${name}`), 'utf8');
}

/** spec/test-vectors/php_known_answers.json, computed with ABA's PHP samples */
export const kat = JSON.parse(
  readFileSync(spec('test-vectors/php_known_answers.json'), 'utf8'),
) as Record<string, string>;

/** the fixed inputs of spec/test-vectors/php_known_answers.php */
export const merchant = new PaywayMerchant({
  merchantId: 'ec000002',
  apiKey: 'test-api-key',
  referer: 'https://shop.test',
  rsaPublicKey: fixture('rsa_1024_public.pem'),
  baseUrl: 'https://payway.test',
});
export const requestTime = '20260102030405';
export const fixedClock = () => new Date(Date.UTC(2026, 0, 2, 3, 4, 5));

export const fullPurchase: Purchase = {
  tranId: 'order-1001',
  amount: 6.5,
  items: [
    { name: 'product 1', quantity: 1, price: 1.5 },
    { name: 'product 2', quantity: 2, price: 2.5 },
  ],
  shipping: 1,
  firstName: 'Sok',
  lastName: 'Dara',
  email: 'sok@example.com',
  phone: '012345678',
  type: 'pre-auth',
  paymentOption: 'abapay_khqr_deeplink',
  returnUrl: 'https://shop.test/payway/callback',
  cancelUrl: 'https://shop.test/cancel',
  continueSuccessUrl: 'https://shop.test/done',
  returnDeeplink: { iosScheme: 'shop://done', androidScheme: 'shop://done' },
  currency: 'USD',
  customFields: { order: '1001' },
  returnParams: 'order=1001',
  payout: [
    { account: '000133879', amount: 1 },
    { account: '000133880', amount: 1.5 },
  ],
  lifetime: 30,
  additionalParams: { wechat_sub_appid: 'wx1' },
  skipSuccessPage: true,
  viewType: 'popup',
  paymentGate: 0,
};

/** PKCS#1 v1.5 decryption in key-size blocks, to check `merchant_auth` */
export function rsaDecrypt(data: string, privateKeyPem: string): string {
  const key = createPrivateKey(privateKeyPem);
  const blockSize = Math.ceil(key.asymmetricKeyDetails!.modulusLength! / 8);
  const source = Buffer.from(data, 'base64');
  const blocks: Buffer[] = [];
  for (let i = 0; i < source.length; i += blockSize) {
    blocks.push(
      privateDecrypt(
        { key, padding: constants.RSA_PKCS1_PADDING },
        source.subarray(i, i + blockSize),
      ),
    );
  }
  return Buffer.concat(blocks).toString('utf8');
}

/** a `fetch` that records requests and answers with `reply` */
export function fakeFetch(
  reply: (request: Request) => Response | Promise<Response>,
): typeof fetch & { requests: Request[] } {
  const requests: Request[] = [];
  const fn = async (input: string | URL | Request, init?: RequestInit) => {
    const request = new Request(input, init);
    requests.push(request.clone());
    init?.signal?.throwIfAborted();
    return reply(request);
  };
  return Object.assign(fn, { requests });
}

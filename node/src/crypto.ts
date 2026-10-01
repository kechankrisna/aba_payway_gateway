import {
  constants,
  createHmac,
  createPublicKey,
  publicEncrypt,
  type KeyObject,
} from 'node:crypto';

/**
 * Hashing and encryption matching the PHP samples in the PayWay checkout
 * docs: `base64_encode(hash_hmac('sha512', ..., true))` for request hashes
 * and callback signatures, and `openssl_public_encrypt` (PKCS#1 v1.5) in
 * chunks for the refund `merchant_auth`.
 *
 * Implement this interface to plug in another crypto backend.
 */
export interface PaywayCrypto {
  /** base64 of the raw HMAC-SHA512 of `message` keyed with `key` */
  hmacSha512Base64(message: string, key: string): string;
  /** RSA-encrypt `data` in key-size chunks with a PEM or bare base64 public key, base64 the result */
  rsaEncrypt(data: string, publicKey: string): string;
}

/** PKCS#1 v1.5 padding takes 11 bytes of every block */
const PKCS1_PADDING_LENGTH = 11;

/** Default {@link PaywayCrypto}, backed by `node:crypto`. */
export class NodePaywayCrypto implements PaywayCrypto {
  hmacSha512Base64(message: string, key: string): string {
    return createHmac('sha512', key).update(message, 'utf8').digest('base64');
  }

  rsaEncrypt(data: string, publicKey: string): string {
    const key = parsePublicKey(publicKey);
    const bits = key.asymmetricKeyDetails?.modulusLength;
    if (key.asymmetricKeyType !== 'rsa' || bits === undefined) {
      throw new TypeError('not an RSA key');
    }
    const chunkSize = Math.max(1, Math.ceil(bits / 8) - PKCS1_PADDING_LENGTH);
    const source = Buffer.from(data, 'utf8');
    const blocks: Buffer[] = [];
    for (let i = 0; i < source.length; i += chunkSize) {
      blocks.push(
        publicEncrypt(
          { key, padding: constants.RSA_PKCS1_PADDING },
          source.subarray(i, i + chunkSize),
        ),
      );
    }
    return Buffer.concat(blocks).toString('base64');
  }
}

/**
 * Parses an RSA public key: PEM `PUBLIC KEY` (X.509 SubjectPublicKeyInfo),
 * PEM `RSA PUBLIC KEY` (PKCS#1), or either as bare base64.
 */
export function parsePublicKey(key: string): KeyObject {
  const trimmed = key.trim();
  if (trimmed.includes('-----BEGIN')) return createPublicKey(trimmed);
  const der = Buffer.from(trimmed.replace(/\s/g, ''), 'base64');
  try {
    return createPublicKey({ key: der, format: 'der', type: 'spki' });
  } catch {
    return createPublicKey({ key: der, format: 'der', type: 'pkcs1' });
  }
}

// ---- callback signature ---------------------------------------------------
//
// ABA's PHP sample signs a callback with:
//
//   $response = json_decode($raw, true);
//   ksort($response);
//   foreach ($response as $value) {
//     if (is_array($value)) $value = json_encode($value);
//     $b4hash .= $value;
//   }
//
// so values are converted to strings the way PHP does it.

/**
 * The string PayWay signs a callback with, as in ABA's PHP sample: the
 * body's values sorted by key and concatenated as PHP converts them to
 * strings, with arrays and objects JSON-encoded the way PHP's `json_encode`
 * does.
 */
export function callbackSigningString(body: Record<string, unknown>): string {
  return Object.keys(body)
    .sort(compareKeys)
    .map((key) => phpString(body[key]))
    .join('');
}

const INTEGER_KEY = /^(0|-?[1-9]\d*)$/;

/** PHP turns integer-like keys into ints; ksort then orders them numerically */
function compareKeys(a: string, b: string): number {
  const aInt = INTEGER_KEY.test(a);
  const bInt = INTEGER_KEY.test(b);
  if (aInt && bInt) return Number(a) - Number(b);
  return Buffer.compare(Buffer.from(a, 'utf8'), Buffer.from(b, 'utf8'));
}

/** PHP's implicit string conversion of a `json_decode(..., true)` value */
function phpString(value: unknown): string {
  switch (typeof value) {
    case 'string':
      return value;
    case 'boolean':
      return value ? '1' : '';
    case 'number':
      return phpNumber(value, 14, 'E');
    case 'object':
      return value === null ? '' : phpJsonEncode(value);
    default:
      return '';
  }
}

/**
 * A number as PHP prints it. Integral values are taken as PHP ints (JSON
 * numbers without a fraction decode to ints); others as floats, printed with
 * `precision` significant digits (`0`: shortest round-trip, as
 * `serialize_precision=-1` does for `json_encode`).
 */
function phpNumber(value: number, precision: number, e: 'E' | 'e'): string {
  if (Number.isInteger(value) && Math.abs(value) < 2 ** 63) {
    // shortest digits, not BigInt: beyond 2^53 they match the JSON literal
    return String(value);
  }
  if (!Number.isFinite(value)) {
    return Number.isNaN(value) ? 'NAN' : value > 0 ? 'INF' : '-INF';
  }
  // like php_gcvt(): digits and decimal point position
  const exponential =
    precision === 0
      ? value.toExponential()
      : value.toExponential(precision - 1);
  const [mantissa = '', exp = '0'] = exponential.split('e');
  const sign = mantissa.startsWith('-') ? '-' : '';
  const digits = mantissa.replace(/[-.]/g, '').replace(/0+$/, '') || '0';
  const decpt = Number(exp) + 1;
  const ndigit = precision === 0 ? 17 : precision;
  if (decpt < 0 ? decpt < -3 : decpt > ndigit) {
    const e10 = decpt - 1;
    return `${sign}${digits[0] ?? '0'}.${digits.slice(1) || '0'}${e}${e10 < 0 ? '-' : '+'}${String(Math.abs(e10))}`;
  }
  if (decpt <= 0) return `${sign}0.${'0'.repeat(-decpt)}${digits}`;
  const whole = digits.slice(0, decpt).padEnd(decpt, '0');
  const fraction = digits.slice(decpt);
  return `${sign}${whole}${fraction === '' ? '' : `.${fraction}`}`;
}

/**
 * `json_encode` with PHP's defaults: `/` escaped, non-ASCII as `\uXXXX`, an
 * empty object as `[]` and an object keyed `0..n-1` as a list (json_decode
 * turns both into PHP lists).
 */
function phpJsonEncode(value: unknown): string {
  if (value === null) return 'null';
  switch (typeof value) {
    case 'boolean':
      return value ? 'true' : 'false';
    case 'number':
      return phpNumber(value, 0, 'e');
    case 'string':
      return phpJsonString(value);
    case 'object': {
      if (Array.isArray(value)) {
        return `[${value.map(phpJsonEncode).join(',')}]`;
      }
      const entries = Object.entries(value as Record<string, unknown>);
      if (entries.every(([key], i) => key === String(i))) {
        return `[${entries.map(([, v]) => phpJsonEncode(v)).join(',')}]`;
      }
      return `{${entries
        .map(([key, v]) => `${phpJsonString(key)}:${phpJsonEncode(v)}`)
        .join(',')}}`;
    }
    default:
      return 'null';
  }
}

const JSON_ESCAPES: Record<string, string> = {
  '"': '\\"',
  '\\': '\\\\',
  '/': '\\/',
  '\b': '\\b',
  '\f': '\\f',
  '\n': '\\n',
  '\r': '\\r',
  '\t': '\\t',
};

function phpJsonString(value: string): string {
  let out = '"';
  for (let i = 0; i < value.length; i++) {
    const char = value.charAt(i);
    const unit = value.charCodeAt(i);
    const escape = JSON_ESCAPES[char];
    if (escape !== undefined) {
      out += escape;
    } else if (unit < 0x20 || unit > 0x7f) {
      out += `\\u${unit.toString(16).padStart(4, '0')}`;
    } else {
      out += char;
    }
  }
  return `${out}"`;
}

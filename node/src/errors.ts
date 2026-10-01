/** What went wrong in a {@link PaywayError}. */
export type PaywayErrorType =
  /** PayWay could not be reached (DNS, refused connection, offline, ...) */
  | 'connection'
  /** the request took longer than the configured timeout */
  | 'timeout'
  /** the call was aborted with its `AbortSignal` */
  | 'cancelled'
  /** PayWay's TLS certificate was rejected */
  | 'badCertificate'
  /** PayWay answered without a PayWay `status` (e.g. an HTML error page) */
  | 'unexpectedResponse'
  /** the refund payload could not be encrypted (missing or invalid RSA key) */
  | 'encryption'
  /** a callback body is not the JSON object PayWay sends */
  | 'invalidCallback'
  /** any other failure; see `cause` */
  | 'unknown';

/**
 * Thrown when PayWay could not be reached or did not answer with a PayWay
 * status, and for invalid local input such as a missing RSA key. Branch on
 * {@link type}.
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are not
 * thrown: they are returned in the response `status`.
 */
export class PaywayError extends Error {
  override readonly name = 'PaywayError';

  /** HTTP status code, when a response was received */
  readonly statusCode: number | undefined;

  constructor(
    /** what went wrong */
    readonly type: PaywayErrorType,
    message: string,
    options: {
      /** HTTP status code, when a response was received */
      statusCode?: number;
      /** the underlying error */
      cause?: unknown;
    } = {},
  ) {
    super(message, { cause: options.cause });
    this.statusCode = options.statusCode;
  }

  /** whether retrying the same call later may succeed */
  get isRetryable(): boolean {
    return (
      this.type === 'connection' ||
      this.type === 'timeout' ||
      (this.type === 'unexpectedResponse' && (this.statusCode ?? 0) >= 500)
    );
  }
}

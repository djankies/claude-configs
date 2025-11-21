/**
 * @typedef {Object} FetchOptions
 * @property {string} method
 * @property {Record<string, string>} [headers]
 * @property {any} [body]
 * @property {number} [timeout]
 * @property {number} [retries]
 */

/**
 * @typedef {Object} FetchResult
 * @property {boolean} success
 * @property {any} [data]
 * @property {Error} [error]
 * @property {string} url
 * @property {number} statusCode
 * @property {number} duration
 */

/**
 * @typedef {Object} BatchFetchResult
 * @property {FetchResult[]} results
 * @property {number} successCount
 * @property {number} errorCount
 * @property {number} totalDuration
 */

/**
 * @typedef {Object} EndpointConfig
 * @property {string} url
 * @property {FetchOptions} [options]
 */

export {};

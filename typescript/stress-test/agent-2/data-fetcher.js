import { fetchWithRetry } from './fetcher.js';
import { fetchBatch } from './batch-fetcher.js';

export class DataFetcher {
  /**
   * @param {Object} config
   * @param {string} [config.baseURL]
   * @param {Record<string, string>} [config.headers]
   * @param {number} [config.timeout]
   * @param {number} [config.retries]
   */
  constructor(config = {}) {
    this.baseURL = config.baseURL || '';
    this.defaultHeaders = config.headers || {};
    this.defaultTimeout = config.timeout || 30000;
    this.defaultRetries = config.retries || 3;
  }

  /**
   * @param {string} url
   * @returns {string}
   */
  resolveURL(url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return this.baseURL + url;
  }

  /**
   * @param {string} url
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async fetch(url, options = {}) {
    const resolvedURL = this.resolveURL(url);
    const mergedOptions = {
      timeout: this.defaultTimeout,
      retries: this.defaultRetries,
      ...options,
      headers: {
        ...this.defaultHeaders,
        ...(options.headers || {})
      }
    };
    return fetchWithRetry(resolvedURL, mergedOptions);
  }

  /**
   * @param {string} url
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async get(url, options = {}) {
    return this.fetch(url, { ...options, method: 'GET' });
  }

  /**
   * @param {string} url
   * @param {any} body
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async post(url, body, options = {}) {
    return this.fetch(url, { ...options, method: 'POST', body });
  }

  /**
   * @param {string} url
   * @param {any} body
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async put(url, body, options = {}) {
    return this.fetch(url, { ...options, method: 'PUT', body });
  }

  /**
   * @param {string} url
   * @param {any} body
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async patch(url, body, options = {}) {
    return this.fetch(url, { ...options, method: 'PATCH', body });
  }

  /**
   * @param {string} url
   * @param {import('./types.js').FetchOptions} [options]
   * @returns {Promise<import('./types.js').FetchResult>}
   */
  async delete(url, options = {}) {
    return this.fetch(url, { ...options, method: 'DELETE' });
  }

  /**
   * @param {Array<import('./types.js').EndpointConfig>} endpoints
   * @param {Object} [options]
   * @param {number} [options.concurrency]
   * @param {boolean} [options.failFast]
   * @returns {Promise<import('./types.js').BatchFetchResult>}
   */
  async fetchBatch(endpoints, options = {}) {
    const resolvedEndpoints = endpoints.map(endpoint => ({
      url: this.resolveURL(endpoint.url),
      options: {
        timeout: this.defaultTimeout,
        retries: this.defaultRetries,
        ...endpoint.options,
        headers: {
          ...this.defaultHeaders,
          ...(endpoint.options?.headers || {})
        }
      }
    }));
    return fetchBatch(resolvedEndpoints, options);
  }

  /**
   * @param {string[]} urls
   * @param {import('./types.js').FetchOptions} [options]
   * @param {Object} [batchOptions]
   * @returns {Promise<import('./types.js').BatchFetchResult>}
   */
  async fetchMultiple(urls, options = {}, batchOptions = {}) {
    const endpoints = urls.map(url => ({
      url,
      options
    }));
    return this.fetchBatch(endpoints, batchOptions);
  }
}

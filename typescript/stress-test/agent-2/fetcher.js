import { setTimeout } from 'timers/promises';

/**
 * @param {string} url
 * @param {import('./types.js').FetchOptions} options
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function fetchWithRetry(url, options = {}) {
  const {
    method = 'GET',
    headers = {},
    body = null,
    timeout = 30000,
    retries = 3
  } = options;

  const startTime = Date.now();
  let lastError = null;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = globalThis.setTimeout(() => controller.abort(), timeout);

      const fetchOptions = {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        },
        signal: controller.signal
      };

      if (body && method !== 'GET' && method !== 'HEAD') {
        fetchOptions.body = typeof body === 'string' ? body : JSON.stringify(body);
      }

      const response = await fetch(url, fetchOptions);
      clearTimeout(timeoutId);

      const duration = Date.now() - startTime;
      const contentType = response.headers.get('content-type');
      let data;

      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      } else {
        data = await response.text();
      }

      return {
        success: response.ok,
        data,
        error: response.ok ? undefined : new Error(`HTTP ${response.status}: ${response.statusText}`),
        url,
        statusCode: response.status,
        duration
      };

    } catch (error) {
      lastError = error;

      if (attempt < retries) {
        const backoffDelay = Math.min(1000 * Math.pow(2, attempt), 10000);
        await setTimeout(backoffDelay);
      }
    }
  }

  const duration = Date.now() - startTime;
  return {
    success: false,
    error: lastError,
    url,
    statusCode: 0,
    duration
  };
}

/**
 * @param {string} url
 * @param {import('./types.js').FetchOptions} [options]
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function get(url, options = {}) {
  return fetchWithRetry(url, { ...options, method: 'GET' });
}

/**
 * @param {string} url
 * @param {any} body
 * @param {import('./types.js').FetchOptions} [options]
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function post(url, body, options = {}) {
  return fetchWithRetry(url, { ...options, method: 'POST', body });
}

/**
 * @param {string} url
 * @param {any} body
 * @param {import('./types.js').FetchOptions} [options]
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function put(url, body, options = {}) {
  return fetchWithRetry(url, { ...options, method: 'PUT', body });
}

/**
 * @param {string} url
 * @param {any} body
 * @param {import('./types.js').FetchOptions} [options]
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function patch(url, body, options = {}) {
  return fetchWithRetry(url, { ...options, method: 'PATCH', body });
}

/**
 * @param {string} url
 * @param {import('./types.js').FetchOptions} [options]
 * @returns {Promise<import('./types.js').FetchResult>}
 */
export async function del(url, options = {}) {
  return fetchWithRetry(url, { ...options, method: 'DELETE' });
}

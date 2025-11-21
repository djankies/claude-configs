import { fetchWithRetry } from './fetcher.js';

/**
 * @param {Array<import('./types.js').EndpointConfig>} endpoints
 * @param {Object} [options]
 * @param {number} [options.concurrency]
 * @param {boolean} [options.failFast]
 * @returns {Promise<import('./types.js').BatchFetchResult>}
 */
export async function fetchBatch(endpoints, options = {}) {
  const { concurrency = Infinity, failFast = false } = options;
  const startTime = Date.now();
  const results = [];

  if (concurrency === Infinity) {
    const promises = endpoints.map(endpoint =>
      fetchWithRetry(endpoint.url, endpoint.options)
        .then(result => {
          if (failFast && !result.success) {
            throw result.error || new Error('Request failed');
          }
          return result;
        })
    );

    if (failFast) {
      results.push(...await Promise.all(promises));
    } else {
      const settledResults = await Promise.allSettled(promises);
      results.push(...settledResults.map(settled =>
        settled.status === 'fulfilled'
          ? settled.value
          : {
              success: false,
              error: settled.reason,
              url: '',
              statusCode: 0,
              duration: 0
            }
      ));
    }
  } else {
    for (let i = 0; i < endpoints.length; i += concurrency) {
      const batch = endpoints.slice(i, i + concurrency);
      const promises = batch.map(endpoint =>
        fetchWithRetry(endpoint.url, endpoint.options)
          .then(result => {
            if (failFast && !result.success) {
              throw result.error || new Error('Request failed');
            }
            return result;
          })
      );

      if (failFast) {
        results.push(...await Promise.all(promises));
      } else {
        const settledResults = await Promise.allSettled(promises);
        results.push(...settledResults.map(settled =>
          settled.status === 'fulfilled'
            ? settled.value
            : {
                success: false,
                error: settled.reason,
                url: '',
                statusCode: 0,
                duration: 0
              }
        ));
      }
    }
  }

  const successCount = results.filter(r => r.success).length;
  const errorCount = results.filter(r => !r.success).length;
  const totalDuration = Date.now() - startTime;

  return {
    results,
    successCount,
    errorCount,
    totalDuration
  };
}

/**
 * @param {string[]} urls
 * @param {import('./types.js').FetchOptions} [options]
 * @param {Object} [batchOptions]
 * @param {number} [batchOptions.concurrency]
 * @param {boolean} [batchOptions.failFast]
 * @returns {Promise<import('./types.js').BatchFetchResult>}
 */
export async function fetchMultiple(urls, options = {}, batchOptions = {}) {
  const endpoints = urls.map(url => ({ url, options }));
  return fetchBatch(endpoints, batchOptions);
}

/**
 * @param {Record<string, string>} urlMap
 * @param {import('./types.js').FetchOptions} [options]
 * @param {Object} [batchOptions]
 * @param {number} [batchOptions.concurrency]
 * @param {boolean} [batchOptions.failFast]
 * @returns {Promise<Record<string, import('./types.js').FetchResult>>}
 */
export async function fetchMap(urlMap, options = {}, batchOptions = {}) {
  const keys = Object.keys(urlMap);
  const endpoints = keys.map(key => ({ url: urlMap[key], options }));

  const batchResult = await fetchBatch(endpoints, batchOptions);

  const resultMap = {};
  keys.forEach((key, index) => {
    resultMap[key] = batchResult.results[index];
  });

  return resultMap;
}

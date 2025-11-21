# Data Fetching Utility

A robust, reusable data fetching utility for Node.js applications with support for concurrent API calls, automatic retries, and graceful error handling.

## Features

- **Concurrent Fetching**: Fetch multiple endpoints simultaneously with configurable concurrency limits
- **Automatic Retries**: Built-in retry logic with exponential backoff
- **Type Safety**: JSDoc type annotations for better IDE support
- **Error Handling**: Graceful error handling with detailed error information
- **Flexible API**: Support for single requests, batch operations, and mapped results
- **Timeout Control**: Configurable timeouts for all requests
- **HTTP Methods**: Support for GET, POST, PUT, PATCH, and DELETE
- **Class-based or Functional**: Use standalone functions or the DataFetcher class

## Installation

```bash
npm install
```

## Usage

### Single Request

```javascript
import { get, post } from './index.js';

const result = await get('https://api.example.com/data');
if (result.success) {
  console.log(result.data);
}

const postResult = await post('https://api.example.com/data', {
  title: 'New Item',
  content: 'Hello World'
});
```

### Batch Requests

```javascript
import { fetchMultiple } from './index.js';

const urls = [
  'https://api.example.com/users/1',
  'https://api.example.com/users/2',
  'https://api.example.com/users/3'
];

const batchResult = await fetchMultiple(urls);
console.log(`Success: ${batchResult.successCount}/${batchResult.results.length}`);
```

### Mapped Requests

```javascript
import { fetchMap } from './index.js';

const urlMap = {
  user: 'https://api.example.com/user',
  posts: 'https://api.example.com/posts',
  comments: 'https://api.example.com/comments'
};

const results = await fetchMap(urlMap);
console.log(results.user.data);
console.log(results.posts.data);
```

### DataFetcher Class

```javascript
import { DataFetcher } from './index.js';

const fetcher = new DataFetcher({
  baseURL: 'https://api.example.com',
  headers: {
    'Authorization': 'Bearer token123'
  },
  timeout: 5000,
  retries: 3
});

const result = await fetcher.get('/users/1');
const batchResult = await fetcher.fetchMultiple(['/users/1', '/users/2']);
```

### Concurrency Control

```javascript
import { fetchMultiple } from './index.js';

const urls = [...];

const result = await fetchMultiple(urls, {}, {
  concurrency: 5,
  failFast: false
});
```

## API Reference

### Functions

#### `get(url, options)`
Performs a GET request.

#### `post(url, body, options)`
Performs a POST request.

#### `put(url, body, options)`
Performs a PUT request.

#### `patch(url, body, options)`
Performs a PATCH request.

#### `del(url, options)`
Performs a DELETE request.

#### `fetchMultiple(urls, options, batchOptions)`
Fetches multiple URLs concurrently.

#### `fetchMap(urlMap, options, batchOptions)`
Fetches URLs and returns a mapped object of results.

### DataFetcher Class

#### Constructor Options
- `baseURL`: Base URL for all requests
- `headers`: Default headers for all requests
- `timeout`: Default timeout in milliseconds
- `retries`: Default number of retry attempts

#### Methods
- `get(url, options)`
- `post(url, body, options)`
- `put(url, body, options)`
- `patch(url, body, options)`
- `delete(url, options)`
- `fetchBatch(endpoints, options)`
- `fetchMultiple(urls, options, batchOptions)`

### Options

#### FetchOptions
- `method`: HTTP method
- `headers`: Request headers
- `body`: Request body
- `timeout`: Request timeout in ms
- `retries`: Number of retry attempts

#### BatchOptions
- `concurrency`: Maximum concurrent requests
- `failFast`: Stop on first error

### Result Types

#### FetchResult
- `success`: Boolean indicating success
- `data`: Response data
- `error`: Error object if failed
- `url`: Request URL
- `statusCode`: HTTP status code
- `duration`: Request duration in ms

#### BatchFetchResult
- `results`: Array of FetchResult objects
- `successCount`: Number of successful requests
- `errorCount`: Number of failed requests
- `totalDuration`: Total duration in ms

## Testing

```bash
npm test
```

## Microservices Integration

This utility is designed for microservices architectures:

1. **Service Discovery**: Use with service mesh or discovery tools
2. **Circuit Breakers**: Integrate with circuit breaker patterns
3. **Monitoring**: Built-in timing and error metrics
4. **Resilience**: Automatic retries and timeout handling

## Performance

- Concurrent requests reduce total latency
- Configurable concurrency prevents overwhelming services
- Exponential backoff reduces server load during retries
- Connection reuse through native fetch API

## Error Handling

All errors are caught and returned in the result object:

```javascript
const result = await get('https://api.example.com/data');
if (!result.success) {
  console.error(`Request failed: ${result.error.message}`);
  console.error(`Status: ${result.statusCode}`);
}
```

## License

MIT

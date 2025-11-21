import { get, post, fetchMultiple, fetchMap } from './index.js';
import { DataFetcher } from './data-fetcher.js';

async function testSingleFetch() {
  console.log('\n=== Testing Single Fetch ===');

  const result = await get('https://jsonplaceholder.typicode.com/posts/1');

  console.log('Success:', result.success);
  console.log('Status Code:', result.statusCode);
  console.log('Duration:', result.duration, 'ms');
  console.log('Data:', result.data);
}

async function testPostRequest() {
  console.log('\n=== Testing POST Request ===');

  const result = await post(
    'https://jsonplaceholder.typicode.com/posts',
    {
      title: 'Test Post',
      body: 'This is a test',
      userId: 1
    }
  );

  console.log('Success:', result.success);
  console.log('Status Code:', result.statusCode);
  console.log('Duration:', result.duration, 'ms');
  console.log('Created Post ID:', result.data?.id);
}

async function testBatchFetch() {
  console.log('\n=== Testing Batch Fetch ===');

  const urls = [
    'https://jsonplaceholder.typicode.com/posts/1',
    'https://jsonplaceholder.typicode.com/posts/2',
    'https://jsonplaceholder.typicode.com/posts/3',
    'https://jsonplaceholder.typicode.com/users/1',
    'https://jsonplaceholder.typicode.com/users/2'
  ];

  const batchResult = await fetchMultiple(urls);

  console.log('Total Duration:', batchResult.totalDuration, 'ms');
  console.log('Success Count:', batchResult.successCount);
  console.log('Error Count:', batchResult.errorCount);
  console.log('Results:', batchResult.results.length);
}

async function testFetchMap() {
  console.log('\n=== Testing Fetch Map ===');

  const urlMap = {
    post1: 'https://jsonplaceholder.typicode.com/posts/1',
    post2: 'https://jsonplaceholder.typicode.com/posts/2',
    user1: 'https://jsonplaceholder.typicode.com/users/1'
  };

  const results = await fetchMap(urlMap);

  console.log('Post 1 Title:', results.post1.data?.title);
  console.log('Post 2 Title:', results.post2.data?.title);
  console.log('User 1 Name:', results.user1.data?.name);
}

async function testDataFetcherClass() {
  console.log('\n=== Testing DataFetcher Class ===');

  const fetcher = new DataFetcher({
    baseURL: 'https://jsonplaceholder.typicode.com',
    headers: {
      'X-Custom-Header': 'test-value'
    },
    timeout: 5000,
    retries: 2
  });

  const result = await fetcher.get('/posts/1');
  console.log('Success:', result.success);
  console.log('Post Title:', result.data?.title);

  const batchResult = await fetcher.fetchMultiple([
    '/posts/1',
    '/posts/2',
    '/posts/3'
  ], {}, { concurrency: 2 });

  console.log('Batch Success Count:', batchResult.successCount);
  console.log('Batch Total Duration:', batchResult.totalDuration, 'ms');
}

async function testErrorHandling() {
  console.log('\n=== Testing Error Handling ===');

  const result = await get('https://jsonplaceholder.typicode.com/posts/99999999');

  console.log('Success:', result.success);
  console.log('Status Code:', result.statusCode);
  console.log('Error:', result.error?.message);
}

async function testConcurrencyControl() {
  console.log('\n=== Testing Concurrency Control ===');

  const urls = Array.from({ length: 10 }, (_, i) =>
    `https://jsonplaceholder.typicode.com/posts/${i + 1}`
  );

  const startTime = Date.now();
  const result = await fetchMultiple(urls, {}, { concurrency: 3 });
  const duration = Date.now() - startTime;

  console.log('Total Requests:', urls.length);
  console.log('Concurrency:', 3);
  console.log('Success Count:', result.successCount);
  console.log('Total Duration:', duration, 'ms');
  console.log('Avg Duration per Request:', duration / urls.length, 'ms');
}

async function runAllTests() {
  try {
    await testSingleFetch();
    await testPostRequest();
    await testBatchFetch();
    await testFetchMap();
    await testDataFetcherClass();
    await testErrorHandling();
    await testConcurrencyControl();

    console.log('\n=== All Tests Completed ===');
  } catch (error) {
    console.error('Test failed:', error);
    process.exit(1);
  }
}

runAllTests();

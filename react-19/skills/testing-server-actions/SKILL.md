---
name: testing-server-actions
description: Teaches testing Server Actions in isolation in React 19. Use when testing Server Actions, form handling, or server-side logic.
allowed-tools: Read, Write, Edit
version: 1.0.0
---

# Testing Server Actions

## Basic Server Action Test

```javascript
import { submitContact } from './actions';

test('submitContact validates email', async () => {
  const formData = new FormData();
  formData.set('email', 'invalid');
  formData.set('message', 'Hello');

  const result = await submitContact(null, formData);

  expect(result.error).toBeTruthy();
});

test('submitContact succeeds with valid data', async () => {
  const formData = new FormData();
  formData.set('email', 'test@example.com');
  formData.set('message', 'Hello');

  const result = await submitContact(null, formData);

  expect(result.success).toBe(true);
});
```

## Mocking Database Calls

```javascript
import { createUser } from './actions';
import { db } from './db';

jest.mock('./db', () => ({
  db: {
    users: {
      create: jest.fn(),
    },
  },
}));

test('createUser creates database record', async () => {
  db.users.create.mockResolvedValue({ id: '123', name: 'Alice' });

  const formData = new FormData();
  formData.set('name', 'Alice');
  formData.set('email', 'alice@example.com');

  const result = await createUser(null, formData);

  expect(db.users.create).toHaveBeenCalledWith({
    name: 'Alice',
    email: 'alice@example.com',
  });

  expect(result.success).toBe(true);
  expect(result.userId).toBe('123');
});
```

## Testing with Authentication

```javascript
import { deletePost } from './actions';
import { getSession } from './auth';

jest.mock('./auth');

test('deletePost requires authentication', async () => {
  getSession.mockResolvedValue(null);

  await expect(deletePost('post-123')).rejects.toThrow('Unauthorized');
});

test('deletePost checks ownership', async () => {
  getSession.mockResolvedValue({ user: { id: 'user-1' } });

  await expect(deletePost('post-owned-by-user-2')).rejects.toThrow('Forbidden');
});
```

For comprehensive Server Action testing, test the function directly in isolation.

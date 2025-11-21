import express, { Express } from 'express';
import { Database } from './database';
import { createRouter } from './routes';
import { errorHandler, notFoundHandler, requestLogger } from './middleware';

const PORT = process.env.PORT || 3000;

function createApp(): Express {
  const app = express();
  const database = new Database();

  app.use(express.json());
  app.use(requestLogger);

  app.use('/api/users', createRouter(database));

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

function startServer(): void {
  const app = createApp();

  app.listen(PORT, () => {
    console.log(`User Validation API running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/users/health`);
    console.log(`Register endpoint: POST http://localhost:${PORT}/api/users/register`);
  });
}

if (require.main === module) {
  startServer();
}

export { createApp };

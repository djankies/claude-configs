import { Router } from 'express';
import { UserController } from './controller';
import { Database } from './database';

export function createRouter(database: Database): Router {
  const router = Router();
  const controller = new UserController(database);

  router.post('/register', (req, res) => controller.registerUser(req, res));
  router.get('/health', (req, res) => controller.healthCheck(req, res));

  return router;
}

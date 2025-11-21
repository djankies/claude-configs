import { Request, Response } from 'express';
import { UserValidator } from './validator';
import { Database } from './database';
import { UserRegistrationData, ApiResponse } from './types';

export class UserController {
  private validator: UserValidator;
  private database: Database;

  constructor(database: Database) {
    this.validator = new UserValidator();
    this.database = database;
  }

  async registerUser(req: Request, res: Response): Promise<void> {
    try {
      const userData: UserRegistrationData = {
        email: req.body.email,
        name: req.body.name,
        password: req.body.password
      };

      const validationResult = this.validator.validate(userData);

      if (!validationResult.isValid) {
        const response: ApiResponse = {
          success: false,
          message: 'Validation failed',
          errors: validationResult.errors
        };
        res.status(400).json(response);
        return;
      }

      const existingUser = await this.database.findByEmail(userData.email);
      if (existingUser) {
        const response: ApiResponse = {
          success: false,
          message: 'Email already registered',
          errors: [{ field: 'email', message: 'This email is already in use' }]
        };
        res.status(409).json(response);
        return;
      }

      const savedUser = await this.database.saveUser(userData);

      const response: ApiResponse = {
        success: true,
        message: 'User registered successfully',
        data: {
          id: savedUser.id,
          email: savedUser.email,
          name: savedUser.name,
          createdAt: savedUser.createdAt
        }
      };

      res.status(201).json(response);
    } catch (error) {
      console.error('Registration error:', error);

      const response: ApiResponse = {
        success: false,
        message: 'Internal server error',
        errors: [{ field: 'server', message: 'An unexpected error occurred' }]
      };

      res.status(500).json(response);
    }
  }

  async healthCheck(req: Request, res: Response): Promise<void> {
    const stats = this.database.getStats();
    res.status(200).json({
      success: true,
      message: 'API is healthy',
      data: {
        status: 'operational',
        timestamp: new Date().toISOString(),
        stats
      }
    });
  }
}

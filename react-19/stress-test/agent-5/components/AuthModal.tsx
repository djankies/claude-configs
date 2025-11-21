'use client';

import { useState, useActionState } from 'react';
import { Modal } from './Modal';
import { useAuth } from '../context/AuthContext';
import { authenticateUser } from '../actions/auth';
import { useAuthAction } from '../hooks/useAuthAction';

type FormMode = 'login' | 'signup';

export function AuthModal() {
  const { isModalOpen, closeModal } = useAuth();
  const [mode, setMode] = useState<FormMode>('login');
  const [state, formAction, isPending] = useActionState(authenticateUser, null);

  useAuthAction(state);

  const toggleMode = () => {
    setMode(prev => prev === 'login' ? 'signup' : 'login');
  };

  return (
    <Modal
      isOpen={isModalOpen}
      onClose={closeModal}
      title={mode === 'login' ? 'Welcome Back' : 'Create Account'}
    >
      <form action={formAction} className="space-y-4">
        <input type="hidden" name="mode" value={mode} />

        {state?.error && (
          <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
            <p className="text-sm text-red-600 dark:text-red-400">{state.error}</p>
          </div>
        )}

        {mode === 'signup' && (
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Full Name
            </label>
            <input
              type="text"
              id="name"
              name="name"
              required={mode === 'signup'}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
              placeholder="John Doe"
              disabled={isPending}
            />
            {state?.fieldErrors?.name && (
              <p className="mt-1 text-sm text-red-600 dark:text-red-400">{state.fieldErrors.name}</p>
            )}
          </div>
        )}

        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Email Address
          </label>
          <input
            type="email"
            id="email"
            name="email"
            required
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder="you@example.com"
            disabled={isPending}
          />
          {state?.fieldErrors?.email && (
            <p className="mt-1 text-sm text-red-600 dark:text-red-400">{state.fieldErrors.email}</p>
          )}
        </div>

        <div>
          <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Password
          </label>
          <input
            type="password"
            id="password"
            name="password"
            required
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder="••••••••"
            disabled={isPending}
            minLength={8}
          />
          {state?.fieldErrors?.password && (
            <p className="mt-1 text-sm text-red-600 dark:text-red-400">{state.fieldErrors.password}</p>
          )}
        </div>

        <button
          type="submit"
          disabled={isPending}
          className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          {isPending ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Processing...
            </span>
          ) : (
            mode === 'login' ? 'Sign In' : 'Create Account'
          )}
        </button>

        <div className="text-center">
          <button
            type="button"
            onClick={toggleMode}
            disabled={isPending}
            className="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 disabled:opacity-50"
          >
            {mode === 'login'
              ? "Don't have an account? Sign up"
              : 'Already have an account? Sign in'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

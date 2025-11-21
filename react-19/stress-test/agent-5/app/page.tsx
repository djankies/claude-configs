'use client';

import { useAuth } from '../context/AuthContext';

export default function HomePage() {
  const { user, isAuthenticated, openModal } = useAuth();

  return (
    <div className="space-y-8">
      <section className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
          Welcome to the Auth Modal Demo
        </h1>
        <p className="text-gray-600 dark:text-gray-300 mb-6">
          This demonstrates a production-ready authentication modal system with global state management.
        </p>

        {isAuthenticated ? (
          <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-md p-4">
            <h2 className="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">
              You're logged in!
            </h2>
            <p className="text-green-700 dark:text-green-300">
              Welcome back, <strong>{user?.name}</strong> ({user?.email})
            </p>
          </div>
        ) : (
          <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-md p-4">
            <h2 className="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">
              Not logged in
            </h2>
            <p className="text-blue-700 dark:text-blue-300 mb-4">
              Click the button below to open the authentication modal.
            </p>
            <button
              onClick={openModal}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md transition-colors"
            >
              Open Login Modal
            </button>
          </div>
        )}
      </section>

      <section className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
          Features
        </h2>
        <ul className="space-y-3 text-gray-600 dark:text-gray-300">
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Global authentication state shared across all components</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Modal can be triggered from any page or component</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Server-side validation with comprehensive error handling</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Persistent user data and theme preference in localStorage</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Dark/light theme support synchronized across app</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Works with both client and server components</span>
          </li>
          <li className="flex items-start">
            <svg className="w-6 h-6 text-green-500 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            <span>Production-ready with loading states and accessibility</span>
          </li>
        </ul>
      </section>

      <section className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
          Navigation
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <a
            href="/dashboard"
            className="block p-4 border-2 border-gray-200 dark:border-gray-700 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors"
          >
            <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Dashboard</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">
              Protected page showing user profile
            </p>
          </a>
          <a
            href="/settings"
            className="block p-4 border-2 border-gray-200 dark:border-gray-700 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors"
          >
            <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Settings</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">
              Page with action buttons to test modal from different locations
            </p>
          </a>
        </div>
      </section>
    </div>
  );
}

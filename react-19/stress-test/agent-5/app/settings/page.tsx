'use client';

import { useAuth } from '../../context/AuthContext';

export default function SettingsPage() {
  const { user, isAuthenticated, theme, openModal, toggleTheme } = useAuth();

  return (
    <div className="space-y-8">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-6">
          Settings
        </h1>
        <p className="text-gray-600 dark:text-gray-300">
          Manage your application preferences and test modal triggers.
        </p>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          Appearance
        </h2>

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white">Theme</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Currently using {theme} mode
              </p>
            </div>
            <button
              onClick={toggleTheme}
              className="px-6 py-3 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-900 dark:text-white font-medium rounded-md transition-colors"
            >
              Toggle Theme
            </button>
          </div>

          <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
            <div className="grid grid-cols-2 gap-4">
              <div className={`p-4 border-2 rounded-lg ${theme === 'light' ? 'border-blue-500 bg-blue-50' : 'border-gray-300 bg-white'}`}>
                <div className="flex items-center justify-center h-20 bg-white rounded shadow-sm mb-2">
                  <svg className="w-12 h-12 text-yellow-500" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
                </div>
                <p className="text-center text-sm font-medium text-gray-900">Light Mode</p>
              </div>
              <div className={`p-4 border-2 rounded-lg ${theme === 'dark' ? 'border-blue-500 bg-gray-900' : 'border-gray-300 bg-white'}`}>
                <div className="flex items-center justify-center h-20 bg-gray-800 rounded shadow-sm mb-2">
                  <svg className="w-12 h-12 text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                  </svg>
                </div>
                <p className="text-center text-sm font-medium text-gray-900 dark:text-white">Dark Mode</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          Account
        </h2>

        <div className="space-y-4">
          {isAuthenticated ? (
            <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-md p-4">
              <h3 className="text-lg font-semibold text-green-900 dark:text-green-100 mb-2">
                Signed in as {user?.name}
              </h3>
              <p className="text-green-700 dark:text-green-300 text-sm mb-4">
                Email: {user?.email}
              </p>
              <p className="text-green-700 dark:text-green-300 text-sm">
                Your authentication state is persisted across all pages and survives page refreshes.
              </p>
            </div>
          ) : (
            <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-md p-4">
              <h3 className="text-lg font-semibold text-yellow-900 dark:text-yellow-100 mb-2">
                Not signed in
              </h3>
              <p className="text-yellow-700 dark:text-yellow-300 text-sm mb-4">
                Sign in to access all features and persist your preferences.
              </p>
              <button
                onClick={openModal}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md transition-colors"
              >
                Sign In
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          Modal Testing
        </h2>
        <p className="text-gray-600 dark:text-gray-300 mb-6">
          Test opening the authentication modal from different contexts and locations.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <button
            onClick={openModal}
            className="p-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md transition-colors text-left"
          >
            <h3 className="font-semibold mb-1">Open Modal (Primary)</h3>
            <p className="text-sm text-blue-100">Standard modal trigger</p>
          </button>

          <button
            onClick={openModal}
            className="p-4 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-md transition-colors text-left"
          >
            <h3 className="font-semibold mb-1">Open Modal (Secondary)</h3>
            <p className="text-sm text-purple-100">Same modal, different button</p>
          </button>

          <button
            onClick={openModal}
            className="p-4 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-md transition-colors text-left"
          >
            <h3 className="font-semibold mb-1">Open Modal (Tertiary)</h3>
            <p className="text-sm text-indigo-100">Global state working everywhere</p>
          </button>

          <button
            onClick={openModal}
            className="p-4 bg-pink-600 hover:bg-pink-700 text-white font-medium rounded-md transition-colors text-left"
          >
            <h3 className="font-semibold mb-1">Open Modal (Quaternary)</h3>
            <p className="text-sm text-pink-100">Demonstrating reusability</p>
          </button>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          System Information
        </h2>

        <dl className="grid grid-cols-1 gap-4">
          <div>
            <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Authentication Status</dt>
            <dd className="mt-1 text-sm text-gray-900 dark:text-white">
              {isAuthenticated ? (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300">
                  Authenticated
                </span>
              ) : (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                  Not Authenticated
                </span>
              )}
            </dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Theme Mode</dt>
            <dd className="mt-1 text-sm text-gray-900 dark:text-white capitalize">{theme}</dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">State Persistence</dt>
            <dd className="mt-1 text-sm text-gray-900 dark:text-white">localStorage</dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Modal System</dt>
            <dd className="mt-1 text-sm text-gray-900 dark:text-white">Portal-based with global state</dd>
          </div>
        </dl>
      </div>
    </div>
  );
}

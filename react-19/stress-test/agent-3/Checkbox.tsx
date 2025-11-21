import React, { forwardRef } from 'react';
import type { CheckboxProps } from './types';

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
  ({ label, error, helperText, className, ...props }, ref) => {
    const checkboxId = props.id || `checkbox-${Math.random().toString(36).substr(2, 9)}`;
    const hasError = Boolean(error);

    const checkboxClassName = [
      'w-4 h-4 rounded border-gray-300 transition-colors',
      hasError ? 'border-red-500 text-red-600 focus:ring-red-500' : 'text-blue-600 focus:ring-blue-500',
      'focus:ring-2 focus:ring-offset-2',
      'disabled:bg-gray-100 disabled:cursor-not-allowed',
      className
    ].filter(Boolean).join(' ');

    return (
      <div>
        <div className="flex items-center">
          <input
            ref={ref}
            type="checkbox"
            id={checkboxId}
            className={checkboxClassName}
            aria-invalid={hasError}
            aria-describedby={hasError ? `${checkboxId}-error` : helperText ? `${checkboxId}-helper` : undefined}
            {...props}
          />
          {label && (
            <label
              htmlFor={checkboxId}
              className="ml-2 text-sm font-medium text-gray-700 cursor-pointer"
            >
              {label}
            </label>
          )}
        </div>
        {error && (
          <p id={`${checkboxId}-error`} className="mt-1 text-sm text-red-600 ml-6">
            {error}
          </p>
        )}
        {!error && helperText && (
          <p id={`${checkboxId}-helper`} className="mt-1 text-sm text-gray-500 ml-6">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

Checkbox.displayName = 'Checkbox';

import React, { forwardRef } from 'react';
import type { TextFieldProps } from './types';

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  ({ label, error, helperText, fullWidth, className, ...props }, ref) => {
    const inputId = props.id || `textfield-${Math.random().toString(36).substr(2, 9)}`;
    const hasError = Boolean(error);

    const inputClassName = [
      'px-3 py-2 border rounded-md transition-colors',
      hasError ? 'border-red-500 focus:border-red-600 focus:ring-red-500' : 'border-gray-300 focus:border-blue-500 focus:ring-blue-500',
      'focus:outline-none focus:ring-2',
      'disabled:bg-gray-100 disabled:cursor-not-allowed',
      fullWidth ? 'w-full' : '',
      className
    ].filter(Boolean).join(' ');

    return (
      <div className={fullWidth ? 'w-full' : ''}>
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={inputClassName}
          aria-invalid={hasError}
          aria-describedby={hasError ? `${inputId}-error` : helperText ? `${inputId}-helper` : undefined}
          {...props}
        />
        {error && (
          <p id={`${inputId}-error`} className="mt-1 text-sm text-red-600">
            {error}
          </p>
        )}
        {!error && helperText && (
          <p id={`${inputId}-helper`} className="mt-1 text-sm text-gray-500">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

TextField.displayName = 'TextField';

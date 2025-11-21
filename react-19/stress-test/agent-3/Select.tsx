import React, { forwardRef } from 'react';
import type { SelectProps } from './types';

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, helperText, fullWidth, options, placeholder, className, ...props }, ref) => {
    const selectId = props.id || `select-${Math.random().toString(36).substr(2, 9)}`;
    const hasError = Boolean(error);

    const selectClassName = [
      'px-3 py-2 border rounded-md transition-colors',
      hasError ? 'border-red-500 focus:border-red-600 focus:ring-red-500' : 'border-gray-300 focus:border-blue-500 focus:ring-blue-500',
      'focus:outline-none focus:ring-2',
      'disabled:bg-gray-100 disabled:cursor-not-allowed',
      'bg-white',
      fullWidth ? 'w-full' : '',
      className
    ].filter(Boolean).join(' ');

    return (
      <div className={fullWidth ? 'w-full' : ''}>
        {label && (
          <label
            htmlFor={selectId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={selectClassName}
          aria-invalid={hasError}
          aria-describedby={hasError ? `${selectId}-error` : helperText ? `${selectId}-helper` : undefined}
          {...props}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        {error && (
          <p id={`${selectId}-error`} className="mt-1 text-sm text-red-600">
            {error}
          </p>
        )}
        {!error && helperText && (
          <p id={`${selectId}-helper`} className="mt-1 text-sm text-gray-500">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

Select.displayName = 'Select';

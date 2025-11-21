import React, { useRef, FormEvent } from 'react';
import { TextField, Select, Checkbox } from './index';
import type { SelectOption } from './types';

export function FormExample() {
  const nameInputRef = useRef<HTMLInputElement>(null);
  const emailInputRef = useRef<HTMLInputElement>(null);
  const roleSelectRef = useRef<HTMLSelectElement>(null);
  const termsCheckboxRef = useRef<HTMLInputElement>(null);

  const roleOptions: SelectOption[] = [
    { value: 'developer', label: 'Developer' },
    { value: 'designer', label: 'Designer' },
    { value: 'manager', label: 'Manager' },
    { value: 'other', label: 'Other' }
  ];

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!nameInputRef.current?.value) {
      nameInputRef.current?.focus();
      return;
    }

    if (!emailInputRef.current?.value) {
      emailInputRef.current?.focus();
      return;
    }

    if (!roleSelectRef.current?.value) {
      roleSelectRef.current?.focus();
      return;
    }

    if (!termsCheckboxRef.current?.checked) {
      termsCheckboxRef.current?.focus();
      return;
    }

    const formData = {
      name: nameInputRef.current.value,
      email: emailInputRef.current.value,
      role: roleSelectRef.current.value,
      terms: termsCheckboxRef.current.checked
    };

    console.log('Form submitted:', formData);
  };

  const focusFirstInput = () => {
    nameInputRef.current?.focus();
  };

  return (
    <div className="max-w-md mx-auto p-6">
      <h2 className="text-2xl font-bold mb-6">User Registration</h2>

      <form onSubmit={handleSubmit} className="space-y-4">
        <TextField
          ref={nameInputRef}
          label="Full Name"
          name="name"
          placeholder="Enter your full name"
          required
          fullWidth
          helperText="Your legal name as it appears on documents"
        />

        <TextField
          ref={emailInputRef}
          label="Email Address"
          name="email"
          type="email"
          placeholder="you@example.com"
          required
          fullWidth
          helperText="We'll never share your email"
        />

        <Select
          ref={roleSelectRef}
          label="Role"
          name="role"
          options={roleOptions}
          placeholder="Select your role"
          required
          fullWidth
          helperText="Choose the role that best describes you"
        />

        <Checkbox
          ref={termsCheckboxRef}
          label="I agree to the terms and conditions"
          name="terms"
          required
        />

        <div className="flex gap-2 pt-4">
          <button
            type="submit"
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Submit
          </button>

          <button
            type="button"
            onClick={focusFirstInput}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors"
          >
            Focus First Field
          </button>
        </div>
      </form>
    </div>
  );
}

export function ValidationExample() {
  return (
    <div className="max-w-md mx-auto p-6 space-y-4">
      <h2 className="text-2xl font-bold mb-6">Error States</h2>

      <TextField
        label="Username"
        error="Username is already taken"
        defaultValue="john_doe"
        fullWidth
      />

      <TextField
        label="Password"
        type="password"
        helperText="Must be at least 8 characters"
        fullWidth
      />

      <Select
        label="Country"
        options={[
          { value: 'us', label: 'United States' },
          { value: 'uk', label: 'United Kingdom' },
          { value: 'ca', label: 'Canada' }
        ]}
        error="Please select a country"
        fullWidth
      />

      <Checkbox
        label="Send me promotional emails"
        defaultChecked
      />

      <Checkbox
        label="I agree to data processing"
        error="You must agree to continue"
      />
    </div>
  );
}

export function DisabledExample() {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <div className="max-w-md mx-auto p-6 space-y-4">
      <h2 className="text-2xl font-bold mb-6">Disabled States</h2>

      <TextField
        ref={inputRef}
        label="Read-only Field"
        value="This field is disabled"
        disabled
        fullWidth
      />

      <Select
        label="Disabled Select"
        options={[{ value: 'option1', label: 'Option 1' }]}
        disabled
        fullWidth
      />

      <Checkbox
        label="Disabled checkbox"
        disabled
      />

      <button
        onClick={() => inputRef.current?.focus()}
        className="px-4 py-2 bg-blue-600 text-white rounded-md"
      >
        Try to Focus Disabled Field
      </button>
    </div>
  );
}

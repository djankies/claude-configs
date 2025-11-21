'use client';

import { useActionState, useOptimistic, useState, useEffect } from 'react';
import type { UserProfile, FormState, ValidationError } from './types';
import { updateProfile } from './actions';
import { validateProfile } from './validation';

interface ProfileEditorProps {
  userId: string;
  initialProfile: UserProfile;
}

export function ProfileEditor({ userId, initialProfile }: ProfileEditorProps) {
  const [optimisticProfile, setOptimisticProfile] = useOptimistic(
    initialProfile,
    (state, newProfile: Partial<UserProfile>) => ({
      ...state,
      ...newProfile,
    })
  );

  const [clientErrors, setClientErrors] = useState<ValidationError[]>([]);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    setIsHydrated(true);
  }, []);

  const [formState, formAction, isPending] = useActionState<FormState, FormData>(
    (prevState, formData) => updateProfile(userId, prevState, formData),
    { errors: [], success: false }
  );

  const handleSubmit = (formData: FormData) => {
    const data = {
      name: formData.get('name') as string,
      email: formData.get('email') as string,
      bio: formData.get('bio') as string,
    };

    if (isHydrated) {
      const errors = validateProfile(data);
      setClientErrors(errors);

      if (errors.length > 0) {
        return;
      }
    }

    setOptimisticProfile(data);
    formAction(formData);
  };

  const getFieldError = (fieldName: string): string | undefined => {
    const clientError = clientErrors.find((e) => e.field === fieldName);
    if (clientError) return clientError.message;

    const serverError = formState.errors.find((e) => e.field === fieldName);
    return serverError?.message;
  };

  const showMessage = formState.message && !isPending;

  return (
    <div className="profile-editor">
      <h2>Edit Profile</h2>

      {showMessage && (
        <div
          className={`message ${formState.success ? 'success' : 'error'}`}
          role="alert"
        >
          {formState.message}
        </div>
      )}

      <form action={handleSubmit}>
        <div className="form-group">
          <label htmlFor="name">
            Name <span className="required">*</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            defaultValue={optimisticProfile.name}
            required
            maxLength={100}
            className={getFieldError('name') ? 'error' : ''}
            aria-invalid={!!getFieldError('name')}
            aria-describedby={getFieldError('name') ? 'name-error' : undefined}
          />
          {getFieldError('name') && (
            <span id="name-error" className="error-message" role="alert">
              {getFieldError('name')}
            </span>
          )}
        </div>

        <div className="form-group">
          <label htmlFor="email">
            Email <span className="required">*</span>
          </label>
          <input
            type="email"
            id="email"
            name="email"
            defaultValue={optimisticProfile.email}
            required
            maxLength={255}
            className={getFieldError('email') ? 'error' : ''}
            aria-invalid={!!getFieldError('email')}
            aria-describedby={getFieldError('email') ? 'email-error' : undefined}
          />
          {getFieldError('email') && (
            <span id="email-error" className="error-message" role="alert">
              {getFieldError('email')}
            </span>
          )}
        </div>

        <div className="form-group">
          <label htmlFor="bio">
            Bio <span className="required">*</span>
          </label>
          <textarea
            id="bio"
            name="bio"
            defaultValue={optimisticProfile.bio}
            required
            minLength={10}
            maxLength={500}
            rows={5}
            className={getFieldError('bio') ? 'error' : ''}
            aria-invalid={!!getFieldError('bio')}
            aria-describedby={getFieldError('bio') ? 'bio-error' : undefined}
          />
          {getFieldError('bio') && (
            <span id="bio-error" className="error-message" role="alert">
              {getFieldError('bio')}
            </span>
          )}
          <small className="help-text">
            {optimisticProfile.bio.length}/500 characters
          </small>
        </div>

        <div className="form-actions">
          <button
            type="submit"
            disabled={isPending}
            className="submit-button"
            aria-busy={isPending}
          >
            {isPending ? 'Saving...' : 'Save Profile'}
          </button>
        </div>
      </form>

      <style jsx>{`
        .profile-editor {
          max-width: 600px;
          margin: 0 auto;
          padding: 2rem;
        }

        h2 {
          margin-bottom: 1.5rem;
          color: #1a1a1a;
        }

        .message {
          padding: 1rem;
          margin-bottom: 1.5rem;
          border-radius: 4px;
          font-weight: 500;
        }

        .message.success {
          background-color: #d4edda;
          color: #155724;
          border: 1px solid #c3e6cb;
        }

        .message.error {
          background-color: #f8d7da;
          color: #721c24;
          border: 1px solid #f5c6cb;
        }

        .form-group {
          margin-bottom: 1.5rem;
        }

        label {
          display: block;
          margin-bottom: 0.5rem;
          font-weight: 500;
          color: #333;
        }

        .required {
          color: #dc3545;
        }

        input,
        textarea {
          width: 100%;
          padding: 0.75rem;
          border: 1px solid #ced4da;
          border-radius: 4px;
          font-size: 1rem;
          font-family: inherit;
          transition: border-color 0.15s ease-in-out;
        }

        input:focus,
        textarea:focus {
          outline: none;
          border-color: #80bdff;
          box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }

        input.error,
        textarea.error {
          border-color: #dc3545;
        }

        input.error:focus,
        textarea.error:focus {
          box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25);
        }

        .error-message {
          display: block;
          margin-top: 0.5rem;
          color: #dc3545;
          font-size: 0.875rem;
        }

        .help-text {
          display: block;
          margin-top: 0.5rem;
          color: #6c757d;
          font-size: 0.875rem;
        }

        .form-actions {
          margin-top: 2rem;
        }

        .submit-button {
          padding: 0.75rem 2rem;
          background-color: #007bff;
          color: white;
          border: none;
          border-radius: 4px;
          font-size: 1rem;
          font-weight: 500;
          cursor: pointer;
          transition: background-color 0.15s ease-in-out;
        }

        .submit-button:hover:not(:disabled) {
          background-color: #0056b3;
        }

        .submit-button:disabled {
          background-color: #6c757d;
          cursor: not-allowed;
          opacity: 0.65;
        }

        .submit-button:focus {
          outline: none;
          box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.5);
        }
      `}</style>
    </div>
  );
}

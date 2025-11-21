import { useState, FormEvent } from 'react';

interface CommentFormProps {
  onSubmit: (author: string, content: string) => Promise<void>;
  isSubmitting: boolean;
  validationErrors: Record<string, string>;
}

export const CommentForm = ({ onSubmit, isSubmitting, validationErrors }: CommentFormProps) => {
  const [author, setAuthor] = useState('');
  const [content, setContent] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    await onSubmit(author, content);

    if (Object.keys(validationErrors).length === 0) {
      setAuthor('');
      setContent('');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="comment-form">
      <h3>Leave a Comment</h3>

      {validationErrors.general && (
        <div className="error-banner" role="alert">
          {validationErrors.general}
        </div>
      )}

      <div className="form-group">
        <label htmlFor="author">
          Name <span className="required">*</span>
        </label>
        <input
          type="text"
          id="author"
          value={author}
          onChange={(e) => setAuthor(e.target.value)}
          disabled={isSubmitting}
          className={validationErrors.author ? 'error' : ''}
          aria-invalid={!!validationErrors.author}
          aria-describedby={validationErrors.author ? 'author-error' : undefined}
        />
        {validationErrors.author && (
          <div id="author-error" className="error-message" role="alert">
            {validationErrors.author}
          </div>
        )}
      </div>

      <div className="form-group">
        <label htmlFor="content">
          Comment <span className="required">*</span>
        </label>
        <textarea
          id="content"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          disabled={isSubmitting}
          rows={4}
          className={validationErrors.content ? 'error' : ''}
          aria-invalid={!!validationErrors.content}
          aria-describedby={validationErrors.content ? 'content-error' : undefined}
        />
        {validationErrors.content && (
          <div id="content-error" className="error-message" role="alert">
            {validationErrors.content}
          </div>
        )}
        <div className="character-count">
          {content.length} / 500
        </div>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="submit-button"
      >
        {isSubmitting ? (
          <>
            <span className="spinner" />
            Posting...
          </>
        ) : (
          'Post Comment'
        )}
      </button>
    </form>
  );
};

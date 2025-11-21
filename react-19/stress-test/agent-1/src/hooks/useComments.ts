import { useState, useEffect, useCallback } from 'react';
import { Comment } from '../types';
import { fetchComments, submitComment } from '../api';

interface UseCommentsResult {
  comments: Comment[];
  isLoading: boolean;
  error: string | null;
  addComment: (author: string, content: string) => Promise<void>;
  isSubmitting: boolean;
  validationErrors: Record<string, string>;
}

export const useComments = (): UseCommentsResult => {
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    const loadComments = async () => {
      try {
        const fetchedComments = await fetchComments();
        setComments(fetchedComments);
      } catch (err) {
        setError('Failed to load comments');
      } finally {
        setIsLoading(false);
      }
    };

    loadComments();
  }, []);

  const addComment = useCallback(async (author: string, content: string) => {
    setIsSubmitting(true);
    setValidationErrors({});

    const optimisticComment: Comment = {
      id: `temp-${Date.now()}`,
      author,
      content,
      timestamp: Date.now(),
      isPending: true,
    };

    setComments(prev => [optimisticComment, ...prev]);

    try {
      const response = await submitComment(author, content);

      if (response.success && response.comment) {
        setComments(prev =>
          prev.map(c =>
            c.id === optimisticComment.id
              ? { ...response.comment!, isPending: false }
              : c
          )
        );
      } else if (response.errors) {
        setComments(prev => prev.filter(c => c.id !== optimisticComment.id));

        const errorMap: Record<string, string> = {};
        response.errors.forEach(err => {
          errorMap[err.field] = err.message;
        });
        setValidationErrors(errorMap);
      }
    } catch (err) {
      setComments(prev => prev.filter(c => c.id !== optimisticComment.id));
      setValidationErrors({
        general: 'An unexpected error occurred. Please try again.',
      });
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  return {
    comments,
    isLoading,
    error,
    addComment,
    isSubmitting,
    validationErrors,
  };
};

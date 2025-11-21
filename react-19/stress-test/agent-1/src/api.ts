import { Comment, SubmitCommentResponse, ValidationError } from './types';

const SIMULATED_DELAY = 1500;
const FAILURE_RATE = 0.2;

const validateComment = (author: string, content: string): ValidationError[] => {
  const errors: ValidationError[] = [];

  if (!author.trim()) {
    errors.push({ field: 'author', message: 'Name is required' });
  } else if (author.length < 2) {
    errors.push({ field: 'author', message: 'Name must be at least 2 characters' });
  } else if (author.length > 50) {
    errors.push({ field: 'author', message: 'Name must be less than 50 characters' });
  }

  if (!content.trim()) {
    errors.push({ field: 'content', message: 'Comment is required' });
  } else if (content.length < 10) {
    errors.push({ field: 'content', message: 'Comment must be at least 10 characters' });
  } else if (content.length > 500) {
    errors.push({ field: 'content', message: 'Comment must be less than 500 characters' });
  }

  if (content.toLowerCase().includes('spam')) {
    errors.push({ field: 'content', message: 'Comment contains prohibited content' });
  }

  return errors;
};

export const submitComment = async (
  author: string,
  content: string
): Promise<SubmitCommentResponse> => {
  await new Promise(resolve => setTimeout(resolve, SIMULATED_DELAY));

  const errors = validateComment(author, content);
  if (errors.length > 0) {
    return { success: false, errors };
  }

  if (Math.random() < FAILURE_RATE) {
    return {
      success: false,
      errors: [{ field: 'general', message: 'Network error. Please try again.' }],
    };
  }

  const comment: Comment = {
    id: `comment-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    author,
    content,
    timestamp: Date.now(),
  };

  return { success: true, comment };
};

export const fetchComments = async (): Promise<Comment[]> => {
  await new Promise(resolve => setTimeout(resolve, 800));

  return [
    {
      id: 'comment-1',
      author: 'Alice Johnson',
      content: 'Great article! Really helped me understand the concepts better.',
      timestamp: Date.now() - 3600000,
    },
    {
      id: 'comment-2',
      author: 'Bob Smith',
      content: 'Thanks for sharing this. I had been struggling with this exact problem for weeks.',
      timestamp: Date.now() - 7200000,
    },
    {
      id: 'comment-3',
      author: 'Carol Williams',
      content: 'Could you elaborate more on the implementation details? Would love to see a follow-up post.',
      timestamp: Date.now() - 10800000,
    },
  ];
};

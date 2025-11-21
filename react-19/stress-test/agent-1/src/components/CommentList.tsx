import { Comment } from '../types';

interface CommentListProps {
  comments: Comment[];
  isLoading: boolean;
  error: string | null;
}

const formatTimestamp = (timestamp: number): string => {
  const now = Date.now();
  const diff = now - timestamp;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
  if (hours < 24) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
  return `${days} day${days > 1 ? 's' : ''} ago`;
};

export const CommentList = ({ comments, isLoading, error }: CommentListProps) => {
  if (isLoading) {
    return (
      <div className="comment-list-loading">
        <div className="spinner-large" />
        <p>Loading comments...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="comment-list-error" role="alert">
        <p>{error}</p>
      </div>
    );
  }

  if (comments.length === 0) {
    return (
      <div className="comment-list-empty">
        <p>No comments yet. Be the first to comment!</p>
      </div>
    );
  }

  return (
    <div className="comment-list">
      <h3>{comments.length} Comment{comments.length !== 1 ? 's' : ''}</h3>
      {comments.map((comment) => (
        <article
          key={comment.id}
          className={`comment ${comment.isPending ? 'pending' : ''}`}
          aria-busy={comment.isPending}
        >
          <div className="comment-header">
            <strong className="comment-author">{comment.author}</strong>
            <time className="comment-time" dateTime={new Date(comment.timestamp).toISOString()}>
              {formatTimestamp(comment.timestamp)}
            </time>
            {comment.isPending && (
              <span className="pending-badge">Posting...</span>
            )}
          </div>
          <p className="comment-content">{comment.content}</p>
        </article>
      ))}
    </div>
  );
};

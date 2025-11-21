import { CommentForm } from './components/CommentForm';
import { CommentList } from './components/CommentList';
import { useComments } from './hooks/useComments';
import './styles.css';

export const App = () => {
  const { comments, isLoading, error, addComment, isSubmitting, validationErrors } = useComments();

  return (
    <div className="app">
      <header className="app-header">
        <h1>Blog Post Comments</h1>
        <p className="subtitle">Real-time comment system with optimistic updates</p>
      </header>

      <main className="app-main">
        <section className="comment-section">
          <CommentForm
            onSubmit={addComment}
            isSubmitting={isSubmitting}
            validationErrors={validationErrors}
          />
        </section>

        <section className="comment-section">
          <CommentList
            comments={comments}
            isLoading={isLoading}
            error={error}
          />
        </section>
      </main>

      <footer className="app-footer">
        <p>Comments are moderated and will appear after review</p>
      </footer>
    </div>
  );
};

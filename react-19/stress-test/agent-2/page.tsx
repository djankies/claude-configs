import { Suspense } from 'react';
import { ProfileEditor } from './ProfileEditor';
import { getUserProfile } from './actions';

interface PageProps {
  params: {
    userId: string;
  };
}

async function ProfileContent({ userId }: { userId: string }) {
  const profile = await getUserProfile(userId);

  if (!profile) {
    return (
      <div className="error-container">
        <h2>Profile Not Found</h2>
        <p>The requested user profile could not be found.</p>
      </div>
    );
  }

  return <ProfileEditor userId={userId} initialProfile={profile} />;
}

function LoadingFallback() {
  return (
    <div className="loading-container">
      <div className="spinner" aria-label="Loading profile" />
      <p>Loading profile...</p>

      <style jsx>{`
        .loading-container {
          max-width: 600px;
          margin: 0 auto;
          padding: 2rem;
          text-align: center;
        }

        .spinner {
          width: 50px;
          height: 50px;
          border: 4px solid #f3f3f3;
          border-top: 4px solid #007bff;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto 1rem;
        }

        @keyframes spin {
          0% {
            transform: rotate(0deg);
          }
          100% {
            transform: rotate(360deg);
          }
        }

        p {
          color: #6c757d;
        }
      `}</style>
    </div>
  );
}

export default function ProfilePage({ params }: PageProps) {
  const userId = params.userId || 'user-1';

  return (
    <main>
      <Suspense fallback={<LoadingFallback />}>
        <ProfileContent userId={userId} />
      </Suspense>

      <style jsx global>{`
        * {
          box-sizing: border-box;
        }

        body {
          margin: 0;
          padding: 0;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
            'Helvetica Neue', Arial, sans-serif;
          background-color: #f8f9fa;
        }

        main {
          min-height: 100vh;
          padding: 2rem 1rem;
        }

        .error-container {
          max-width: 600px;
          margin: 0 auto;
          padding: 2rem;
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          text-align: center;
        }

        .error-container h2 {
          color: #dc3545;
          margin-bottom: 1rem;
        }

        .error-container p {
          color: #6c757d;
        }
      `}</style>
    </main>
  );
}

'use client';

import { useEffect } from 'react';
import { useAuth } from '../context/AuthContext';

export function useAuthAction(state: any) {
  const { login } = useAuth();

  useEffect(() => {
    if (state?.success && state?.user) {
      login(state.user);
    }
  }, [state, login]);

  return state;
}

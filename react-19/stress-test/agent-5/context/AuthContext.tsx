'use client';

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface User {
  id: string;
  email: string;
  name: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  theme: 'light' | 'dark';
  isModalOpen: boolean;
  login: (user: User) => void;
  logout: () => void;
  toggleTheme: () => void;
  openModal: () => void;
  closeModal: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const AUTH_STORAGE_KEY = 'auth_user';
const THEME_STORAGE_KEY = 'app_theme';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    const storedUser = localStorage.getItem(AUTH_STORAGE_KEY);
    const storedTheme = localStorage.getItem(THEME_STORAGE_KEY);

    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch (error) {
        console.error('Failed to parse stored user:', error);
        localStorage.removeItem(AUTH_STORAGE_KEY);
      }
    }

    if (storedTheme === 'dark' || storedTheme === 'light') {
      setTheme(storedTheme);
    }

    setIsHydrated(true);
  }, []);

  useEffect(() => {
    if (!isHydrated) return;

    if (user) {
      localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(user));
    } else {
      localStorage.removeItem(AUTH_STORAGE_KEY);
    }
  }, [user, isHydrated]);

  useEffect(() => {
    if (!isHydrated) return;

    localStorage.setItem(THEME_STORAGE_KEY, theme);
    document.documentElement.classList.toggle('dark', theme === 'dark');
  }, [theme, isHydrated]);

  const login = (newUser: User) => {
    setUser(newUser);
    setIsModalOpen(false);
  };

  const logout = () => {
    setUser(null);
  };

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  const openModal = () => {
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        theme,
        isModalOpen,
        login,
        logout,
        toggleTheme,
        openModal,
        closeModal,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

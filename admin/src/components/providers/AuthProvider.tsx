'use client';

import { useState, useEffect, ReactNode } from 'react';
import { AuthContext } from '@/hooks/useAuth';
import { signIn as fbSignIn, signOut as fbSignOut, onAuthChange, getAdminProfile } from '@/lib/firebase/auth';
import type { Admin } from '@/types';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthChange(async (user) => {
      if (user) {
        const profile = await getAdminProfile(user.uid);
        setAdmin(profile);
      } else {
        setAdmin(null);
      }
      setLoading(false);
    });
    return unsub;
  }, []);

  async function signIn(email: string, password: string) {
    const profile = await fbSignIn(email, password);
    setAdmin(profile);
  }

  async function signOut() {
    await fbSignOut();
    setAdmin(null);
  }

  return (
    <AuthContext.Provider value={{ admin, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

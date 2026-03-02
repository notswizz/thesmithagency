'use client';

import { ReactNode } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { useFirestoreSubscriptions } from '@/hooks/useFirestore';
import { useCommandPalette } from '@/hooks/useCommandPalette';
import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { MobileNav } from '@/components/layout/MobileNav';
import { CommandPalette } from '@/components/ui/CommandPalette';
import { ChatPanel } from '@/components/chat/ChatPanel';
import { useStore } from '@/lib/store';

export function AppShell({ children }: { children: ReactNode }) {
  const { admin, loading } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const { chatOpen, setChatOpen } = useStore();

  useFirestoreSubscriptions();
  useCommandPalette();

  // Login page — no shell
  if (pathname === '/login') {
    return <>{children}</>;
  }

  // Loading
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-pink-dark border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Not authenticated
  if (!admin) {
    if (typeof window !== 'undefined') router.push('/login');
    return null;
  }

  return (
    <div className="min-h-screen bg-cream">
      <Sidebar />
      <div className="lg:ml-64">
        <Header />
        <main className="p-6 pb-24 lg:pb-6">{children}</main>
      </div>
      <MobileNav />
      <CommandPalette />
    </div>
  );
}

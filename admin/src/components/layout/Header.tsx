'use client';

import { useAuth } from '@/hooks/useAuth';
import { useStore } from '@/lib/store';

export function Header() {
  const { admin, signOut } = useAuth();
  const { setSidebarOpen } = useStore();

  return (
    <header className="sticky top-0 z-20 bg-cream/80 backdrop-blur-md border-b border-border-light h-14 flex items-center px-6 gap-4">
      {/* Mobile menu button */}
      <button
        onClick={() => setSidebarOpen(true)}
        className="lg:hidden p-2 -ml-2 text-navy-secondary hover:bg-cream-dark rounded-lg"
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      <div className="flex-1" />

      {/* Admin info */}
      {admin && (
        <div className="flex items-center gap-4">
          <span className="text-sm text-navy-secondary hidden sm:inline">{admin.name}</span>
          <div className="w-px h-4 bg-border-light hidden sm:block" />
          <button
            onClick={signOut}
            className="text-xs text-navy-secondary/50 hover:text-navy-secondary transition-colors uppercase tracking-wider"
          >
            Sign out
          </button>
        </div>
      )}
    </header>
  );
}

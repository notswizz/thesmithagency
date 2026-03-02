'use client';

import { useEffect } from 'react';
import { useStore } from '@/lib/store';

export function useCommandPalette() {
  const { commandPaletteOpen, setCommandPaletteOpen } = useStore();

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setCommandPaletteOpen(!commandPaletteOpen);
      }
      if (e.key === 'Escape' && commandPaletteOpen) {
        setCommandPaletteOpen(false);
      }
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [commandPaletteOpen, setCommandPaletteOpen]);

  return { open: commandPaletteOpen, setOpen: setCommandPaletteOpen };
}

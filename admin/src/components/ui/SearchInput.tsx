'use client';

import { useState, useRef, useEffect, useMemo } from 'react';

export interface SearchSuggestion {
  label: string;
  sublabel?: string;
  href?: string;
  icon?: string;
}

interface SearchInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  suggestions?: SearchSuggestion[];
  onSelect?: (suggestion: SearchSuggestion) => void;
}

export function SearchInput({ value, onChange, placeholder = 'Search...', suggestions = [], onSelect }: SearchInputProps) {
  const [focused, setFocused] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const showDropdown = focused && value.trim().length > 0 && suggestions.length > 0;

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setFocused(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  // Reset selection when suggestions change
  useEffect(() => {
    setSelectedIndex(-1);
  }, [suggestions]);

  function handleKeyDown(e: React.KeyboardEvent) {
    if (!showDropdown) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((i) => Math.min(i + 1, suggestions.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((i) => Math.max(-1, i - 1));
    } else if (e.key === 'Enter' && selectedIndex >= 0 && suggestions[selectedIndex]) {
      e.preventDefault();
      handleSelect(suggestions[selectedIndex]);
    } else if (e.key === 'Escape') {
      setFocused(false);
    }
  }

  function handleSelect(suggestion: SearchSuggestion) {
    onChange(suggestion.label);
    setFocused(false);
    onSelect?.(suggestion);
  }

  return (
    <div ref={wrapperRef} className="relative">
      <div className="relative">
        <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-navy-secondary/30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          ref={inputRef}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={() => setFocused(true)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          className="w-full rounded-lg ring-1 ring-border-light bg-white pl-9 pr-8 py-2.5 text-sm text-navy-heading
            placeholder:text-navy-secondary/30 focus:outline-none focus:ring-2 focus:ring-pink-dark/40
            transition-shadow duration-150"
        />
        {value && (
          <button
            onClick={() => { onChange(''); inputRef.current?.focus(); }}
            className="absolute right-2.5 top-1/2 -translate-y-1/2 p-0.5 text-navy-secondary/30 hover:text-navy-secondary transition-colors"
          >
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* Dropdown */}
      {showDropdown && (
        <div className="absolute z-20 top-full mt-1 w-full bg-white rounded-xl ring-1 ring-border-light shadow-lg overflow-hidden animate-[slideUp_150ms_ease-out]">
          <ul className="max-h-64 overflow-y-auto py-1">
            {suggestions.map((s, i) => (
              <li
                key={`${s.label}-${i}`}
                onMouseDown={(e) => { e.preventDefault(); handleSelect(s); }}
                onMouseEnter={() => setSelectedIndex(i)}
                className={`flex items-center gap-2.5 px-3 py-2 cursor-pointer text-sm transition-colors ${
                  i === selectedIndex ? 'bg-cream-dark' : ''
                }`}
              >
                {s.icon && <span className="text-base flex-shrink-0">{s.icon}</span>}
                <div className="min-w-0">
                  <div className="font-medium text-navy truncate">{s.label}</div>
                  {s.sublabel && <div className="text-xs text-navy-secondary/40 truncate">{s.sublabel}</div>}
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

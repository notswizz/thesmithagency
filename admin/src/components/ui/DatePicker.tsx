'use client';

import { useState, useMemo } from 'react';
import { getMonthDays, getMonthName, getDayName, toDateString } from '@/lib/utils/dates';

interface DatePickerProps {
  selected?: string[];
  onSelect: (dates: string[]) => void;
  minDate?: string;
  maxDate?: string;
  mode?: 'single' | 'multiple' | 'range';
}

export function DatePicker({ selected = [], onSelect, minDate, maxDate, mode = 'single' }: DatePickerProps) {
  const today = new Date();
  const [viewYear, setViewYear] = useState(today.getFullYear());
  const [viewMonth, setViewMonth] = useState(today.getMonth());

  const days = useMemo(() => getMonthDays(viewYear, viewMonth), [viewYear, viewMonth]);
  const startDow = days[0].getDay();

  function prev() {
    if (viewMonth === 0) { setViewMonth(11); setViewYear((y) => y - 1); }
    else setViewMonth((m) => m - 1);
  }

  function next() {
    if (viewMonth === 11) { setViewMonth(0); setViewYear((y) => y + 1); }
    else setViewMonth((m) => m + 1);
  }

  function handleClick(dateStr: string) {
    if (mode === 'single') {
      onSelect([dateStr]);
    } else if (mode === 'multiple') {
      onSelect(
        selected.includes(dateStr)
          ? selected.filter((d) => d !== dateStr)
          : [...selected, dateStr].sort()
      );
    } else if (mode === 'range') {
      if (selected.length === 0 || selected.length === 2) {
        onSelect([dateStr]);
      } else {
        const [start] = selected;
        const sorted = [start, dateStr].sort();
        // Generate all dates in range
        const range: string[] = [];
        const cur = new Date(Number(sorted[0].split('-')[0]), Number(sorted[0].split('-')[1]) - 1, Number(sorted[0].split('-')[2]));
        const end = new Date(Number(sorted[1].split('-')[0]), Number(sorted[1].split('-')[1]) - 1, Number(sorted[1].split('-')[2]));
        while (cur <= end) {
          range.push(toDateString(cur));
          cur.setDate(cur.getDate() + 1);
        }
        onSelect(range);
      }
    }
  }

  function isDisabled(dateStr: string) {
    if (minDate && dateStr < minDate) return true;
    if (maxDate && dateStr > maxDate) return true;
    return false;
  }

  return (
    <div className="w-full max-w-sm">
      <div className="flex items-center justify-between mb-4">
        <button onClick={prev} className="p-1 hover:bg-cream-dark rounded-lg text-navy-secondary">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
        </button>
        <span className="text-sm font-semibold text-navy-heading">
          {getMonthName(viewMonth)} {viewYear}
        </span>
        <button onClick={next} className="p-1 hover:bg-cream-dark rounded-lg text-navy-secondary">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
        </button>
      </div>
      <div className="grid grid-cols-7 gap-1">
        {[0, 1, 2, 3, 4, 5, 6].map((d) => (
          <div key={d} className="text-center text-xs text-navy-secondary/40 font-medium py-1">
            {getDayName(d)}
          </div>
        ))}
        {Array.from({ length: startDow }).map((_, i) => (
          <div key={`pad-${i}`} />
        ))}
        {days.map((day) => {
          const dateStr = toDateString(day);
          const isSelected = selected.includes(dateStr);
          const disabled = isDisabled(dateStr);
          const isToday = toDateString(today) === dateStr;
          return (
            <button
              key={dateStr}
              disabled={disabled}
              onClick={() => handleClick(dateStr)}
              className={`h-9 w-full rounded-lg text-sm transition-colors
                ${disabled ? 'text-navy-secondary/20 cursor-not-allowed' : 'hover:bg-cream-dark cursor-pointer'}
                ${isSelected ? 'bg-navy-heading text-white hover:bg-navy-heading/90' : ''}
                ${isToday && !isSelected ? 'ring-1 ring-pink-dark' : ''}
              `}
            >
              {day.getDate()}
            </button>
          );
        })}
      </div>
    </div>
  );
}

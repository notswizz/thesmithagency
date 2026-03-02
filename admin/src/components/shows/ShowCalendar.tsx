'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { getMonthDays, getMonthName, getDayName, toDateString, isInRange } from '@/lib/utils/dates';
import type { Show } from '@/types';

const statusColors: Record<string, string> = {
  active: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  inactive: 'bg-slate-100 text-slate-500 border-slate-200',
};

export function ShowCalendar({ shows }: { shows: Show[] }) {
  const today = new Date();
  const [year, setYear] = useState(today.getFullYear());
  const [month, setMonth] = useState(today.getMonth());

  const days = useMemo(() => getMonthDays(year, month), [year, month]);
  const startDow = days[0].getDay();
  const todayStr = toDateString(today);

  function prev() {
    if (month === 0) { setMonth(11); setYear((y) => y - 1); }
    else setMonth((m) => m - 1);
  }

  function next() {
    if (month === 11) { setMonth(0); setYear((y) => y + 1); }
    else setMonth((m) => m + 1);
  }

  function showsOnDate(dateStr: string) {
    return shows.filter((s) => isInRange(dateStr, s.startDate, s.endDate));
  }

  return (
    <div className="bg-white rounded-2xl ring-1 ring-border-light shadow-[0_1px_3px_rgba(0,0,0,0.04)] overflow-hidden">
      <div className="flex items-center justify-between px-6 py-4 border-b border-border-light">
        <button onClick={prev} className="p-2 hover:bg-cream-dark rounded-lg text-navy-secondary">←</button>
        <span className="text-lg font-semibold text-navy-heading">{getMonthName(month)} {year}</span>
        <button onClick={next} className="p-2 hover:bg-cream-dark rounded-lg text-navy-secondary">→</button>
      </div>
      <div className="grid grid-cols-7">
        {[0, 1, 2, 3, 4, 5, 6].map((d) => (
          <div key={d} className="py-2 text-center text-xs font-medium text-navy-secondary/40 border-b border-border-light">
            {getDayName(d)}
          </div>
        ))}
        {Array.from({ length: startDow }).map((_, i) => (
          <div key={`pad-${i}`} className="min-h-[100px] border-b border-r border-slate-50" />
        ))}
        {days.map((day) => {
          const dateStr = toDateString(day);
          const dayShows = showsOnDate(dateStr);
          const isToday = dateStr === todayStr;
          return (
            <div
              key={dateStr}
              className={`min-h-[100px] border-b border-r border-slate-50 p-1 ${isToday ? 'bg-pink-light/5' : ''}`}
            >
              <div className={`text-xs mb-1 px-1 ${isToday ? 'text-pink-dark font-bold' : 'text-slate-400'}`}>
                {day.getDate()}
              </div>
              <div className="space-y-0.5">
                {dayShows.slice(0, 3).map((show) => (
                  <Link
                    key={show.id}
                    href={`/shows/${show.id}`}
                    className={`block text-[10px] px-1.5 py-0.5 rounded border truncate ${statusColors[show.status] || statusColors.active}`}
                  >
                    {show.name}
                  </Link>
                ))}
                {dayShows.length > 3 && (
                  <div className="text-[10px] text-slate-400 px-1">+{dayShows.length - 3} more</div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

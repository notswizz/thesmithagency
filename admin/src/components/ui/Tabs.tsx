'use client';

interface Tab {
  key: string;
  label: string;
  count?: number;
}

interface TabsProps {
  tabs: Tab[];
  active: string;
  onChange: (key: string) => void;
}

export function Tabs({ tabs, active, onChange }: TabsProps) {
  return (
    <div className="border-b border-border-light">
      <nav className="flex gap-6 -mb-px">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => onChange(tab.key)}
            className={`py-3 text-sm font-medium border-b-2 transition-colors ${
              active === tab.key
                ? 'border-navy-heading text-navy-heading'
                : 'border-transparent text-navy-secondary/50 hover:text-navy-secondary hover:border-border-light'
            }`}
          >
            {tab.label}
            {tab.count !== undefined && (
              <span className="ml-2 text-xs bg-cream-dark text-navy-secondary px-2 py-0.5 rounded-full">
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </nav>
    </div>
  );
}

import type { BookingStatus, PaymentStatus, ShowStatus } from '@/types';

type BadgeVariant = 'amber' | 'emerald' | 'red' | 'blue' | 'slate' | 'pink';

const variantStyles: Record<BadgeVariant, string> = {
  amber: 'bg-amber-50 text-amber-700 ring-amber-200',
  emerald: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  red: 'bg-red-50 text-red-700 ring-red-200',
  blue: 'bg-blue-50 text-blue-700 ring-blue-200',
  slate: 'bg-slate-50 text-slate-600 ring-slate-200',
  pink: 'bg-pink-50 text-pink-700 ring-pink-200',
};

const statusVariant: Record<BookingStatus | PaymentStatus | ShowStatus, BadgeVariant> = {
  pending: 'amber',
  booked: 'blue',
  completed: 'emerald',
  cancelled: 'red',
  unpaid: 'red',
  deposit_paid: 'amber',
  paid: 'emerald',
  active: 'emerald',
  inactive: 'slate',
};

interface BadgeProps {
  variant?: BadgeVariant;
  status?: BookingStatus | PaymentStatus | ShowStatus;
  children: React.ReactNode;
  className?: string;
}

export function Badge({ variant, status, children, className = '' }: BadgeProps) {
  const v = variant || (status ? statusVariant[status] : 'slate');
  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ring-1 ${variantStyles[v]} ${className}`}
    >
      {children}
    </span>
  );
}

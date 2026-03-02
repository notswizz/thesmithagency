interface AvatarProps {
  src?: string;
  name: string;
  size?: 'sm' | 'md' | 'lg';
  status?: 'online' | 'approved' | 'pending';
}

const sizeClasses = { sm: 'w-8 h-8 text-xs', md: 'w-10 h-10 text-sm', lg: 'w-16 h-16 text-lg' };
const statusColors = { online: 'bg-emerald-400', approved: 'bg-emerald-400', pending: 'bg-amber-400' };

function initials(name: string): string {
  return name
    .split(' ')
    .map((w) => w[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

export function Avatar({ src, name, size = 'md', status }: AvatarProps) {
  return (
    <div className="relative inline-flex">
      {src ? (
        <img
          src={src}
          alt={name}
          className={`${sizeClasses[size]} rounded-full object-cover ring-2 ring-white`}
          referrerPolicy="no-referrer"
        />
      ) : (
        <div
          className={`${sizeClasses[size]} rounded-full bg-cream-dark text-navy-heading font-semibold
            flex items-center justify-center ring-2 ring-white`}
        >
          {initials(name)}
        </div>
      )}
      {status && (
        <span
          className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full ring-2 ring-white ${statusColors[status]}`}
        />
      )}
    </div>
  );
}

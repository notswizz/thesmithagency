/** Case-insensitive substring + fuzzy character matching. Null-safe. */
export function fuzzyMatch(query: string, text: string | null | undefined): boolean {
  if (!text || !query) return false;
  const q = query.toLowerCase();
  const t = text.toLowerCase();
  if (t.includes(q)) return true;
  // Check if all chars appear in order
  let qi = 0;
  for (let ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t[ti] === q[qi]) qi++;
  }
  return qi === q.length;
}

export function searchEntities<T>(
  items: T[],
  query: string,
  fields: readonly (keyof T)[]
): T[] {
  if (!query.trim()) return items;
  const q = query.toLowerCase().trim();
  // Score items: exact substring match scores higher than fuzzy
  const scored = items
    .map((item) => {
      let bestScore = 0;
      for (const field of fields) {
        const val = item[field as keyof T];
        if (typeof val !== 'string' || !val) continue;
        const t = val.toLowerCase();
        if (t === q) { bestScore = Math.max(bestScore, 3); }
        else if (t.startsWith(q)) { bestScore = Math.max(bestScore, 2); }
        else if (t.includes(q)) { bestScore = Math.max(bestScore, 1); }
        else if (fuzzyMatch(q, val)) { bestScore = Math.max(bestScore, 0.5); }
      }
      return { item, score: bestScore };
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score);
  return scored.map((s) => s.item);
}

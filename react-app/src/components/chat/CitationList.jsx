import { useState } from 'react';
import { FileText, ChevronDown, ChevronUp } from 'lucide-react';
import { extractSourceName, truncate } from '../../utils/formatters.js';
import '../../styles/chat/CitationList.css';

export default function CitationList({ citations }) {
  const [isExpanded, setIsExpanded] = useState(false);

  if (!citations || citations.length === 0) return null;

  // Dé-duplication par source URI
  const unique = citations.reduce((acc, cite) => {
    const key = cite.source ?? cite.uri ?? JSON.stringify(cite);
    if (!acc.seen.has(key)) {
      acc.seen.add(key);
      acc.list.push(cite);
    }
    return acc;
  }, { seen: new Set(), list: [] }).list;

  const label = unique.length === 1
    ? '1 document consulté'
    : `${unique.length} documents consultés`;


  return (
    <div className="citation-list" id="citation-list">
      <button
        className="citation-toggle"
        onClick={() => setIsExpanded((prev) => !prev)}
        aria-expanded={isExpanded}
        aria-controls="citation-items"
        title={isExpanded ? 'Masquer les sources' : 'Afficher les sources'}
      >
        <FileText size={13} />
        <span>{label}</span>
        {isExpanded ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
      </button>

      {isExpanded && (
        <div className="citation-items" id="citation-items" role="list">
          {unique.map((cite, idx) => {
            const sourceName = extractSourceName(cite.source ?? cite.uri ?? '');
            const excerpt = cite.excerpt ?? cite.content ?? null;

            return (
              <div
                key={idx}
                className="citation-item"
                role="listitem"
                id={`citation-item-${idx}`}
              >
                <div className="citation-number" aria-label={`Source ${idx + 1}`}>
                  {idx + 1}
                </div>
                <div className="citation-body">
                  <div className="citation-source">
                    <FileText size={12} />
                    <span title={cite.source ?? cite.uri}>{sourceName}</span>
                  </div>
                  {excerpt && (
                    <blockquote className="citation-excerpt">
                      {truncate(excerpt, 220)}
                    </blockquote>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

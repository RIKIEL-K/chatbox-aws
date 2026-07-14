import { useState } from 'react';
import { FileText, ChevronDown, ChevronUp } from 'lucide-react';
import { extractSourceName, truncate } from '../../utils/formatters.js';
import '../../styles/chat/CitationList.css';

export default function CitationList({ citations }) {
  const [isExpanded, setIsExpanded] = useState(false);

  if (!citations || citations.length === 0) return null;

  return (
    <div className="citation-list" id="citation-list">
      <button
        className="citation-toggle"
        onClick={() => setIsExpanded(!isExpanded)}
        aria-expanded={isExpanded}
      >
        <FileText size={14} />
        <span>Sources consultées ({citations.length})</span>
        {isExpanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
      </button>

      {isExpanded && (
        <div className="citation-items">
          {citations.map((cite, idx) => (
            <div key={idx} className="citation-item">
              <div className="citation-number">{idx + 1}</div>
              <div className="citation-body">
                <div className="citation-source">
                  <FileText size={12} />
                  <span>{extractSourceName(cite.source)}</span>
                </div>
                {cite.excerpt && (
                  <blockquote className="citation-excerpt">
                    {truncate(cite.excerpt, 200)}
                  </blockquote>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

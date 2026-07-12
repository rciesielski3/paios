# QA News Adapter (M4)

## Purpose
Extract quality assurance industry news and insights from multiple sources.

## Data Sources (Phase 1)
- Dev.to #qa tag (free API, no auth)
- Medium #qa publications (RSS scrape)
- QA testing blogs (RSS/HTML scrape)

## Processing
1. Load `system/config/qa-news-filter.yaml`
2. Fetch articles from sources
3. Filter by keywords + priority
4. Normalize to M3 format
5. Output to merge node

## Output Format (M3 Contract)
```json
{
  "source": "qa_news",
  "source_id": "qa_news_{{ source_name }}_{{ url_hash }}",
  "title": "{{ article_title }}",
  "url": "{{ article_url }}",
  "content": "{{ excerpt }}",
  "priority": "high|medium|low",
  "tags": ["qa", "{{ extracted_topics }}"]
}
```

## Implementation Notes
- Start with Dev.to free API (simplest, no auth)
- RSS feeds for blogs (add in Phase 2)
- No comment/discussion scraping in M4 (keep scope minimal)
- Reuse existing HTTP request patterns from GitHub adapters

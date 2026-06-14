# RSS / Atom / JSON Feed - FIM Solution Documentation

## Description
RSS 2.0, [Atom](https://datatracker.ietf.org/doc/html/rfc4287), and [JSON Feed](https://www.jsonfeed.org) are syndication formats that expose a list of content items (title, link, summary, timestamp, author) for feed readers, podcast apps, email-digest tools, and cross-posting automations. They are the backbone of content syndication and the discovery stage of a content funnel.

## Basic Syntax
```xml
<!-- RSS 2.0 -->
<rss version="2.0"><channel>
  <title>Noizu Engineering</title>
  <link>https://example.com</link>
  <description>Systems and platform notes</description>
  <item>
    <title>Rate Limiting 101</title>
    <link>https://example.com/rate-limiting</link>
    <guid>https://example.com/rate-limiting</guid>
    <pubDate>Sun, 14 Jun 2026 09:00:00 GMT</pubDate>
    <description><![CDATA[Token, leaky, and sliding-window limiters.]]></description>
  </item>
</channel></rss>
```
```json
{ "version": "https://jsonfeed.org/version/1.1",
  "title": "Noizu Engineering",
  "home_page_url": "https://example.com",
  "feed_url": "https://example.com/feed.json",
  "items": [{ "id": "https://example.com/rate-limiting",
    "url": "https://example.com/rate-limiting",
    "title": "Rate Limiting 101",
    "content_html": "<p>Token, leaky, and sliding-window limiters.</p>",
    "date_published": "2026-06-14T09:00:00Z" }] }
```

## Toolchain
- **feedgen** (Python) - Generate RSS/Atom/podcast feeds
- **feed** (Node) - Emit RSS, Atom, and JSON Feed from one model
- **SSG built-ins** - Hugo/Jekyll/Astro auto-generate feeds
- **feedparser** (Python) - Read/normalize feeds for repurposing
- **podcast extensions** - iTunes/`podcast:` namespace tags for audio

## Strengths
- Universal, reader-agnostic content syndication
- Powers podcast distribution (RSS + iTunes namespace)
- Enables cross-posting and email-digest automations
- Simple, cacheable, static-file friendly
- JSON Feed is trivial to produce/consume in JS pipelines

## Limitations
- Multiple competing formats (RSS vs Atom vs JSON Feed)
- Strict date/XML formatting; invalid feeds break readers
- Full-content vs summary feed is a strategic trade-off
- No built-in analytics on consumption

## Best Use Cases
- Blog/newsletter syndication to feed readers
- Podcast distribution to Apple/Spotify via RSS
- Automated cross-posting and content-digest pipelines
- Discovery-stage funnel distribution from an owned site

## NPL-FIM Integration
```npl
⌜feed-emit|rss|FIM@1.0⌝
format: rss2 | atom | json-feed
builder: feedgen | feed | ssg-builtin
items: [title, link, guid, pubDate, content]
extensions: [podcast-itunes]
⌞feed-emit⌟
```

NPL agents emit RSS/Atom/JSON Feed to syndicate published content and to power podcast and cross-posting automations.

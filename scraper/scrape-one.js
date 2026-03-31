#!/usr/bin/env node
/**
 * HelloInterview System Design Scraper
 * 
 * Scrapes one page per run from hellointerview.com and saves as markdown.
 * Designed to be called by OpenClaw cron job.
 * 
 * Usage: node scrape-one.js
 * 
 * Reads scrape-status.json for state, fetches next unscraped page,
 * saves to content/ dir, updates status.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const SCRAPER_DIR = path.dirname(__filename);
const STATUS_FILE = path.join(SCRAPER_DIR, 'scrape-status.json');
const CONTENT_DIR = path.join(SCRAPER_DIR, 'content');

function readStatus() {
  return JSON.parse(fs.readFileSync(STATUS_FILE, 'utf-8'));
}

function writeStatus(status) {
  status.last_updated = new Date().toISOString();
  fs.writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2) + '\n');
}

function urlToFilename(url) {
  // /learn/system-design/core-concepts/caching -> core-concepts/caching.md
  const parts = url.replace('https://www.hellointerview.com/learn/system-design/', '');
  return parts.replace(/\//g, '_') + '.md';
}

function urlToCategory(url) {
  const path = url.replace('https://www.hellointerview.com/learn/system-design/', '');
  const parts = path.split('/');
  return parts[0]; // in-a-hurry, core-concepts, problem-breakdowns, deep-dives
}

function fetchPage(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { 
      headers: { 
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    });
    req.on('error', reject);
    req.setTimeout(30000, () => { req.destroy(); reject(new Error('Timeout')); });
  });
}

function extractContent(html) {
  let content = html;
  
  // Remove script, style, svg, noscript
  content = content.replace(/<script[\s\S]*?<\/script>/gi, '');
  content = content.replace(/<style[\s\S]*?<\/style>/gi, '');
  content = content.replace(/<svg[\s\S]*?<\/svg>/gi, '');
  content = content.replace(/<noscript[\s\S]*?<\/noscript>/gi, '');
  content = content.replace(/<nav[\s\S]*?<\/nav>/gi, '');
  content = content.replace(/<footer[\s\S]*?<\/footer>/gi, '');
  content = content.replace(/<header[\s\S]*?<\/header>/gi, '');
  
  // Extract title from og:title or h1
  const ogTitle = content.match(/<meta[^>]*property="og:title"[^>]*content="([^"]*)"[^>]*>/i);
  const titleMatch = content.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i);
  const title = ogTitle ? ogTitle[1].trim() : 
                titleMatch ? titleMatch[1].replace(/<[^>]+>/g, '').trim() : 'Untitled';
  
  // Try to extract article content - hellointerview wraps content in article or specific divs
  const articleMatch = content.match(/<article[^>]*>([\s\S]*?)<\/article>/i) ||
                       content.match(/<div[^>]*class="[^"]*prose[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/i) ||
                       content.match(/<main[^>]*>([\s\S]*?)<\/main>/i);
  
  if (articleMatch) {
    content = articleMatch[1];
  }
  
  // Remove promo banners, sign-in links, sidebar navigation (HTML level)
  content = content.replace(/<a[^>]*\/premium[^>]*>[\s\S]*?<\/a>/gi, '');
  content = content.replace(/<a[^>]*\/pricing[^>]*>[\s\S]*?<\/a>/gi, '');
  content = content.replace(/<a[^>]*\/become-an-expert[^>]*>[\s\S]*?<\/a>/gi, '');
  content = content.replace(/<a[^>]*\/login[^>]*>[\s\S]*?<\/a>/gi, '');
  content = content.replace(/<button[\s\S]*?<\/button>/gi, '');
  // Remove empty links (social icons etc)
  content = content.replace(/<a[^>]*href="https:\/\/(www\.)?(youtube|linkedin|twitter|discord|substack)[^"]*"[^>]*>\s*<\/a>/gi, '');
  content = content.replace(/<a[^>]*printful[^>]*>[\s\S]*?<\/a>/gi, '');
  
  // Convert HTML to rough markdown
  // Headers
  content = content.replace(/<h1[^>]*>([\s\S]*?)<\/h1>/gi, '\n# $1\n');
  content = content.replace(/<h2[^>]*>([\s\S]*?)<\/h2>/gi, '\n## $1\n');
  content = content.replace(/<h3[^>]*>([\s\S]*?)<\/h3>/gi, '\n### $1\n');
  content = content.replace(/<h4[^>]*>([\s\S]*?)<\/h4>/gi, '\n#### $1\n');
  content = content.replace(/<h5[^>]*>([\s\S]*?)<\/h5>/gi, '\n##### $1\n');
  
  // Bold & italic
  content = content.replace(/<strong[^>]*>([\s\S]*?)<\/strong>/gi, '**$1**');
  content = content.replace(/<b[^>]*>([\s\S]*?)<\/b>/gi, '**$1**');
  content = content.replace(/<em[^>]*>([\s\S]*?)<\/em>/gi, '*$1*');
  content = content.replace(/<i[^>]*>([\s\S]*?)<\/i>/gi, '*$1*');
  
  // Code
  content = content.replace(/<code[^>]*>([\s\S]*?)<\/code>/gi, '`$1`');
  content = content.replace(/<pre[^>]*>([\s\S]*?)<\/pre>/gi, '\n```\n$1\n```\n');
  
  // Links
  content = content.replace(/<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, '[$2]($1)');
  
  // Lists
  content = content.replace(/<li[^>]*>([\s\S]*?)<\/li>/gi, '- $1\n');
  content = content.replace(/<\/?[ou]l[^>]*>/gi, '\n');
  
  // Paragraphs & breaks
  content = content.replace(/<p[^>]*>([\s\S]*?)<\/p>/gi, '\n$1\n');
  content = content.replace(/<br\s*\/?>/gi, '\n');
  content = content.replace(/<\/?div[^>]*>/gi, '\n');
  
  // Images
  content = content.replace(/<img[^>]*alt="([^"]*)"[^>]*src="([^"]*)"[^>]*>/gi, '![Alt: $1]($2)');
  content = content.replace(/<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*>/gi, '![Alt: $2]($1)');
  content = content.replace(/<img[^>]*src="([^"]*)"[^>]*>/gi, '![]($1)');
  
  // Remove remaining HTML tags
  content = content.replace(/<[^>]+>/g, '');
  
  // Decode HTML entities
  content = content.replace(/&amp;/g, '&');
  content = content.replace(/&lt;/g, '<');
  content = content.replace(/&gt;/g, '>');
  content = content.replace(/&quot;/g, '"');
  content = content.replace(/&#39;/g, "'");
  content = content.replace(/&#x27;/g, "'");
  content = content.replace(/&nbsp;/g, ' ');
  
  // Post-markdown cleanup - remove leftover nav/promo
  content = content.replace(/\[?\s*Limited Time Offer[\s\S]*?🎉\s*\]?\s*\([^)]*\)/gi, '');
  content = content.replace(/\[Pricing\]\([^)]*\)/gi, '');
  content = content.replace(/\[Become a Coach\]\([^)]*\)/gi, '');
  content = content.replace(/\[Sign in \/ Sign up\]\([^)]*\)/gi, '');
  content = content.replace(/\[Get Premium\]\([^)]*\)/gi, '');
  content = content.replace(/Get Premium/gi, '');
  content = content.replace(/Search\s*⌘K/gi, '');
  content = content.replace(/\[\]\(https:\/\/(www\.)?(youtube|linkedin|twitter|discord|substack|hello-interview-swag)[^)]*\)/gi, '');
  
  // Clean title from og:title
  let cleanTitle = title.replace(/\s*\|\s*Hello Interview.*$/i, '').trim();
  
  // Clean up whitespace
  content = content.replace(/\n{3,}/g, '\n\n');
  content = content.trim();
  
  return { title: cleanTitle, content };
}

async function main() {
  const status = readStatus();
  
  if (status.status === 'complete' || status.status === 'paused') {
    console.log(JSON.stringify({ action: 'skip', reason: status.status }));
    process.exit(0);
  }
  
  // Find next page to scrape
  const nextUrl = status.pages.find(url => 
    !status.completed.includes(url) && !status.failed.includes(url)
  );
  
  if (!nextUrl) {
    status.status = 'complete';
    writeStatus(status);
    console.log(JSON.stringify({ action: 'complete', total: status.completed.length }));
    process.exit(0);
  }
  
  const category = urlToCategory(nextUrl);
  const filename = urlToFilename(nextUrl);
  const categoryDir = path.join(CONTENT_DIR, category);
  
  // Ensure directory exists
  fs.mkdirSync(categoryDir, { recursive: true });
  
  const outFile = path.join(CONTENT_DIR, filename);
  
  // Check if already scraped
  if (fs.existsSync(outFile)) {
    status.completed.push(nextUrl);
    status.current_index = status.completed.length;
    writeStatus(status);
    console.log(JSON.stringify({ 
      action: 'already_exists', 
      url: nextUrl, 
      progress: `${status.completed.length}/${status.total_pages}` 
    }));
    process.exit(0);
  }
  
  try {
    console.error(`Fetching: ${nextUrl}`);
    const { status: httpStatus, data } = await fetchPage(nextUrl);
    
    if (httpStatus !== 200) {
      throw new Error(`HTTP ${httpStatus}`);
    }
    
    const { title, content } = extractContent(data);
    
    // Build markdown file
    const markdown = `---
source: ${nextUrl}
title: "${title}"
category: ${category}
scraped_at: ${new Date().toISOString()}
---

# ${title}

${content}
`;
    
    fs.writeFileSync(outFile, markdown);
    
    status.completed.push(nextUrl);
    status.current_index = status.completed.length;
    writeStatus(status);
    
    console.log(JSON.stringify({ 
      action: 'scraped', 
      url: nextUrl, 
      title,
      file: outFile,
      progress: `${status.completed.length}/${status.total_pages}`,
      content_length: content.length
    }));
    
  } catch (err) {
    status.failed.push(nextUrl);
    writeStatus(status);
    console.log(JSON.stringify({ 
      action: 'failed', 
      url: nextUrl, 
      error: err.message,
      progress: `${status.completed.length}/${status.total_pages}` 
    }));
    process.exit(1);
  }
}

main();

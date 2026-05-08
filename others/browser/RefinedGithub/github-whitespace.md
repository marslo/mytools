# GitHub Whitespace Visibility Control

## Overview

This document describes how to control Refined GitHub's `show-whitespace` feature
so that whitespace markers (space dots `·` and tab arrows `→`) are only visible
on specific pages, and how trailing whitespace is highlighted via Tampermonkey.

### How It Works

Refined GitHub's `show-whitespace` injects `<span data-rgh-whitespace="space|tab">` 
elements into code lines. The dots/arrows are rendered via **`background-image`** 
(an inline SVG), not `::before` pseudo-elements.

Two layers work together:

| Layer         | Role                        | Tool              |
|---------------|-----------------------------|-------------------|
| **CSS**       | Controls which pages show whitespace dots | Refined GitHub Custom CSS |
| **Tampermonkey JS** | Highlights trailing whitespace with red background | Tampermonkey userscript |

CSS is the gate — if it hides the `background-image`, the JS highlight is also
invisible. JS only enhances what CSS allows.

---

## Current State

### CSS (Refined GitHub Custom CSS)

```css
/* ── Whitespace markers: hide ONLY space dots on non-PR pages ── */
body:not(:has(#diff-comparison-viewer-container)) [data-rgh-whitespace="space"] {
  background-image: none !important;
}
```

**Effect:**
- PR Conversation + Files Changed → space dots visible (page has `#diff-comparison-viewer-container`)
- File browsing (`/blob/...`), README, etc. → space dots hidden
- Tab arrows (`→`) → always visible everywhere (only `="space"` is targeted)

### Tampermonkey Userscript

Script: **GitHub PR trailing whitespace highlighter** (v1.2)

- Runs on `https://github.com/*/pull/*`
- Finds all `[data-rgh-whitespace="space"]` spans
- Walks backwards from the end of each line's child nodes
- If the last child nodes are whitespace spans → marks them with red background
- Uses `MutationObserver` to catch dynamically loaded content

---

## Expansion Guide

### Approach 1: Blacklist (Current — hide on specific pages)

Keep whitespace visible by default, hide on specific pages. Best when you want
whitespace on most pages and only need to suppress a few.

**Pattern:**

```css
<scope-selector> [data-rgh-whitespace="space"] {
  background-image: none !important;
}
```

**Examples:**

```css
/* Hide on file browsing pages only (current approach, broadened) */
body:not(:has(#diff-comparison-viewer-container)) [data-rgh-whitespace="space"] {
  background-image: none !important;
}

/* Hide only on README renderings */
.markdown-body [data-rgh-whitespace="space"] {
  background-image: none !important;
}

/* Hide on blob (single file view) pages */
[class*="react-code-file-contents"] [data-rgh-whitespace="space"] {
  background-image: none !important;
}

/* Hide on wiki pages */
.wiki-body [data-rgh-whitespace="space"] {
  background-image: none !important;
}
```

### Approach 2: Whitelist (opt-in — show on specific pages)

Hide whitespace globally, re-enable on specific pages. Best when you only want
whitespace on a few specific pages.

**Pattern:**

```css
/* Global hide */
[data-rgh-whitespace="space"] {
  background-image: none !important;
}

/* Re-enable on target pages — must use the original SVG since `revert` does not
   restore Refined GitHub's injected styles (they are not part of the UA sheet) */
<scope-selector> [data-rgh-whitespace="space"] {
  background-image: url("data:image/svg+xml,%3Csvg preserveAspectRatio='xMinYMid meet' viewBox='0 0 12 24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M4.5 11C4.5 10.1716 5.17157 9.5 6 9.5C6.82843 9.5 7.5 10.1716 7.5 11C7.5 11.8284 6.82843 12.5 6 12.5C5.17157 12.5 4.5 11.8284 4.5 11Z' fill='rgba(128, 128, 128, 50%25)'/%3E%3C/svg%3E") !important;
}
```

**Examples:**

```css
/* Global hide */
[data-rgh-whitespace="space"] {
  background-image: none !important;
}

/* Show on PR pages */
#diff-comparison-viewer-container [data-rgh-whitespace="space"] {
  background-image: url("data:image/svg+xml,%3Csvg preserveAspectRatio='xMinYMid meet' viewBox='0 0 12 24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M4.5 11C4.5 10.1716 5.17157 9.5 6 9.5C6.82843 9.5 7.5 10.1716 7.5 11C7.5 11.8284 6.82843 12.5 6 12.5C5.17157 12.5 4.5 11.8284 4.5 11Z' fill='rgba(128, 128, 128, 50%25)'/%3E%3C/svg%3E") !important;
}

/* Show on Issue pages */
#discussion_bucket [data-rgh-whitespace="space"] {
  background-image: url("...same SVG...") !important;
}
```

> **Note:** `revert !important` does NOT work for restoring Refined GitHub styles
> because they are injected as author-level CSS, not browser defaults. You must
> paste the full SVG data URI back.

---

## Useful Scope Selectors

| Page                        | Selector / Detection                                      |
|-----------------------------|-----------------------------------------------------------|
| PR (all tabs)               | `#diff-comparison-viewer-container`                       |
| PR Conversation only        | `#diff-comparison-viewer-container:has([class*="Conversations-module"])` |
| PR Files Changed only       | `#diff-comparison-viewer-container:not(:has([class*="Conversations-module"]))` |
| File browsing (`/blob/`)    | `[class*="react-code-file-contents"]`                     |
| Issue page                  | `#discussion_bucket` or `body:has(.gh-header-show)`       |
| README / Markdown render    | `.markdown-body`                                          |
| Wiki                        | `.wiki-body`                                              |
| Gist                        | `.gist-content`                                           |
| Embedded code block         | `.blob-wrapper-embedded`                                  |

---

## Controlling Tab Markers

The current CSS only targets `="space"`. To also control tab arrows:

```css
/* Hide tab arrows on non-PR pages */
body:not(:has(#diff-comparison-viewer-container)) [data-rgh-whitespace="tab"] {
  background-image: none !important;
}

/* Or hide both together */
body:not(:has(#diff-comparison-viewer-container)) [data-rgh-whitespace] {
  background-image: none !important;
}
```

---

## Debug Tools

### 1. Check if whitespace spans exist on the current page

```javascript
const spaces = document.querySelectorAll('[data-rgh-whitespace="space"]').length;
const tabs = document.querySelectorAll('[data-rgh-whitespace="tab"]').length;
console.log(`Whitespace spans — spaces: ${spaces}, tabs: ${tabs}`);
```

### 2. Inspect how a whitespace span is rendered

```javascript
const el = document.querySelector('[data-rgh-whitespace]');
if (!el) { console.log('No whitespace spans found'); } else {
  const cs = getComputedStyle(el);
  console.log({
    tagName: el.tagName,
    rghType: el.dataset.rghWhitespace,
    textContent: JSON.stringify(el.textContent),
    background: cs.background,
    backgroundImage: cs.backgroundImage,
    visibility: cs.visibility,
    display: cs.display,
  });
}
```

### 3. Find trailing whitespace spans (manual test)

```javascript
const parents = new Set();
for (const span of document.querySelectorAll('[data-rgh-whitespace="space"]')) {
  parents.add(span.parentElement);
}
console.log('Line parents found:', parents.size);

let count = 0;
for (const line of parents) {
  const children = [...line.childNodes];
  let i = children.length - 1;
  while (i >= 0) {
    const node = children[i];
    if (node.nodeType === 1 && node.dataset?.rghWhitespace === 'space') {
      node.style.backgroundColor = 'rgba(255, 60, 60, 0.3)';
      count++;
      i--;
    } else {
      break;
    }
  }
}
console.log('Trailing spaces highlighted:', count);
```

### 4. Dump layout hierarchy (for width debugging)

```javascript
(function() {
  const container = document.getElementById('diff-comparison-viewer-container');
  if (!container) { console.log('Not on a PR page'); return; }

  function info(el) {
    const cs = getComputedStyle(el);
    return {
      tag: el.tagName.toLowerCase(),
      id: el.id || undefined,
      class: el.className.split(/\s+/).filter(c =>
        /PageLayout|Layout|container|Conversation|wrapper|Content|Pane|Sidebar|discussion/i.test(c)
      ).join(' ') || el.className.substring(0, 80),
      width: cs.width,
      maxWidth: cs.maxWidth,
      display: cs.display,
      flex: cs.flex || undefined,
    };
  }

  const results = [];
  let el = container;
  for (let depth = 0; depth < 15 && el; depth++) {
    results.push({ depth, ...info(el) });
    const kids = Array.from(el.children).filter(c =>
      c.tagName !== 'SCRIPT' && c.tagName !== 'STYLE' && !c.hidden &&
      getComputedStyle(c).display !== 'none'
    );
    if (kids.length === 1) {
      el = kids[0];
    } else if (kids.length > 1) {
      results.push({ depth: depth + 0.5, note: `${kids.length} visible children` });
      el = kids.find(k =>
        /PageLayout|Conversation|Layout-main|discussion|timeline/i.test(k.className)
      ) || kids[0];
    } else {
      break;
    }
  }
  console.table(results);
})();
```

---

## Key Gotchas

1. **`revert` does not restore Refined GitHub styles** — RGH injects author-level
   CSS; `revert` only rolls back to the UA stylesheet. Use the original SVG data URI.

2. **CSS `:has()` cannot detect text nodes** — trailing whitespace detection via
   pure CSS (`:not(:has(~ :not([data-rgh-whitespace])))`) produces false positives
   on lines where code content is a raw text node (not wrapped in `<span>`).
   Use the Tampermonkey JS approach instead.

3. **Class name hashes change** — GitHub uses CSS Modules with hashed suffixes
   (e.g. `Conversations-module__layout__as5PR`). Always use `[class*="..."]`
   substring matching, never the full class name.

4. **Plural matters** — The module is `Conversations-module` (with **s**),
   not `Conversation-module`.

5. **`#diff-comparison-viewer-container`** wraps ALL PR tabs (Conversation,
   Files Changed, Commits, Checks). It is the `container-xl` element whose
   default `max-width: 1280px` caps the page width.

6. **`data-side-panel-open` attribute** exists on `#diff-comparison-viewer-container`
   on all PR tabs. Value is `"true"` only when the file tree panel is open
   (Files Changed tab). Use `="true"` not just the attribute presence selector.

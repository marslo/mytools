// ==UserScript==
// @name         GitHub PR trailing whitespace highlighter
// @description  Highlight trailing whitespace in PR diffs
// @version      1.0.0
// @include      https://github.com/*/pull/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==

const STYLE = 'background-color: rgba(255, 60, 60, 0.3)';
const ATTR = 'data-rgh-trailing-marked';

function markTrailing() {
  const parents = new Set();
  for (const span of document.querySelectorAll('[data-rgh-whitespace="space"]')) {
    parents.add(span.parentElement);
  }

  for (const line of parents) {
    const children = [...line.childNodes];
    let i = children.length - 1;

    while (i >= 0) {
      const node = children[i];
      if (node.nodeType === 1 && node.dataset?.rghWhitespace === 'space') {
        if (!node.hasAttribute(ATTR)) {
          node.style.cssText += STYLE;
          node.setAttribute(ATTR, '');
        }
        i--;
      } else {
        break;
      }
    }
  }
}

const observer = new MutationObserver(() => {
  clearTimeout(observer._t);
  observer._t = setTimeout(markTrailing, 500);
});
observer.observe(document.body, { childList: true, subtree: true });
setTimeout(markTrailing, 1000);

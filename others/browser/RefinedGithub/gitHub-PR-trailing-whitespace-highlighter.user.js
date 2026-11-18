// ==UserScript==
// @name         GitHub PR trailing whitespace highlighter
// @description  Highlight trailing whitespace in PR diffs
// @version      1.1.0
// @include      https://github.com/*/pull/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==

const STYLE = 'background-color: rgba(255, 60, 60, 0.3)';
const ATTR = 'data-rgh-trailing-marked';
const WS = '[data-rgh-whitespace]'; // space + tab spans from refined-github
const LINE = '.blob-code-inner, .diff-text-inner, td'; // classic / new diff view line container

function mark( span ) {
  if ( span.hasAttribute(ATTR) ) return;
  span.style.cssText += STYLE;
  span.setAttribute( ATTR, '' );
}

// walk the line's text nodes from the end: mark whitespace spans until the first non-blank character
function markLine( line ) {
  const texts = [];
  const walker = document.createTreeWalker( line, NodeFilter.SHOW_TEXT );
  while ( walker.nextNode() ) texts.push( walker.currentNode );
  for ( let i = texts.length - 1; i >= 0; i-- ) {
    const ws = texts[i].parentElement.closest( WS );
    if ( ws && line.contains(ws) ) { mark( ws ); continue; }
    if ( /\S/.test(texts[i].nodeValue) ) break; // real content: nothing before it is trailing
  }
}

function markTrailing() {
  const lines = new Set();
  for ( const span of document.querySelectorAll(WS) ) {
    lines.add( span.closest(LINE) || span.parentElement );
  }
  lines.forEach( markLine );
}

const observer = new MutationObserver( () => {
  clearTimeout( observer._t );
  observer._t = setTimeout( markTrailing, 500 );
} );
observer.observe( document.body, { childList: true, subtree: true } );
setTimeout( markTrailing, 1000 );

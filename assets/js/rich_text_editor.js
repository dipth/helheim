import { Editor, Extension } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Strike from '@tiptap/extension-strike';
import TextAlign from '@tiptap/extension-text-align';
import Link from '@tiptap/extension-link';
import Image from '@tiptap/extension-image';
import Subscript from '@tiptap/extension-subscript';
import Superscript from '@tiptap/extension-superscript';
import Suggestion from '@tiptap/suggestion';
import { MentionableConfig } from './mentionable';

// Helheim.Scrubber whitelists <strike> but strips <s>, so the default Strike
// output would be deleted on save.
const CompatStrike = Strike.extend({
  renderHTML({ HTMLAttributes }) {
    return ['strike', HTMLAttributes, 0];
  }
});

const HEADING_LEVELS = [1, 2, 3, 4];

// Tags the editor schema cannot represent; content containing them (possible
// in the unscrubbed admin term body) would be silently dropped on save, so we
// leave the plain textarea in place instead of mounting the editor.
const UNSUPPORTED_HTML = /<(table|thead|tbody|tr|td|th|pre|code|iframe|frame|div|form|u|video|audio|embed|object|script|style)\b/i;

let usernamesPromise = null;
function fetchUsernames() {
  if (!usernamesPromise) {
    usernamesPromise = fetch(MentionableConfig.data, { headers: { 'Accept': 'application/json' } })
      .then(response => {
        if (!response.ok) throw new Error(`usernames fetch failed: ${response.status}`);
        return response.json();
      })
      .catch(() => {
        usernamesPromise = null;
        return [];
      });
  }
  return usernamesPromise;
}

// Inserts mentions as plain text "@username" so that stored HTML stays
// identical to the old At.js behaviour and Mentionable.run() keeps
// rewriting them into profile links on display.
const MentionSuggestion = Extension.create({
  name: 'mentionSuggestion',

  addProseMirrorPlugins() {
    return [
      Suggestion({
        editor: this.editor,
        char: '@',
        items: ({ query }) => {
          return fetchUsernames().then(usernames => {
            const q = query.toLowerCase();
            return usernames
              .filter(username => username.toLowerCase().includes(q))
              .sort((a, b) => {
                const aStarts = a.toLowerCase().startsWith(q);
                const bStarts = b.toLowerCase().startsWith(q);
                if (aStarts !== bStarts) return aStarts ? -1 : 1;
                return a.localeCompare(b);
              })
              .slice(0, 8);
          });
        },
        command: ({ editor, range, props }) => {
          editor
            .chain()
            .focus()
            .insertContentAt(range, [{ type: 'text', text: `@${props} ` }])
            .run();
        },
        render: () => {
          let menu = null;
          let items = [];
          let command = null;
          let selectedIndex = 0;
          let dismissed = false;

          const removeMenu = () => {
            if (menu) {
              menu.remove();
              menu = null;
            }
          };

          const renderItems = () => {
            if (!menu) return;
            menu.innerHTML = '';
            items.forEach((username, index) => {
              const item = document.createElement('button');
              item.type = 'button';
              item.className = 'dropdown-item' + (index === selectedIndex ? ' active' : '');
              item.textContent = username;
              item.addEventListener('mousedown', event => {
                event.preventDefault();
                command(username);
              });
              menu.appendChild(item);
            });
          };

          const position = clientRect => {
            const rect = clientRect && clientRect();
            if (!rect || !menu) return;
            menu.style.left = `${rect.left + window.pageXOffset}px`;
            menu.style.top = `${rect.bottom + window.pageYOffset}px`;
          };

          const renderMenu = props => {
            items = props.items;
            command = props.command;
            if (dismissed || items.length === 0) {
              removeMenu();
              return;
            }
            if (!menu) {
              menu = document.createElement('div');
              menu.className = 'dropdown-menu rich-text-editor-mentions';
              menu.style.position = 'absolute';
              document.body.appendChild(menu);
            }
            selectedIndex = Math.min(selectedIndex, items.length - 1);
            renderItems();
            position(props.clientRect);
          };

          return {
            onStart: props => {
              dismissed = false;
              selectedIndex = 0;
              renderMenu(props);
            },
            onUpdate: renderMenu,
            onKeyDown: props => {
              if (props.event.key === 'Escape') {
                if (!menu) return false;
                dismissed = true;
                removeMenu();
                return true;
              }
              if (!menu || items.length === 0) return false;
              if (props.event.key === 'ArrowDown') {
                selectedIndex = (selectedIndex + 1) % items.length;
                renderItems();
                return true;
              }
              if (props.event.key === 'ArrowUp') {
                selectedIndex = (selectedIndex + items.length - 1) % items.length;
                renderItems();
                return true;
              }
              if (props.event.key === 'Enter' || props.event.key === 'Tab') {
                command(items[selectedIndex]);
                return true;
              }
              return false;
            },
            onExit: removeMenu
          };
        }
      })
    ];
  }
});

function normalizeUrl(url) {
  if (!url) return null;
  url = url.trim();
  if (url.length === 0) return null;
  // Already has a scheme: keep as typed, but only for safe schemes —
  // reject javascript: and other unsupported protocols.
  if (/^[a-z][a-z0-9+.-]*:/i.test(url)) return /^(https?|mailto):/i.test(url) ? url : null;
  // Site-relative path or fragment: resolve against this site, like the old
  // TinyMCE relative_urls: false + document_base_url behaviour.
  if (url.startsWith('/') || url.startsWith('#')) return new URL(url, document.baseURI).href;
  // Bare domain.
  return `https://${url}`;
}

function urlHost(url) {
  try {
    return new URL(url).host;
  } catch (e) {
    return null;
  }
}

const TOOLBAR_ITEMS = [
  { command: 'undo', icon: 'fa-undo', run: editor => editor.chain().focus().undo().run() },
  { command: 'redo', icon: 'fa-redo', run: editor => editor.chain().focus().redo().run() },
  { separator: true },
  { blockSelect: true },
  { separator: true },
  {
    command: 'bold', icon: 'fa-bold',
    run: editor => editor.chain().focus().toggleBold().run(),
    isActive: editor => editor.isActive('bold')
  },
  {
    command: 'italic', icon: 'fa-italic',
    run: editor => editor.chain().focus().toggleItalic().run(),
    isActive: editor => editor.isActive('italic')
  },
  {
    command: 'strike', icon: 'fa-strikethrough',
    run: editor => editor.chain().focus().toggleStrike().run(),
    isActive: editor => editor.isActive('strike')
  },
  {
    command: 'superscript', icon: 'fa-superscript',
    run: editor => editor.chain().focus().toggleSuperscript().run(),
    isActive: editor => editor.isActive('superscript')
  },
  {
    command: 'subscript', icon: 'fa-subscript',
    run: editor => editor.chain().focus().toggleSubscript().run(),
    isActive: editor => editor.isActive('subscript')
  },
  { separator: true },
  {
    command: 'alignLeft', icon: 'fa-align-left',
    run: editor => editor.chain().focus().setTextAlign('left').run(),
    isActive: editor => editor.isActive({ textAlign: 'left' })
  },
  {
    command: 'alignCenter', icon: 'fa-align-center',
    run: editor => editor.chain().focus().setTextAlign('center').run(),
    isActive: editor => editor.isActive({ textAlign: 'center' })
  },
  {
    command: 'alignRight', icon: 'fa-align-right',
    run: editor => editor.chain().focus().setTextAlign('right').run(),
    isActive: editor => editor.isActive({ textAlign: 'right' })
  },
  {
    command: 'alignJustify', icon: 'fa-align-justify',
    run: editor => editor.chain().focus().setTextAlign('justify').run(),
    isActive: editor => editor.isActive({ textAlign: 'justify' })
  },
  { separator: true },
  {
    command: 'bulletList', icon: 'fa-list-ul',
    run: editor => editor.chain().focus().toggleBulletList().run(),
    isActive: editor => editor.isActive('bulletList')
  },
  {
    command: 'orderedList', icon: 'fa-list-ol',
    run: editor => editor.chain().focus().toggleOrderedList().run(),
    isActive: editor => editor.isActive('orderedList')
  },
  {
    command: 'blockquote', icon: 'fa-quote-right',
    run: editor => editor.chain().focus().toggleBlockquote().run(),
    isActive: editor => editor.isActive('blockquote')
  },
  { command: 'horizontalRule', icon: 'fa-minus', run: editor => editor.chain().focus().setHorizontalRule().run() },
  { separator: true },
  {
    command: 'link', icon: 'fa-link',
    isActive: editor => editor.isActive('link'),
    run: (editor, ctx) => {
      if (editor.isActive('link')) {
        editor.chain().focus().unsetLink().run();
        return;
      }
      const url = normalizeUrl(window.prompt(ctx.labels.linkPrompt));
      if (!url) return;
      if (editor.state.selection.empty) {
        editor.chain().focus().insertContent({
          type: 'text',
          text: url,
          marks: [{ type: 'link', attrs: { href: url } }]
        }).run();
      } else {
        editor.chain().focus().setLink({ href: url }).run();
      }
    }
  },
  {
    command: 'image', icon: 'fa-image',
    run: (editor, ctx) => {
      const url = normalizeUrl(window.prompt(ctx.labels.imagePrompt));
      if (!url) return;
      if (ctx.assetHost && urlHost(url) !== ctx.assetHost && !window.confirm(ctx.labels.externalImageWarning)) {
        return;
      }
      editor.chain().focus().setImage({ src: url }).run();
    }
  }
];

function buildToolbar(container, ctx) {
  const toolbar = document.createElement('div');
  toolbar.className = 'rich-text-editor-toolbar btn-toolbar';
  let group = null;

  TOOLBAR_ITEMS.forEach(item => {
    if (item.separator) {
      group = null;
      return;
    }
    if (!group) {
      group = document.createElement('div');
      group.className = 'btn-group btn-group-sm';
      toolbar.appendChild(group);
    }
    if (item.blockSelect) {
      const select = document.createElement('select');
      select.className = 'form-control form-control-sm rich-text-editor-block-select';
      const blank = document.createElement('option');
      blank.value = '';
      blank.hidden = true;
      blank.disabled = true;
      select.appendChild(blank);
      const paragraph = document.createElement('option');
      paragraph.value = 'p';
      paragraph.textContent = ctx.labels.paragraph;
      select.appendChild(paragraph);
      HEADING_LEVELS.forEach(level => {
        const option = document.createElement('option');
        option.value = String(level);
        option.textContent = `${ctx.labels.heading} ${level}`;
        select.appendChild(option);
      });
      group.appendChild(select);
      return;
    }
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'btn btn-secondary';
    button.title = ctx.labels[item.command] || '';
    button.dataset.command = item.command;
    button.innerHTML = `<i class="fa ${item.icon}"></i>`;
    group.appendChild(button);
  });

  container.appendChild(toolbar);
  return toolbar;
}

function initEditor(textarea) {
  const mentions = textarea.dataset.mentions === 'true';
  const ctx = {
    labels: JSON.parse(textarea.dataset.labels || '{}'),
    assetHost: urlHost(textarea.dataset.assetHost || '')
  };

  // Content the schema cannot represent would be silently dropped on save
  // (relevant for the unscrubbed admin term body); keep the plain textarea.
  if (UNSUPPORTED_HTML.test(textarea.value)) return;

  const wrapper = document.createElement('div');
  wrapper.className = 'rich-text-editor';
  textarea.insertAdjacentElement('afterend', wrapper);

  const toolbar = buildToolbar(wrapper, ctx);
  const mount = document.createElement('div');
  mount.className = 'rich-text-editor-content';
  wrapper.appendChild(mount);

  const extensions = [
    StarterKit.configure({
      heading: { levels: HEADING_LEVELS },
      code: false,
      codeBlock: false,
      strike: false
    }),
    CompatStrike,
    TextAlign.configure({ types: ['paragraph', 'heading'] }),
    Link.configure({ openOnClick: false }),
    Image,
    Subscript,
    Superscript
  ];
  if (mentions) {
    extensions.push(MentionSuggestion);
    fetchUsernames();
  }

  let editor;
  try {
    editor = new Editor({
      element: mount,
      extensions: extensions,
      content: textarea.value,
      onUpdate: ({ editor }) => {
        textarea.value = editor.isEmpty ? '' : editor.getHTML();
      }
    });
  } catch (e) {
    // Leave the plain textarea usable and keep initializing any other
    // editors on the page.
    wrapper.remove();
    console.error('Rich text editor failed to initialize', e);
    return;
  }
  textarea.hidden = true;

  const form = textarea.closest('form');
  if (form) {
    form.addEventListener('submit', () => {
      textarea.value = editor.isEmpty ? '' : editor.getHTML();
    });
  }

  const itemsByCommand = {};
  TOOLBAR_ITEMS.forEach(item => {
    if (item.command) itemsByCommand[item.command] = item;
  });

  toolbar.addEventListener('click', event => {
    const button = event.target.closest('button[data-command]');
    if (!button) return;
    event.preventDefault();
    itemsByCommand[button.dataset.command].run(editor, ctx);
  });

  const blockSelect = toolbar.querySelector('.rich-text-editor-block-select');
  blockSelect.addEventListener('change', () => {
    const value = blockSelect.value;
    if (value === 'p') {
      editor.chain().focus().setParagraph().run();
    } else if (value) {
      editor.chain().focus().setHeading({ level: parseInt(value, 10) }).run();
    }
  });

  const refreshToolbar = () => {
    toolbar.querySelectorAll('button[data-command]').forEach(button => {
      const item = itemsByCommand[button.dataset.command];
      button.classList.toggle('active', item.isActive ? item.isActive(editor) : false);
    });
    const level = HEADING_LEVELS.find(l => editor.isActive('heading', { level: l }));
    if (level) {
      blockSelect.value = String(level);
    } else {
      blockSelect.value = editor.isActive('paragraph') ? 'p' : '';
    }
  };
  editor.on('transaction', refreshToolbar);
  refreshToolbar();
}

export var RichTextEditor = {
  run: function() {
    document.querySelectorAll('textarea[data-rich-text-editor]').forEach(initEditor);
  }
};

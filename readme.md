---

# cherry-prompt.el

A lightweight, interactive file-list aggregator for GNU Emacs. Perfect for cherry-picking source code files across different repositories and consolidating them into a single buffer to feed LLMs (like Claude, ChatGPT, or local models).

Built using pure Elisp, leveraging `tabulated-list-mode` for a familiar Dired/Buffer-menu experience, and `savehist` for seamless persistence between sessions.

![Cherry-Prompt em Ação](https://github.com/seanvert/cherry-prompt/blob/main/ss.png?raw=true)

## Features

- **Granular Cherry-Picking:** Add the currently visited file to your active list with a single keystroke.
- **Interactive Manager:** View and manage your lists inside a dedicated buffer. Use `d` to mark for deletion, `u` to unmark, and `x` to execute—just like Dired or Buffer Menu.
- **Token Estimation:** Displays a lightweight token estimate for each file (based on the standard $characters / 4$ metric) and updates the grand total dynamically in the header.
- **Zero Dependencies:** No external CLI tools, Python scripts, or heavy packages required.
- **Session Persistence:** Lists are saved automatically across Emacs restarts using the native `savehist` mode.

## Installation

Since it's a single-file utility, you can just paste the code into your `~/.emacs.d/init.el` or load it from a custom path:

```elisp
(load-file "/path/to/cherry-prompt.el")

```

## Keybindings

Configure your preferred prefix map. Here is the recommended setup using `C-c l`:

```elisp
(define-prefix-command 'my-list-map)
(global-set-key (kbd "C-c l") 'my-list-map)

(define-key my-list-map (kbd "c") 'my/create-file-list)
(define-key my-list-map (kbd "s") 'my/select-active-list)
(define-key my-list-map (kbd "a") 'my/add-current-file-to-active-list)
(define-key my-list-map (kbd "r") 'my/remove-current-file-from-active-list)
(define-key my-list-map (kbd "v") 'my/show-active-list-manager)
(define-key my-list-map (kbd "p") 'my/process-active-list)

```

## Usage Workflow

1. **Create a list:** Type `C-c l c` and give it a name (e.g., `auth-feature`). This list becomes automatically active.
2. **Collect files:** Navigate through your projects. When you find a file you want to include in your context, press `C-c l a`.
3. **Manage visually:** Press `C-c l v` to open the `*Gerenciador de Lista*` buffer.
* Press `d` to mark a file for removal.
* Press `u` to unmark.
* Press `x` to execute changes.
* Check the header to see the **Total Token Estimate** for your current selection.


4. **Generate Dump:** Press `C-c l p`. A separate buffer called `*Arquivos Copiados*` will open, containing the full text of all files separated by clean, readable comments with filenames and paths. Just copy everything and paste it into your LLM prompt.

## Under the Hood

* **Performance:** Uses `insert-file-contents` to stream file data straight into the buffer without rendering hidden buffers, making it extremely fast even for larger files.
* **Idiomatic:** Extends `tabulated-list-mode` for rendering tables cleanly and respects Emacs' native hooks.

## License

GPL

---


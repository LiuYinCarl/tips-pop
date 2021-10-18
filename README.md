# tips-pop
Emacs plugins to show useful tips

I want to write a Emacs Plugin to help me search the key-bindings fast. So I write tips-pop, which is inspired by [shell-pop-el](https://github.com/kyagi/shell-pop-el).


.emacs config
```elisp
(use-package tips-pop
| :load-path "~/github/tips-pop"
| :init
| (setq tips-pop-universal-key "C-c u"
|  |    tips-pop-window-size 30
|  |    tips-pop-full-span t
|  |    tips-pop-window-position "bottom"
|  |    tips-pop-restore-window-configuration t
|  |    tips-pop-cleanup-buffer-at-process-exit t))

```

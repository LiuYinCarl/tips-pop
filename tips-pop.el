(require 'cl-lib)

(defgroup tips-pop ()
  "tips-group"
  :group 'shell)

(defvar tips-pop-internal-mode "shell")
(defvar tips-pop-internal-mode-buffer "*tips*")
(defvar tips-pop-internal-mode-func '(lambda () (shell))) ;; TODO should't use shell
(defvar tips-pop-last-buffer nil)
(defvar tips-pop-last-window nil)
(defvar tips-pop-last-tips-buffer-index 1)
(defvar tips-pop-last-tips-buffer-name "")
(defvar tips-pop-window-configuration nil)


(defcustom tips-pop-window-size 30
  "Percentage for tips-buffer window size."
  :type '(restricted-sexp
	  :match-alternatives
	  ((lambda (x) (and (integrep x)
			    (<= x 100)
			    (<= 0 x)))))
  :group 'tips-pop)
(defvaralias 'tips-pop-window-height 'tips-pop-window-size)

(defcustom tips-pop-full-span nil
  "If non-nil, the tips span full width of a window"
  :type 'boolean
  :group 'tips-pop)

(defcustom tips-pop-window-position "bottom"
  "Position of the popped buffer."
  :type '(choice
	  (const "top")
	  (const "bottom")
	  (const "left")
	  (const "right")
	  (const "full"))
  :group 'tips-pop)

(defcustom tips-pop-cleanup-buffer-at-process-exit t
  "If non-nil, cleanup the buffer after its process exits."
  :type 'boolean
  :group 'tips-pop)

(defun tips-pop-set-universal-key (symbol value)
  (set-default symbol value)
  (when value (global-set-key (read-kbd-macro value) 'tips-pop))
  (when (and (string= tips-pop-internal-mode "tips")
	     tips-pop-universal-key)
    (define-key term-raw-map (read-kbd-macro value) 'tips-pop)))

(defcustom tips-pop-universal-key nil
  "key binding used to pop in and out of the tips window."

  :type '(choice string (const nil))
  :set 'tips-pop-set-universal-key
  :group 'tips-pop)

(defcustom tips-pop-in-hook nil
  ""
  :type 'hook
  :group 'tips-pop)

(defcustom tips-pop-in-after-hook nil
  ""
  :type 'hook
  :group 'tips-pop)

(defcustom tips-pop-out-hook nil
  ""
  :type 'hook
  :group 'tips-pop)

(defcustom tips-pop-process-exit-hook nil
  ""
  :type 'hook
  :group 'tips-pop)

(defun tips-pop-tips-buffer-name (index)
  ""
  (if (string-match-p "*\\'" tips-pop-internal-mode-buffer)
      (replace-regexp-in-string
       "*\\'" (format "-%d*" index) tips-pop-internal-mode-buffer)
    (format "%s-%d" tips-pop-internal-mode-buffer index)))

(defun tips-pop-check-internal-mode-buffer (index)
  (let ((bufname (tips-pop-tips-buffer-name index)))
    (when (get-buffer bufname)
      (if (or (term-check-proc bufname)
	      (string= tips-pop-internal-mode "eshell"))
	  bufname
	(kill-buffer bufname)
	nil))
    bufname))

(defun tips-pop-get-internal-mode-buffer-window (index)
  (get-buffer-window (tips-pop-check-internal-mode-buffer index)))


(defun tips-pop (arg)
  ""
  (interactive "P")
  (if (string= (buffer-name) tips-pop-last-tips-buffer-name)
      (if (null arg)
	  (tips-pop-out)
	(tips-pop-switch-to-tips-buffer (prefix-numeric-value arg)))
    (tips-pop-up (or arg tips-pop-last-tips-buffer-index))))

(defsubst tips-pop-full-p ()
  ""
  (string= tips-pop-window-position "full"))

(defsubst tips-pop-split-side-p ()
  ""
  (member tips-pop-window-position '("left" "right")))

(defun tips-pop-calculate-window-size ()
  ""
  (let* ((win (and tips-pop-full-span (frame-root-window)))
	 (size (if (tips-pop-split-side-p)
		   (window-width)
		 (window-height win))))
    (round (* size (/ (- 100 tips-pop-window-height) 100.0)))))

(defun tips-pop-kill-and-delete-window ()
  ""
  (unless (one-window-p)
    (delete-window)))

(defun tips-pop-switch-to-tips-buffer (index)
  ""
  (let ((bufname (tips-pop-tips-buffer-name index)))
    (if (get-buffer bufname)
	(switch-to-buffer bufname)
      (funcall (eval tips-pop-internal-mode-func))
      (rename-buffer bufname)
      (tips-pop-set-exit-action))
    (setq tips-pop-last-tips-buffer-name bufname
	  tips-pop-last-tips-buffer-index index)))

(defun tips-pop-translate-position (pos)
  ""
  (cond
   ((string= pos "top") 'above)
   ((string= pos "bottom") 'below)
   ((string= pos "left") 'left)
   ((string= pos "right") 'right)))

(defun tips-pop-get-unused-internal-mode-buffer-window ()
  ""
  (let ((finish nil)
	(index 1)
	bufname)
    (while (not finish)
      (setq bufname (tips-pop-tips-buffer-name index))
      (if (get-buffer bufname)
	  (setq index (1+ index))
	(setq finish t)))
    (cons index (get-buffer-window bufname))))

(defun tips-pop-up (index)
  ""
  (run-hooks 'tips-pop-in-hook)
  (let ((w (if (listp index)
	       (let ((ret (tips-pop-get-unused-internal-mode-buffer-window)))
		 (setq index (car ret))
		 (cdr ret))
	     (tips-pop-get-internal-mode-buffer-window index))))
    (when (tips-pop-full-p)
      (setq tips-pop-window-configuration
	    (list (current-window-configuration) (point-marker)))
      (delete-other-window))
    (if w
	(select-window w)
      (setq tips-pop-last-buffer (buffer-name)
	    tips-pop-last-window (selected-window))
      (when (and (not (= tips-pop-window-height 100))
		 (not (tips-pop-full-p)))
	(let ((new-window (tips-pop-split-window)))
	  (select-window new-window)))
      (tips-pop-switch-to-tips-buffer index))
    (run-hooks 'tips-pop-in-after-hook)))

(defun tips-pop-out ()
  ""
  (run-hooks 'tips-pop-out-hook)
  (if (tips-pop-full-p)
      (let ((window-conf (cl-first tips-pop-window-configuration))
	    (marker (cl-second tips-pop-window-configuration)))
	(set-window-configuration window-conf)
	(when (marker-buffer marker)
	  (goto-char marker)))
    (when (and (not (one-window-p)) (not (= tips-pop-window-height 100)))
      (bury-buffer)
      (delete-window)
      (select-window tips-pop-last-window))
    (when tips-pop-restore-window-configuration
      (switch-to-buffer tips-pop-last-buffer))))

(defun tips-pop-split-window ()
  ""
  (unless (tips-pop-full-p)
    (cond
     (tips-pop-full-span
      (split-window
       (frame-root-window)
       (tips-pop-calculate-window-size)
       (tips-pop-translate-position tips-pop-window-position)))
     (t
      (split-window (selected-window) (tips-pop-calculate-window-size)
		    (tips-pop-translate-position tips-pop-window-position))))))

(provide 'tips-pop)

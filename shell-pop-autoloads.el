(add-to-list 'load-path (directory-file-name
			 (or (file-name-directory #$) (car load-path))))

(defvar tips-pop-universal-key nil)

(custom-autoload 'tips-pop-universal-key "tips-pop" nil)

(autoload 'tips-pop "tips-pop" "\
\(fn ARG" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "tips-pop"
									  '("tips-pop-")))

(load-file "./behave.el")
(load-file "../send.el")
(load-file "../regexp.el")
(load-file "../init.el")
(behave-clear-contexts)

(defvar temp-cmdbuf nil)
(defun setup ()
  (setq temp-cmdbuf (generate-new-buffer "*cmdbuf-test*"))
  (dbgr-cmdbuf-init temp-cmdbuf "rbdbgr" (gethash "rbdbgr" dbgr-pat-hash))
  (dbgr-srcbuf-init (current-buffer) temp-cmdbuf 
		    "rbdbgr" 
		    '("/bin/rbdbgr" "my-script" "arg1"))
)

(defun tear-down()
  (kill-buffer temp-cmdbuf)
)

(context "dbgr-send"
	 (tag send)
	 (specify "format no expand characters"
		  (dolist (str '("abc" "100%" "I feel %% today"))
		    (assert-equal str (dbgr-expand-format str)))
	   )
	 (specify "format %l - with arg"
		  (assert-equal "line 5" (dbgr-expand-format "line %p" 5)))
	 (specify "format %l - without arg"
		  (assert-equal "line " (dbgr-expand-format "line %p")))

	 (setup)
	 ;; Current buffer is now set up as a source buffer
	 (setq file-name (buffer-file-name))
	 (if file-name
	     (specify "File formatting"
		      (dolist 
			  (pair 
			   (list 
			    (cons "%d" (file-name-directory file-name))
			    (cons "%x" file-name)
			    (cons "%X" (expand-file-name file-name))
			    (cons "%f" "test-send.el")
			    (cons "%F" "test-send")))
			(assert-equal (cdr pair) (dbgr-expand-format (car pair))))))
	 (tear-down)

	 (specify "dbgr-define-command"
		  (defalias 'dbgr-command-orig
		    (symbol-function 'dbgr-command))
		  (defun dbgr-command (str &optional arg)
		    (assert-equal "testing" str))
		  (dbgr-define-command 'my-test "testing" "a" "my documentation")
		  (assert-t (functionp 'dbgr-cmd-my-test))
		  (assert-equal "my documentation" (documentation 'dbgr-cmd-my-test))
		  (assert-equal 'dbgr-cmd-my-test (lookup-key (current-local-map) "\C-ca"))
		  (dbgr-cmd-my-test 5)
		  (fset 'dbgr-command (symbol-function 'dbgr-command-orig))
		  )

)

(behave "send")


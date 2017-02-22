(defun org-keys ()
  (interactive)
  ;; Make ~SPC ,~ work, reference:
  ;; http://stackoverflow.com/questions/24169333/how-can-i-emphasize-or-verbatim-quote-a-comma-in-org-mode
  (setcar (nthcdr 2 org-emphasis-regexp-components) " \t\n")
  (org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

  (setq org-emphasis-alist '(("*" bold)
                             ("/" italic)
                             ("_" underline)
                             ("=" org-verbatim verbatim)
                             ("~" org-kbd)
                             ("+"
                              (:strike-through t))))

  (setq org-hide-emphasis-markers t))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "M-h") 'org-metaleft)
  (define-key org-mode-map (kbd "M-j") 'org-metadown)
  (define-key org-mode-map (kbd "M-k") 'org-metaup)
  (define-key org-mode-map (kbd "M-l") 'org-metaright)
  (define-key org-mode-map (kbd "M-H") 'org-shiftmetaleft)
  (define-key org-mode-map (kbd "M-J") 'org-shiftmetadown)
  (define-key org-mode-map (kbd "M-K") 'org-shiftmetaup)
  (define-key org-mode-map (kbd "M-L") 'org-shiftmetaright)
  (org-keys))

(setq org-mobile-force-id-on-agenda-items nil)
(setq org-startup-indented t)
(setq org-agenda-todo-ignore-scheduled t)
(setq org-agenda-todo-ignore-deadlines t)

(add-hook 'org-capture-mode-hook 'evil-insert-state)

;; Sync mobile org automatically in both directions
;; From http://stackoverflow.com/a/31360779/11229
(with-eval-after-load 'org
  (when (and org-mobile-directory org-mobile-inbox-for-pull)
    (require 'org-mobile)
    (require 'gnus-async)
    ;; Define a timer variable
    (defvar org-mobile-push-timer nil
      "Timer that `org-mobile-push-timer' used to reschedule itself, or nil.")
    ;; Push to mobile when the idle timer runs out
    (defun org-mobile-push-with-delay (secs)
      (when org-mobile-push-timer
        (cancel-timer org-mobile-push-timer))
      (setq org-mobile-push-timer
            (run-with-idle-timer
             (* 1 secs) nil 'org-mobile-push)))
    ;; After saving files, start an idle timer after which we are going to push
    (add-hook 'after-save-hook
              (lambda ()
                (if (or (eq major-mode 'org-mode) (eq major-mode 'org-agenda-mode))
                    (dolist (file (org-mobile-files-alist))
                      (if (string= (expand-file-name (car file)) (buffer-file-name))
                          (org-mobile-push-with-delay 30))))))
    ;; watch mobileorg.org for changes, and then call org-mobile-pull
    (defun org-mobile-install-monitor (file secs)
      (run-with-timer
       0 secs
       (lambda (f p)
         (unless (< p (second (time-since (elt (file-attributes f) 5))))
           (org-mobile-pull)
           (org-mobile-push)))
       file secs))
    (defvar monitor-timer (org-mobile-install-monitor (concat org-mobile-directory "/mobileorg.org") 30)
      "Check if file changed every 30 s.")))

;; Refresh calendars via org-gcal and automatically create appt-reminders.
;; Appt will be refreshed any time an org file is saved after 10 seconds of idle.
;; gcal will be synced after 1 minute of idle every 15 minutes.
(with-eval-after-load 'org
  (when org-gcal-client-id
    (defvar aj-refresh-appt-timer nil
      "Timer that `aj-refresh-appt-with-delay' uses to reschedule itself, or nil.")
    (defun aj-refresh-appt-with-delay ()
      (when aj-refresh-appt-timer
        (cancel-timer aj-refresh-appt-timer))
      (setq aj-refresh-appt-timer
            (run-with-idle-timer
             10 nil
             (lambda ()
               (setq appt-time-msg-list nil)
               (org-agenda-to-appt)))))

    (add-hook 'after-save-hook
              (lambda ()
                (when (eq major-mode 'org-mode)
                  (aj-refresh-appt-with-delay))))

    (defvar aj-sync-calendar-timer nil
      "Timer that `aj-sync-calendar-with-delay' uses to reschedule itself, or nil.")
    (defun aj-sync-calendar-with-delay ()
      (when aj-sync-calendar-timer
        (cancel-timer aj-sync-calendar-timer))
      (setq aj-sync-calendar-timer
            (run-with-idle-timer
             60 nil
             'org-gcal-fetch)))

    (run-with-timer
     0 (* 15 60)
     'aj-sync-calendar-with-delay)))

(provide 'init-org)

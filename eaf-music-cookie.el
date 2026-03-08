;;; eaf-music-cookie.el --- 自动复制 EAF 网易云音乐 Cookie -*- lexical-binding: t -*-

;;; Commentary:
;; 提供命令自动从 EAF 浏览器复制网易云音乐 Cookie 到音乐播放器

;;; Code:

(defgroup eaf-music-cookie nil
  "EAF 网易云音乐 Cookie 管理"
  :group 'applications)

(defcustom eaf-music-cookie-script-path
  (expand-file-name "~/.emacs.d/eaf/app/music-player/copy_netease_cookie.py")
  "Cookie 复制脚本路径"
  :type 'string
  :group 'eaf-music-cookie)

;;;###autoload
(defun eaf-music-copy-netease-cookie ()
  "从 EAF 浏览器复制网易云音乐 Cookie 到音乐播放器"
  (interactive)
  (let ((buffer (get-buffer-create "*eaf-music-cookie*")))
    (pop-to-buffer buffer)
    (erase-buffer)
    (insert "正在复制 Cookie...\n")
    (insert "========================================\n\n")
    (if (file-exists-p eaf-music-cookie-script-path)
        (make-process
         :name "eaf-music-cookie"
         :buffer buffer
         :command (list "python3" eaf-music-cookie-script-path)
         :sentinel (lambda (proc event)
                    (when (string-match "finished" event)
                      (with-current-buffer (process-buffer proc)
                        (goto-char (point-max))
                        (insert "\n✅ 完成！现在可以启动音乐播放器了\n")
                        (insert "命令: M-x eaf-open-cloud-music")))))
      (insert (format "❌ 脚本不存在: %s\n" eaf-music-cookie-script-path)))))

;;;###autoload
(defun eaf-music-open-with-cookie ()
  "先复制 Cookie，然后自动打开网易云音乐"
  (interactive)
  (let ((buffer (get-buffer-create "*eaf-music-cookie*")))
    (pop-to-buffer buffer)
    (erase-buffer)
    (insert "正在复制 Cookie...\n")
    (insert "========================================\n\n")
    (if (file-exists-p eaf-music-cookie-script-path)
        (make-process
         :name "eaf-music-cookie"
         :buffer buffer
         :command (list "python3" eaf-music-cookie-script-path)
         :sentinel (lambda (proc event)
                    (when (string-match "finished" event)
                      (with-current-buffer (process-buffer proc)
                        (goto-char (point-max))
                        (if (string-match "✅ Cookie 已保存" (buffer-string))
                            (progn
                              (insert "\n✅ Cookie 复制成功！正在打开音乐播放器...\n")
                              (run-with-timer 0.5 nil #'eaf-open-cloud-music))
                          (insert "\n❌ Cookie 复制失败，请检查日志\n"))))))
      (insert (format "❌ 脚本不存在: %s\n" eaf-music-cookie-script-path)))))

(provide 'eaf-music-cookie)
;;; eaf-music-cookie.el ends here

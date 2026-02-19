;; init-ai.el --- Initialize AI configurations.	-*- lexical-binding: t -*-

;; Copyright (C) 2026 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; URL: https://github.com/seagle0128/.emacs.d

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:
;;
;; AI configurations.
;;

;;; Code:

(eval-when-compile
  (require 'init-const))

;; Interact with ChatGPT or other LLMs
(use-package gptel
  :functions gptel-make-openai
  :custom
  (gptel-model 'gpt-4o)
  ;; Put the apikey to `auth-sources'
  ;; Format: "machine {HOST} login {USER} password {APIKEY}"
  ;; The LLM host is used as HOST, and "apikey" as USER.
  (gptel-backend (gptel-make-openai "Github Models"
                   :host "models.inference.ai.azure.com"
                   :endpoint "/chat/completions?api-version=2024-05-01-preview"
                   :stream t
                   :key 'gptel-api-key
                   :models '(gpt-4o))))

;; Generate commit messages for magit
(use-package gptel-magit
  :hook (magit-mode . gptel-magit-install))

;; A native shell experience to interact with ACP agents
(when emacs/>=29p
  (use-package agent-shell
    :diminish agent-shell-ui-mode))

;; Minuet - AI Code Completion (like Copilot)
(use-package minuet
  :diminish
  :bind
  (("C-M-i" . #'minuet-show-suggestion)    ; 显示补全建议
   ("C-M-y" . #'minuet-complete-with-minibuffer) ; 使用 minibuffer 补全
   ("C-M-m" . #'minuet-configure-provider)  ; 配置 provider
   :map minuet-active-mode-map
   ("M-p" . #'minuet-previous-suggestion)   ; 上一个建议
   ("M-n" . #'minuet-next-suggestion)       ; 下一个建议
   ("M-a" . #'minuet-accept-suggestion-line) ; 逐行接受建议
   ("M-A" . #'minuet-accept-suggestion)      ; 接受整个建议
   ("C-M-e" . #'minuet-dismiss-suggestion))    ; 关闭建议

  :init
  ;; 启用自动建议模式 (类似 Copilot)
  (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode)

  :config
  ;; 配置使用 DeepSeek Coder
  (setq minuet-provider 'openai-compatible)

  ;; 使用 DeepSeek API
  (plist-put minuet-openai-compatible-options :api-key "DEEPSEEK_API_KEY")
  (plist-put minuet-openai-compatible-options :end-point "https://api.deepseek.com/v1/chat/completions")
  (plist-put minuet-openai-compatible-options :model "deepseek-coder")

  ;; 优化参数 - 减少延迟
  (setq minuet-request-timeout 5)
  (setq minuet-auto-suggestion-debounce-delay 0.4)
  (setq minuet-auto-suggestion-throttle-delay 1.0)
  (setq minuet-context-window 4096)

  ;; 设置补全 token 数量
  (minuet-set-optional-options minuet-openai-compatible-options :max_tokens 128)
  (minuet-set-optional-options minuet-openai-compatible-options :top_p 0.9))

(provide 'init-ai)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-ai.el ends here

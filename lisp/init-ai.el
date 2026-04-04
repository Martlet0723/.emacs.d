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
  :diminish
  :functions (gptel-make-openai gptel-make-deepseek gptel-make-anthropic)
  :bind (("C-<f12>"   . gptel)
         ("C-M-<f12>" . gptel-menu))
  :hook (gptel-mode . gptel-highlight-mode)
  :config
  ;; Register backends and setup models
  ;; Securing API keys with authinfo (see `auth-sources')
  ;; format: "machine {HOST} login apikey password {token}"

  ;; 默认使用 MiniMax
  (setq gptel-model 'MiniMax-M2.7
        gptel-backend
        (gptel-make-openai "MiniMax"
          :host "api.minimaxi.com"
          :endpoint "/v1/chat/completions"
          :stream t
          :key (getenv "MINIMAX_API_KEY")
          :models '(MiniMax-M2.7)))

  ;; GitHub Models
  (gptel-make-openai "Github Models"
    :host "models.inference.ai.azure.com"
    :endpoint "/chat/completions?api-version=2024-05-01-preview"
    :stream t
    :key 'gptel-api-key
    :models '(gpt-4o))

  (gptel-make-openai "Nvidia"
    :host "integrate.api.nvidia.com"
    :endpoint "/v1/chat/completions"
    :stream t
    :key 'gptel-api-key
    :models '(z-ai/glm4.7 minimaxai/minimax-m2.1 deepseek-ai/deepseek-v3.1-terminus))

  (gptel-make-openai "ChatGLM"
    :host "open.bigmodel.cn"
    :endpoint "/api/paas/v4/chat/completions"
    :stream t
    :key 'gptel-api-key
    :models '(glm-4.7 glm-4.7-flash glm-5))

  (gptel-make-openai "Moonshot"
    :host "api.moonshot.cn"
    :key 'gptel-api-key
    :stream t
    :models '(kimi-latest kimi-k2-0711-preview))

  (gptel-make-deepseek "DeepSeek"
    :stream t
    :key 'gptel-api-key)

  (gptel-make-anthropic "Claude"
    :stream t
    :key 'gptel-api-key)

  ;; 修复 gptel-rewrite 内容丢失问题：在 rewrite 前保存到 kill-ring
  (defun my/gptel-rewrite-save-region (&rest _)
    "Save region content to kill-ring before gptel-rewrite."
    (when (use-region-p)
      (kill-new (buffer-substring-no-properties (region-beginning) (region-end)))))
  (advice-add 'gptel-rewrite :before #'my/gptel-rewrite-save-region))

;; Generate commit messages for magit
(use-package gptel-magit
  :hook (magit-mode . gptel-magit-install)
  :config
  ;; 修复 reasoning 响应导致的类型错误 (wrong-type-argument char-or-string-p)
  ;; 原因：某些模型（如带思考功能的模型）会返回 (reasoning . "text") 格式的响应
  ;; gptel-magit 的回调函数期望字符串，但收到了 cons cell
  (defun gptel-magit--generate (callback)
    "Generate a commit message for current magit repo.
Invokes CALLBACK with the generated message when done."
    (let ((diff (magit-git-output "diff" "--cached")))
      (gptel-magit--request diff
                            :system gptel-magit-commit-prompt
                            :context nil
                            :callback (lambda (response _info)
                                        ;; 跳过 reasoning cons cell，只处理字符串响应
                                        (when (stringp response)
                                          (let ((msg (gptel-magit--format-commit-message response)))
                                            (funcall callback msg))))))))

;; A native shell experience to interact with ACP agents
(when emacs/>=29p
  (use-package agent-shell
    :diminish agent-shell-ui-mode
    :commands agent-shell-insert
    :defines magit-mode-map
    :functions (magit-staged-files magit-commit-p magit-thing-at-point)
    :custom
    (agent-shell-display-action '(display-buffer-reuse-window))
    (agent-shell-header-style 'text)  ; 禁用图形化 header，使用纯文本
    (agent-shell-opencode-default-model-id "minimax-cn-coding-plan/MiniMax-M2.7")
    ;; (agent-shell-claude-default-model-id "minimax-cn-coding-plan/MiniMax-M2.7")
    :bind (("<f12>"      . agent-shell)
           ("<f13>"      . agent-shell)
           ("C-c a"      . agent-shell)
           ("C-c A"      . agent-shell-new-shell)
           :map agent-shell-mode-map
           ("C-h ?"      . agent-shell-help-menu)
           ("C-<return>" . agent-shell-help-menu)
           :map magit-mode-map
           ("C-c C-g"    . my/agent-shell-magit-generate-commit)
           ("C-c C-r"    . my/agent-shell-review-magit-commit))
    :config
    (with-eval-after-load 'magit
      (defun my/agent-shell-magit-generate-commit ()
        "Generate conventional message and commit stage changes in magit."
        (interactive)
        (if (magit-staged-files)
            (agent-shell-insert
             :submit t
             :text "Commit changes with conventional message")
          (user-error "No staged changes")))

      (defun my/agent-shell-review-magit-commit ()
        "Send the commit from magit to agent-shell for reviews."
        (interactive)
        (if-let* ((commit (magit-commit-p (magit-thing-at-point 'git-revision t))))
            (agent-shell-insert
             :submit t
             :text (format "Review commit: %s" commit))
          (user-error "No magit commit at point"))))))

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
  ;; (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode) ; 注释掉关闭默认启用

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

;; Aidermacs - AI Pair Programming with Aider
(use-package aidermacs
  :bind (("C-c M-m" . aidermacs-transient-menu))
  :custom
  ;; 指定 aider 可执行文件路径
  (aidermacs-program (expand-file-name "~/.local/bin/aider"))
  ;; 使用 MiniMax-M2.5 模型 (Anthropic 兼容格式)
  (aidermacs-default-model "anthropic/MiniMax-M2.5")
  (aidermacs-default-chat-mode 'architect)
  ;; 使用 comint 后端 (更稳定)
  (aidermacs-backend 'comint)
  ;; 关闭自动提交
  (aidermacs-auto-commits nil)
  :config
  ;; 设置 Anthropic 兼容 API Key (从 env.el 读取 MINIMAX_API_KEY)
  (setenv "ANTHROPIC_API_KEY" (getenv "MINIMAX_API_KEY"))
  ;; 设置 MiniMax Anthropic 兼容 API 端点
  (setenv "ANTHROPIC_BASE_URL" "https://api.minimaxi.com/anthropic"))

;; org-ai - AI assistant in Org mode
;; Set API config before loading org-ai
;; MiniMax uses OpenAI-compatible API, so we use 'openai service with custom endpoint
(setq org-ai-service 'openai)
(setq org-ai-openai-api-token (getenv "MINIMAX_API_KEY"))
(setq org-ai-use-auth-source nil)
;; Set MiniMax API endpoint (OpenAI compatible)
(setq org-ai-openai-chat-endpoint "https://api.minimaxi.com/v1/chat/completions")
(use-package org-ai
  :commands (org-ai-mode org-ai-global-mode)
  :hook (org-mode . org-ai-mode)
  :bind (:map org-ai-mode-map
         ("C-c C-c" . org-ai-complete-block)
         ("C-c C-k" . org-ai-kill-region-at-point))
  :custom
  ;; Use MiniMax API
  (org-ai-default-chat-model "MiniMax-M2.5")
  ;; Disable speech features
  (org-ai-talk-output-enable nil)
  ;; Don't jump to end automatically
  (org-ai-jump-to-end-of-block nil)
  :config
  ;; Add MiniMax to available models
  (add-to-list 'org-ai-chat-models "MiniMax-M2.5")
  ;; Enable global mode for commands outside org-mode
  (org-ai-global-mode +1)
  ;; Fix multibyte by advising the original function
  (defun org-ai--payload-utf8-fix (orig-fun &rest args)
    "Around advice to force unibyte for URL requests."
    (let ((result (apply orig-fun args)))
      (if (multibyte-string-p result)
          (string-to-unibyte result)
        result)))
  (advice-add #'org-ai--payload :around #'org-ai--payload-utf8-fix))

(provide 'init-ai)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-ai.el ends here

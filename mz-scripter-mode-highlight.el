(define-minor-mode mz-scripter-mode-highlight
  "キーワードを青色でハイライトするマイナーモード"
  :lighter " MZScr-hl"

  (if mz-scripter-mode-highlight ;; 正規表現の部分には変数は使えないらしい
      (font-lock-add-keywords
       nil
       '(("\\(se\\|sw\\)[0-9]+" . 'mz-scripter-mode-highlight-keyword-and-integer-face) ; se23
	 ("\\(wc\\|wh\\|tc\\|th\\|yc\\|yh\\|ac\\|ah\\|w\\|k\\|hachi\\|kuro\\|txt\\|iseki\\|iseki_fu1\\|iseki_fu2\\|iseki_fu3\\|konoe1\\|konoe2\\|king\\|jiiya\\|master\\)\n" . 'mz-scripter-mode-highlight-character-face) ; wc
	 ("\\(rr\\)\\([^,]+\\),\\([^,]+\\)\\(bb\\)" . 'mz-scripter-mode-highlight-ruby-face) ; rr猫,ねこbb
	;("/\\*\\(.\\|\n\\)*?\\*/" . 'mz-scripter-mode-highlight-memo-face) ; /*メモ行。改行を含む*/
	 ("/\\*\\(.\\|\n\\)*?\\*/" ; /*メモ行。改行を含む*/
	  (0 (progn
	       (put-text-property (match-beginning 0) (match-end 0)
				  'font-lock-multiline t) ; 複数行にまたがるため、font-lock-multilineプロパティを使う
	       'mz-scripter-mode-highlight-memo-face)))
	 ("ss\\(.\\|\n\\)*?cc" ; /*スクリプト行。改行を含む*/
	  (0 (progn
	       (put-text-property (match-beginning 0) (match-end 0)
				  'font-lock-multiline t) ; 複数行にまたがるため、font-lock-multilineプロパティを使う
	       'mz-scripter-mode-highlight-script-face)))
	 (";.+" . 'mz-scripter-mode-highlight-annotation-face) ; 注釈行 
	 ("te\\|tb\\|ts\\|ws\\|wl\\|fnn\\|fng\\|fne\\|wait" . 'mz-scripter-mode-highlight-keyword-only-face) ; te
	 ("\\(?:[^\x00-\x7F]\\)\\{31,\\}" . 'mz-scripter-mode-highlight-over30chars-face) ; 全角30文字超え
	 ("^#[^#].*"
	  (0 (when (mz-scripter-mode-highlight--inside-memo-block-p)
	       'mz-scripter-mode-highlight-h1-face)
	     prepend))
	 ("^##[^#].*"
	  (0 (when (mz-scripter-mode-highlight--inside-memo-block-p)
	       'mz-scripter-mode-highlight-h2-face)
	     prepend))))

    (font-lock-remove-keywords
     nil
     '(("\\(se\\|sw\\)[0-9]+" . 'mz-scripter-mode-highlight-keyword-and-integer-face)
       ("\\(wc\\|wh\\|tc\\|th\\|yc\\|yh\\|ac\\|ah\\|w\\|k\\|hachi\\|kuro\\|txt\\|iseki\\|iseki_fu1\\|iseki_fu2\\|iseki_fu3\\|konoe1\\|konoe2\\|king\\|jiiya\\|master\\)\n" . 'mz-scripter-mode-highlight-character-face)
       ("\\(rr\\)\\([^,]+\\),\\([^,]+\\)\\(bb\\)" . 'mz-scripter-mode-highlight-ruby-face)
       ("/\\*\\(.\\|\n\\)*?\\*/" . 'mz-scripter-mode-highlight-memo-face)
       ("ss\\(.\\|\n\\)*?cc" . 'mz-scripter-mode-highlight-script-face)
       (";.+" . 'mz-scripter-mode-highlight-annotation-face)
       ("te\\|tb\\|ts\\|ws\\|wl\\|fnn\\|fng\\|fne\\|wait" . 'mz-scripter-mode-highlight-keyword-only-face)
       ("\\(?:[^\x00-\x7F]\\)\\{31,\\}" . 'mz-scripter-mode-highlight-over30chars-face)
       ("^#[^#].*" (0 'mz-scripter-mode-highlight-h1-face prepend))
       ("^##[^#].*" (0 'mz-scripter-mode-highlight-h2-face prepend))))
    (font-lock-flush)))


(defun mz-scripter-mode-highlight--inside-memo-block-p ()
  "現在の行が /* ... */ の中にあるかを判定する。"
  (save-excursion
    (let ((pos (point)))
      (and (re-search-backward "/\\*" nil t)
	   (re-search-forward "\\*/" nil t)
	   (< pos (match-end 0))))))


(defface mz-scripter-mode-highlight-keyword-only-face
  '((t (:foreground "dark violet" :weight bold)))
  "キーワードのみのパターンのためのハイライトフェイス。")

(defface mz-scripter-mode-highlight-keyword-and-integer-face
  '((t (:foreground "blue" :weight bold)))
  "キーワード＋整数値のパターンのためのハイライトフェイス。")

(defface mz-scripter-mode-highlight-character-face
  '((t (:foreground "black" :background "medium spring green")))
  "キャラクター名のパターンのためのハイライトフェイス。")

(defface mz-scripter-mode-highlight-ruby-face
  ;;'((t (:background "LightSkyBlue1" :foreground "firebrick3")))
  '((t (:foreground "firebrick3")))
  "ルビのパターンのためのハイライトフェイス。")

(defface mz-scripter-mode-highlight-over30chars-face
  '((t (:background "RosyBrown1")))
  "全角30文字を超過したパターンのためのハイライトフェイス。")

(defface mz-scripter-mode-highlight-annotation-face
  '((t (:foreground "dark green" :weight bold)))
  "注釈行のハイライトフェイス。")

(defface mz-scripter-mode-highlight-script-face
  '((t (:background "#FFFEC4" :underline (:color "blue4"))))
  "スクリプト行のハイライトフェイス。")

(defface mz-scripter-mode-highlight-memo-face
  '((t (:foreground "RoyalBlue1" :background "light cyan")))
  "メモ行のハイライトフェイス。")

(defface mz-scripter-mode-highlight-h1-face
  '((t (:foreground "RoyalBlue1" :weight bold :height 2.0
		    :underline (:color "blue4"))))
  "メモ行内だけで使える、h1行のフェイス")

(defface mz-scripter-mode-highlight-h2-face
  '((t (:foreground "RoyalBlue1" :weight bold :height 1.2)))
  "メモ行内だけで使える、h2行のフェイス")

(defun enable-mz-scripter-highlight ()
  "特定のメジャーモードにhookして、mz-scripter-mode-highlight を自動的に有効化するための関数"
  (mz-scripter-mode-highlight 1))



(provide 'mz-scripter-mode-highlight)


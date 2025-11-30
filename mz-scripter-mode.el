;; mz-scripter-mode.el
;; MZ Scripter mode, RPGツクールMZの台本執筆モード
;; 台本の執筆機能、および台本からMZのJSON形式への変換機能。

;; 命名規則
;; interactiveな関数はmz-scripter-*
;; 内部関数はMZScr/*
;; 内部変数はmzscr-*

;;;;;;;; ライブラリ
(require 'cl-lib) ; common-lisp関数が収録されたライブラリ
(require 'posframe) ; ポップアップで文字列表示
(require 'mz-scripter-mode-highlight) ; ハイライト

;;;;;;;; Keymap
(defvar mz-scripter-mode-keymap
  (let ((keymap (make-sparse-keymap)))
    ;; (define-key keymap (kbd "C-c c") 'よくつかう機能のために残しとく)
    (define-key keymap (kbd "C-c t") 'MZScr/test) ; 開発用
    (define-key keymap (kbd "C-c l") 'MZScr/list-switches) ; 効果音、演出番号を一覧表示
    (define-key keymap (kbd "C-c h") 'describe-bindings) ; ヘルプ表示(Emacs標準の機能を呼ぶ)
    (define-key keymap (kbd "C-c i") 'MZScr/insert-direction) ; 演出(効果音、立ち絵)の挿入
    (define-key keymap (kbd "C-c r") 'mz-scripter-mode-exe-region) ; リージョンで選択された台本をJSONに変換
    ;;(define-key keymap (kbd "C-c b") 'mz-scripter-mode-exe-buffer) ; バッファの台本をJSONに変換
    (define-key keymap (kbd "C-c !") 'mz-scripter-mode-export-to-mz-buffer) ; バッファの台本をJSONに変換
    keymap)
  "Keymap for MZ Scripter mode")

;;;;;;;; 共通変数
(defgroup mz-scripter-mode nil
  "A major mode for Scripting MZ scenario."
  :group 'convenience)
(defcustom mzscr-json-exportfile-path "C://workspace//rpgMaker//games//MZ//bknk2_v1.2.0//data//Map210.json"
  "json file path to export."
  :type 'string
  :group 'mz-scripter-mode)
(defcustom mzscr-json-template-path "~/.emacs.d/elisp/mz-scripter-mode/Map210_template.json"
  "json template file using while exporting."
  :type 'string
  :group 'mz-scripter-mode)

(defface mzscr-header-line-face
  '((t (:background "#FFFEE6" :foreground "dark slate gray" :weight bold)))
  "Face for the header line.")

(defcustom mzscr-next-event-title "東京ゲームダンジョン10"
  "event title for display on right up of buffer."
  :type 'string
  :group 'mz-scripter-mode)

(defcustom mzscr-next-event-date "2025-12-31"
  "date of next event, format is %Y-%m-%d, ex) 1970-01-01"
  :type 'string
  :group 'mz-scripter-mode)

;; マップJSONファイルにエクスポートする際に使用するファイルのパス
;; (setq mzscr-json-exportfile-path "C://workspace//rpgMaker//games//MZ//bknk2_v1.0.0//data//Map210.json")
;; (setq mzscr-json-template-path "~/.emacs.d/elisp/mz-scripter-mode/Map210_template.json")

;; キャラ立ち絵pic, (キャラ名 picファイル名)
(setq mzscr-pic-name-alist
      '(("tc" "たま" "tc.png") ("th" "珠" "th.png") ("yc" "やにゅし" "yc.png") ("yh" "やぬし" "yh.png")
	("wc" "ウィリーキャット" "wc.png") ("wh" "ウィリー" "wh.png") ("yc" "やにゅし" "yc.png") ("yh" "やぬし" "yh.png")
	("ah" "葵" "yh.png") ("ac" "あおい" "ac.png")))

;; キャラ辞書 key:キャラ略称、value:キャラ名とキャラ文字色
(setq mzscr-character-info-alist
      '(("txt" "" "") ; 名無しとか地の文用
	("tc" "たま" "\\\\c[23]")("th" "珠" "\\\\c[23]")("yc" "やにゅし" "\\\\c[2]")("yh" "やぬし" "\\\\c[2]")
	("wc" "ウィリーキャット" "\\\\c[17]")("wh" "ウィリー" "\\\\c[17]")("hachi" "はちわれ" "\\\\c[21]")("kuro" "くろ" "\\\\c[21]")
	("ac" "あおい" "\\\\c[13]")("ah" "葵" "\\\\c[13]")("k" "神主" "\\\\c[5]")("w" "わさポン" "")("iseki" "遺跡ネッコ" "")
	("iseki_fu1" "iseki_fu1" "\\\\c[7]")("iseki_fu2" "iseki_fu2" "\\\\c[7]")("iseki_fu3" "iseki_fu3" "\\\\c[7]")
	("konoe1" "近衛兵ネッコ１" "")("konoe2" "近衛兵ネッコ２" "")("king" "おうさまネッコ" "")("jiiya" "じいや" "")("master" "マスター" "")))
;; (assoc "ah" character-info-alist) ;assoc関数でkey検索可能

;; スイッチ一覧 SE, アクション別にまとめて定義
(setq mzscr-switches
      '((Sound
	 (("ツッコミ" 42) ("シャキーン" 43) ("ボヨン" 44) ("爆発" 45)
	  ("和太鼓" 46) ("ドンドンパフパフ" 47) ("指パッチン" 48) ("ファンファーレ" 49)
	  ("時代劇" 50) ("ウワー" 51) ("スポッ１" 52)("スポッ２" 53)
	  ("拍子木１" 54) ("拍子木２" 55) ("レジスター" 56) ("将棋" 57)
	  ("かわいい音" 58) ("ブン！" 59) ("チーン" 60)("ぱっ" 61)))
	(Action
	 (("富竹フラッシュ" 85)))))

(defun MZScr/test ()
  "for development"
  (interactive))

;;;;;;;; メジャーモード定義
;; hookの定義　慣習的にnilで初期化
(defvar mz-scripter-mode-hook nil
  "Hook run after `mz-scripter-mode` is enabled.")

(defun mz-scripter-mode ()
  "RPGMakerMZ Scripter mode"
  (interactive)

  (use-local-map mz-scripter-mode-keymap) ; MZ Scripterモード用キーマップを使用
  (setq major-mode 'mz-scripter-mode ; メジャーモードの設定
	mode-name "MZ Scripter") ; モードライン上のモード名のフィールド
  (mz-scripter-mode-highlight)
  (face-remap-add-relative 'default :background "#FFFEE6") ; ハイライトを有効化

  (setq-local ; バッファ右上に次のイベントまでの残り日数を表示
   header-line-format
   '(:eval (MZScr/get-header-text))))
;; posfrmeで右上に残りの日時を表示するコードだが、動作が微妙なのでオミット
;; (let ((target-window (get-buffer-window (current-buffer))))
;;   (if (and target-window (window-live-p target-window))
;; 	(posframe-show " *header-posframe*"
;; 		       :string (MZScr/get-header-text)
;; 		       :poshandler #'posframe-poshandler-frame-top-left-corner
;; 		       :background-color "#333333"
;; 		       :foreground-color "white"
;; 		       :internal-border-width 1
;; 		       :timeout nil))))


(defun MZScr/get-header-text ()
  (let* ((text (concat mzscr-next-event-title
		       "("
		       mzscr-next-event-date
		       "), 残り"
		       (number-to-string (MZScr/days-until mzscr-next-event-date))
		       "日！"))
	 (text-width (string-width text))
	 (win-width (window-width))
	 (padding (max 0 (- win-width text-width)))
	 (padded-text (concat (make-string padding ?\s) text)))
    (propertize padded-text 'face 'mzscr-header-line-face)))

(defun MZScr/days-until (date-string)
  "Calculate the number of days from today until DATE-STRING (format: YYYY-MM-DD)."
  (let* ((parts (mapcar #'string-to-number (split-string date-string "-")))
	 (year (nth 0 parts))
	 (month (nth 1 parts))
	 (day (nth 2 parts))
	 (target-time (encode-time 0 0 0 day month year))
	 (now (current-time))
	 (diff (time-subtract target-time now))
	 (days (floor (/ (float-time diff) 86400))))
    days))

;;;;;;;; エディタ機能
(defun MZScr/list-switches ()
  "キャラ辞書とスイッチ一覧を横に並べて専用バッファに表示する。"
  (interactive)
  (with-output-to-temp-buffer "*キャラとスイッチ一覧*"
    (princ (format "%-20s %-10s %-10s | %-20s %-5s\n"
                   "名前" "略称" "色コード" "スイッチ名" "ID"))
    (princ (make-string 80 ?-))
    ;; 最大行数を取得（長い方に合わせる）
    (let* ((char-list mzscr-character-info-alist)
           (switch-list (apply #'append (mapcar #'cadr mzscr-switches)))
           (max-len (max (length char-list) (length switch-list))))
      (dotimes (i max-len)
        (let* ((char-entry (nth i char-list))
               (sw-entry (nth i switch-list))
               (char-key (nth 0 char-entry))
               (char-name (nth 1 char-entry))
               (char-color (nth 2 char-entry))
               (sw-name (if sw-entry (car sw-entry) ""))
               (sw-id (if sw-entry (cadr sw-entry) "")))
          (princ (format "%-20s %-10s %-10s | %-20s %-5s\n"
                         (or char-name "") (or char-key "") (or char-color "")
                         sw-name sw-id))
	  )))
    (princ "\n")
    (princ "mzscrファイルの記法\n")
    (princ "tb, 文字拡大(Text Big) → \\{\n")
    (princ "ts, 文字縮小(Text Small) → \\}\n")
    (princ "ws, 1/4s待ち(Wait Short) → \\.\n")
    (princ "wl, 1s待ち(Wait Long) → \\|\n")
    (princ "te, リターン待ち(Text End) → \\!\n")
    (princ "fnn, ネコフォント → \\fn[n]\n")
    (princ "fn, ギャグフォント → \\fn[g]\n")
    (princ "fne, フォント変更終了 → \\fn\n")))

(defun MZScr/insert-direction ()
  "演出(効果音, 立ち絵, 演出)を挿入する"
  (interactive)
  (let ((choice (read-char-choice "演出の種類を選択　効果音[s] | 立ち絵[p] | 演出[d] :" '("s" "p" "d"))))
    (cond
     ((char-equal choice ?s) ; ?sでsの文字コード
      (MZScr/insert-sound-effect)) ; 効果音の挿入処理
     ((char-equal choice ?p) ; 立ち絵の挿入処理
      (MZScr/insert-standing-picture))
     ((char-equal choice ?d) ; 演出の挿入処理
      (MZScr/insert-staging)))))

(defun MZScr/insert-sound-effect ()
  "効果音を挿入する"
  ;; スイッチのリストから効果音の一覧バッファを作る
  ;; (("ツッコミ" 42) ("シャキーン" 43))
  (let ((se-switch-list (cadr (assoc 'Sound mzscr-switches)))) ; 効果音スイッチ一覧
    (let ((se-option-list
	   (mapcar (lambda (e) (format "%s" e))
		   (number-sequence 0 (1- (length se-switch-list)))))) ; 選択肢用のオプション
      (let ((choice) (config (current-window-configuration)))
					;(save-selected-window
	;; (unwind-protect ; 上手く動かないので一旦コメントアウト
	;; (progn 
	;; (save-excursion ; バッファを変えるからsave-excursionでは戻せない
	;; (with-current-buffer (current-buffer) ; これもダメ
	
	;; スイッチ一覧をカレントバッファの隣に表示する
	(if (one-window-p) ; ウィンドウが分割されていなければ新たに分割
	    (split-window (selected-window) 80 t))
	(other-window 1)
	(switch-to-buffer "*SE Switches*")
	;;(get-buffer-create "*SE Switches*")
	(set-buffer "*SE Switches*")

	;; (erase-buffer)
	(insert "効果音を挿入\n==========\n")
	(MZScr/insert-mzscr-switches se-switch-list nil) ; バッファに効果音一覧を項番付きで表示
	(setq choice (completing-read "インデックスで選択: " se-option-list))

	;; 選択まで終えたので、元のフレーム構成に戻す
	(set-window-configuration config)
	
	(kill-buffer "*SE Switches*")
	;;(switch-to-buffer cur-buf)
	;;(set-window-configration config))
	
	;; choice番目の効果音番号を取得してバッファに挿入
	(let ((i 0) (l se-switch-list))
	  (while (not (eq (string-to-number choice) i))
	    (setq l (cdr l)
		  i (1+ i)))
	  (insert (format "sw%d" (cadar l))))))))

(defun MZScr/insert-standing-picture ()
  "立ち絵番号を挿入する"
  ;; 選択肢表示
  ;; picファイル名リストから選択肢のリストを作成
  (let ((choice)
	(options (mapcar 'car mzscr-pic-name-alist))
	(names (mapcar 'cadr mzscr-pic-name-alist)))
    (let ((choice-sentence
	   (mapconcat 'identity (cl-mapcar (lambda (s1 s2) (format "%s[%s]" s1 s2)) names options) " | ")))
      (setq choice (completing-read (format "%s :" choice-sentence) options)))
    ;; キャラクター選択終わり

    ;; 立ち絵画像表示
    ;; スイッチ一覧をカレントバッファの隣に表示する
    (let ((config (current-window-configuration)))
      (if (one-window-p) 
	  (split-window (selected-window) 20 t) ; ウィンドウが1つだけなら新たに分割
	(window-resize (selected-window) 40 t)) ; 2つ以上ならカレントウィンドウをリサイズ
      (other-window 1)
      (switch-to-buffer "*立ち絵*")
      (set-buffer "*立ち絵*")

      (let ((file-path (concat "~/.emacs.d/elisp/mz-scripter-mode/fig/" choice ".png")))
	(let ((img (create-image file-path 'png nil)))
	  (if img
              (insert-image img)
	    (insert (format "画像を読み込めませんでした: %s" file-path)))))
      (setq choice (completing-read "表情番号を入力 :" '()))

      ;; 選択まで終えたので、元のフレーム構成に戻す
      (set-window-configuration config)
      (kill-buffer "*立ち絵*")
      (insert (format "se%s" choice)))))

(defun MZScr/insert-staging ()
  "演出を挿入する"
  ;; スイッチのリストから演出の一覧バッファを作る
  ;; (("富竹フラッシュ" 85) ("ナイスな演出" 86))
  (let ((action-switch-list (cadr (assoc 'Action mzscr-switches)))) ; 演出一覧
    (let ((action-option-list
	   (mapcar (lambda (e) (format "%s" e))
		   (number-sequence 0 (1- (length action-switch-list)))))) ; 選択肢用のオプション
      (let ((choice) (config (current-window-configuration)))
	;; スイッチ一覧をカレントバッファの隣に表示する
	(if (one-window-p) ; ウィンドウが分割されていなければ新たに分割
	    (split-window (selected-window) 80 t))
	(other-window 1)
	(switch-to-buffer "*Action Switches*")
	(set-buffer "*Action Switches*")
	(insert "演出を挿入\n==========\n")
	(MZScr/insert-mzscr-switches action-switch-list nil) ; バッファに演出一覧を項番付きで表示	
	(setq choice (completing-read "インデックスで選択: " action-option-list))

	;; 選択まで終えたので、元のフレーム構成に戻す
	(set-window-configuration config)
	(kill-buffer "*Action Switches*")
	
	;; choice番目の演出番号を取得してバッファに挿入
	(let ((i 0) (l action-switch-list))
	  (while (not (eq (string-to-number choice) i))
	    (setq l (cdr l)
		  i (1+ i)))
	  (insert (format "sw%d" (cadar l))))))))

(defun MZScr/insert-mzscr-switches(switch-list by-actual-nump)
  "内部処理用：スイッチ番号と名前をバッファに挿入する
by-actual-nump：tを指定すると、実際のスイッチ番号にて挿入
nilを指定すると、0から始まる項番にて挿入"
  (let ((i 0) (l switch-list) e)
    (while (not (eq i (length switch-list)))
      (setq i (1+ i)
	    e (car l)
	    l (cdr l))
      (let ((name (car e))  ; "富竹フラッシュ"
	    (num (cadr e))) ; 42
	(if by-actual-nump
	    (insert (format "[%s]    %s\n" num name)) ; 実際のスイッチ番号
	  (insert (format "[%d]    %s\n" (1- i) name))))))) ; 0から始まる項番


;;;;;;;; JSON変換機能
;;;; 処理用変数
;; 現在処理中の行の種類
;; キャラ名行：name, メモ行：memo, 注釈行：annotation, セリフ行：dialogue
;; メモ行は複数行に跨るため、メモ行の/*から*/までの間はメモ行用の変換を行う
;; 基本的に処理を終えたらnilに戻す
;; メモ行など複数行にまたがるものは戻さずそのままにする
(setq mzscr-current-line-kind nil)

;; キャラ文字色
;; 台本からjsonへの変換のアルゴリズム上、キャラの文字色はグローバル変数として保持
;; キャラ名行から文字色を判定して、セリフ行の行頭に配置する
(setq mzscr-text-color "\\\\c[0]")

(defun MZScr/get-name (key)
  "キャラ辞書からキャラ名を取得"
  (let ((character-info (assoc key mzscr-character-info-alist)))
    (cadr character-info)))

(defun MZScr/get-text-color (key)
  "キャラ辞書からキャラ文字色を取得"
  (let ((character-info (assoc key mzscr-character-info-alist)))
    (caddr character-info)))

(defun MZScr/replace-se (arg)
  "テキスト中の表情番号をMZ形式に変換する。
se22 → \\SE[22] ※ JSON形式に併せてbackslashはふたつ
「se」と「1桁以上の数字」がくっ付いたもの検索し、1桁以上の数字は置換後の文字列にて利用(\\2のとこ)"
  (replace-regexp-in-string "\\(se\\)\\([0-9]+\\)" "\\\\\\\\SE[\\2]" arg))

(defun MZScr/replace-switch (arg)
  "テキスト中のスイッチ番号をMZ形式に変換する。 sw22 → \\+switch[22]"
  (replace-regexp-in-string "\\(sw\\)\\([0-9]+\\)" "\\\\\\\\+switch[\\2]" arg))

(defun MZScr/replace-ruby (arg)
  "テキスト中のルビをMZ形式に変換する rb文字,もじbr → \\rb[文字,もじ]
正規表現：5か所に分けて一致させる
rb　','を除く1文字以上　','　','を除く1文字以上　br
※ M-x rb-builder で正規表現を確認しながら書ける
※ Emacs Lispの正規表現は、バックスラッシュが多くなる(エスケープがイケてないため)"

  (replace-regexp-in-string "\\(rr\\)\\([^,]+\\),\\([^,]+\\)\\(bb\\)" "\\\\\\\\r[\\2,\\3]" arg))
;; (ruby-replacer "rb猫,ねこbr")
;; (ruby-replacer "rb猫,ねこbr test 一行に2回以上現れるパターンrb猫,ねこbr")


(defun MZScr/replace-ctrlChar (arg)
  "テキスト中の制御文字をMZ形式に変換する"
  (let ((replacements '(("tb" . "\\\\\\\\{") ; 文字拡大, tb(Text Big) → \\{
			("ts" . "\\\\\\\\}") ; 文字縮小, ts(Text Small) → \\}
			("te" . "\\\\\\\\!") ; リターン待ち, te(Text End) → \\!
			("ws" . "\\\\\\\\.") ; 1/4s wait, ws(Wait Short) → \\.
			("wl" . "\\\\\\\\|") ; 1s wait te(Wait Long) → \\|
			("fnn" . "\\\\\\\\fn[n]")   ; ネコフォント, fnn → \\fn[n]
			("fng" . "\\\\\\\\fn[gag]") ; ギャグフォント, fng → \\fn[gag]
			("fne" . "\\\\\\\\fn"))))   ; フォント変更終了, fne → \\fn
    (dolist (pair replacements arg)
      (setq arg (replace-regexp-in-string (car pair) (cdr pair) arg)))))


(defun MZScr/set-line-kind (arg)
  "argが何の行なのか設定"
  (cond
   ((MZScr/get-name arg) ; キャラ名がヒットしたらキャラ名行
    (setq mzscr-current-line-kind 'NAME))
   ((and (<= 1 (length arg)) (string= (substring arg 0 1) ";")) ; 先頭1文字目が;だったら注釈行
    (setq mzscr-current-line-kind 'ANNOTATION))
   ((and (<= 4 (length arg)) (string= (substring arg 0 4) "wait")) ; 先頭4文字がwaitだったらウェイト行
    (setq mzscr-current-line-kind 'WAIT))
   ((or ; メモ行は複数行にまたがる
     (eq mzscr-current-line-kind 'MEMO) ; メモ行が設定されてたらメモ行の途中
     (string= arg "/*") ; メモ行の開始記号
     (string= arg "*/")) ; メモ行の終了記号
    (setq mzscr-current-line-kind 'MEMO)) ; メモ行
   ((or ; スクリプト行は複数行にまたがる
     (eq mzscr-current-line-kind 'SCRIPT) ; スクリプト行が設定されてたらスクリプト行の途中
     (and (<= 2 (length arg)) (string= (substring arg 0 2) "ss")) ; 先頭2文字がssだったらスクリプト行
     (string= arg "cc")) ; スクリプト行の終了記号
    (setq mzscr-current-line-kind 'SCRIPT)) ; スクリプト行
   ((and (<= 6 (length arg)) (string= (substring arg 0 6) "action")) ; 先頭6文字がactionだったらアクション行
    (setq mzscr-current-line-kind 'ACTION))
   (t (setq mzscr-current-line-kind 'DIALOGUE)))) ; それ以外はセリフ行

(defun MZScr/script-line-to-json-line (arg)
  "台本の一行をMZの会話用JSONの一行に変換する。
行の種類に応じて変換処理を変える。
・キャラ名行 NAME
・注釈行 ANNOTATION
・ウェイト行 WAIT
・アクション行（対応予定） ACTION
・セリフ行 DIALOGUE"
  (MZScr/set-line-kind arg) ; 引数行の種類を取得
  (cond
   ((eq mzscr-current-line-kind 'NAME) ; キャラ名の変換処理
    (setq mzscr-current-line-kind nil) ; 引数行の種類をnilに戻す
    (let ((template-str "{\"code\":101,\"indent\":0,\"parameters\":[\"\",0,0,2,\"%%NAME%%\"]},\n"))
      (let ((name (MZScr/get-name arg))
	    (text-color (MZScr/get-text-color arg))) ; キャラ名とキャラ文字色を取得
	(setq mzscr-text-color text-color) ; キャラ文字色をセット ※ここでは使わない。セリフ行の変換処理にて行頭に配置する
	(princ (string-replace "%%NAME%%" name template-str)))))
   
   ((eq mzscr-current-line-kind 'ANNOTATION) ; 注釈行の変換処理
    (setq mzscr-current-line-kind nil) ; 引数行の種類をnilに戻す
    (let ((template-str "{\"code\":108,\"indent\":0,\"parameters\":[\";;\"]},{\"code\":408,\"indent\":0,\"parameters\":[\";; %%LINE%%\"]},\n"))
      (princ (string-replace "%%LINE%%" arg template-str))))

   ((eq mzscr-current-line-kind 'WAIT) ; ウェイト行の変換処理
    (message "waitwaitwait")
    (setq mzscr-current-line-kind nil) ; 引数行の種類をnilに戻す
    (let ((template-str "{\"code\":230,\"indent\":0,\"parameters\":[%%VALUE%%]},\n")
	  (value (string-replace "wait" "" (string-replace " " "" arg)))) ; ウェイトする値を取り出し
      (princ (string-replace "%%VALUE%%" value template-str))))
   
   ((eq mzscr-current-line-kind 'MEMO) ; メモ行の変換処理
    ;; 変換処理は何もしない
    (if (string= arg "*/") ; メモ行の終了記号 */ が来た場合のみ引数行の種類をnilに戻す
	(setq mzscr-current-line-kind nil)))

   ((eq mzscr-current-line-kind 'SCRIPT) ; スクリプト行の変換処理
    (if (string= arg "cc")
	;; スクリプト行の終了記号 cc が来た場合のみ引数行の種類をnilに戻す
	;; また、ccの際は変換処理は行わない
					;(progn
	(setq mzscr-current-line-kind nil)
					;(princ "hogehoghoge"))
      (let ((template-str "{\"code\":%%CODE_NUM%%,\"indent\":0,\"parameters\":[\"%%LINE%%\"]},\n"))
	(if (and (<= 2 (length arg)) (string= (substring arg 0 2) "ss"))
	    ;; ssから始まる行はcode:355, "ss "(ssと半角スペース) を取り除いてから置換
	    (let ((without-ss-arg (string-replace "ss" "" (string-replace "ss " "" arg))))
	      (princ (string-replace "%%CODE_NUM%%" "355" (string-replace "%%LINE%%" without-ss-arg template-str))))
	  ;; それ以外は655, argをそのまま置換
	  (princ (string-replace "%%CODE_NUM%%" "655" (string-replace "%%LINE%%" arg template-str)))))))

   ((eq mzscr-current-line-kind 'ACTION) ; アクション行の変換処理
    (setq mzscr-current-line-kind nil) ; 引数行の種類をnilに戻す
    (concat arg "アクション用処理"))

   ((eq mzscr-current-line-kind 'DIALOGUE) ; セリフ行の変換処理
    (setq mzscr-current-line-kind nil) ; 引数行の種類をnilに戻す
    ;; セリフ行の変換規則
    ;; 1. キャラに応じて文字色を先頭に配置
    ;; 2. "se"と1桁以上の数字が続く箇所をMZの表情番号に置換 se22→\\SE[22]
    ;; 3. "sw"と1桁以上の数字が続く箇所をMZのスイッチ番号に置換 sw→\\+switch[22]
    ;; 4. ルビを置換。rb文字,もじbr→\\rb[文字,もじ]
    ;; 5. 制御文字を置換。文字大(Text Big),"tb"→\\{  文字小(Text Small) ts→\\}  リターン待ち(Text End) te→\\!
    (let ((template-str "{\"code\":401,\"indent\":0,\"parameters\":[\" %%TEXT-COLOR%%%%LINE%%\"]},\n")
	  (line-replaced (MZScr/replace-ruby
			  (MZScr/replace-se
			   (MZScr/replace-switch
			    (MZScr/replace-ctrlChar arg)))))) ; セリフ行。制御文字、表情番号、スイッチ番号、ルビを置換
      (princ (string-replace "%%TEXT-COLOR%%" mzscr-text-color (string-replace "%%LINE%%" line-replaced template-str)))))
   (t nil)))

;;(MZScr/script-line-to-json-line "tc")
;;(MZScr/script-line-to-json-line "; 注釈行です")
;;(MZScr/script-line-to-json-line "actionアクション行だよ")
;;(MZScr/script-line-to-json-line "se4tbtbぬにゃあ！te rr本気,マジbb tstsにゅおお・・・。te")
;;(MZScr/script-line-to-json-line "/*")
;;(MZScr/script-line-to-json-line "fff")
;;(MZScr/script-line-to-json-line "*/")


(defun MZScr/script-list-to-json-list (script-list)
  "台本全行(リスト)をMZの会話用JSON(リスト)に変換"
  (mapcar 'MZScr/script-line-to-json-line script-list))
;; (MZScr/script-list-to-json-list '("yc" "se4tbぬにゃあ！sw42te" "se16グーン・ウォーリアー号！te"))


(defun mz-scripter-mode-exe-region ()
  "リージョンからmzのマップjsonへ変換してウィンドウに書き出す"
  (interactive) ; interactiveの引数についてのとっかかり https://nitbit.hatenadiary.org/entry/20101103/1288781507
  (let ((region-string (buffer-substring-no-properties (region-beginning) (region-end))))
    (let ((region-string-list (remove "" (split-string region-string "\n")))) ;リージョンの各行からリストを作る。空行は除去
      ;; (prin1 region-string-list)
      ;;(goto-char (point-max)) ;; バッファ末行に移動
      ;;(insert "\n") (insert "\n") ;; 空行入れてから出力(コピペしやすいため！)

      (let ((config (current-window-configuration)))
	;; 変換後のjsonをカレントウィンドウの隣に表示する
	(if (one-window-p) ; ウィンドウが分割されていなければ新たに分割
	    (split-window (selected-window) 80 t))
	(other-window 1)
	(switch-to-buffer "*MZ Scripter Mode Output*")
	(set-buffer "*MZ Scripter Mode Output*")
	;; mapc..リストの全要素に対して処理を実施、リストは返さない
	;; mapcar..リストの全要素に対して処理を実施し、新しいリストを返す
	(mapc 'insert (MZScr/script-list-to-json-list region-string-list)) ;; 変換、書き出し
	(insert "\n"))))) ;; 最後に空行

(defun mz-scripter-mode-exe-buffer ()
  "バッファからmzのマップjsonへ変換してウィンドウに書き出す"
  (interactive)
  (let ((buffer-string-list
	 (remove "" (split-string
		     (buffer-substring-no-properties (point-min) (point-max)) "\n")))) ;バッファからリストを作る。空行は除去
    (let ((config (current-window-configuration)))
      ;; 変換後のjsonをカレントウィンドウの隣に表示する
      (if (one-window-p) ; ウィンドウが分割されていなければ新たに分割
	  (split-window (selected-window) 80 t))
      (other-window 1)
      (switch-to-buffer "*MZ Scripter Mode Output*")
      (set-buffer "*MZ Scripter Mode Output*")
      (mapc 'insert (MZScr/script-list-to-json-list buffer-string-list)) ;; 変換、書き出し
      (insert "\n"))))

(defun mz-scripter-mode-export-to-mz-buffer ()
  (interactive)
  "バッファからmzのマップjsonファイルへエクスポートする"
  (let ((buffer-string-list ;バッファからリストを作る。空行は除去
	 (remove "" (split-string
		     (buffer-substring-no-properties (point-min) (point-max)) "\n"))))
    (let ((script-json-text (mapconcat #'identity (MZScr/script-list-to-json-list buffer-string-list) "\t"))) ;台本からjson化
      (let ((jsonbody ;Map用jsonのボディ
	     (with-temp-buffer ; 一時バッファにファイルの内容を取得
	       (insert-file-contents mzscr-json-template-path)
	       (goto-char (point-min))
	       (while (search-forward "%%MZSCR%%" nil t) ; 置き換え部分を台本jsonに置換する
		 (replace-match script-json-text t t))
	       (buffer-string))))
	;; エクスポート先のファイルに書き出す
	(find-file mzscr-json-exportfile-path)
	(erase-buffer)
	(insert jsonbody)
	(save-buffer)
	(kill-buffer)))))

;; (x-popup-menu t '("Menu Title"
;;                   ("表情"
;;                    ("Item1-1" . 11)
;;                    ("Item1-2" . 12))
;;                   ("効果音"
;;                    ("ツッコミ" . 42)
;;                    ("シャキーン" . 43)
;;                    ("ボヨン" . 44))
;;                   ("演出"
;;                    ("富竹フラッシュ" . 21))))

(provide 'mz-scripter-mode)
;;; mz-scripter-mode.el ends here




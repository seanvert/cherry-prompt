;; =========================================================================
;; 1. VARIÁVEIS GLOBAIS E PERSISTÊNCIA (Sempre no topo)
;; =========================================================================

(defvar my/file-lists nil
  "Alist (lista de associação) que guarda as listas de arquivos.
O formato é ((\"nome-da-lista\" . (\"arq1\" \"arq2\"))).")

(defvar my/active-file-list nil
  "Nome da lista de arquivos que está ativa no momento.")

(defvar my/file-list-manager-buffer "*Gerenciador de Lista*"
  "Nome do buffer interativo de gerenciamento de arquivos.")
(require 'savehist)
;; Ativa o savehist-mode para persistir dados entre sessões
(add-to-list 'savehist-additional-variables 'my/file-lists)
(savehist-mode 1)

;; =========================================================================
;; 2. FUNÇÕES DE MANIPULAÇÃO DE ARQUIVOS E LISTAS
;; =========================================================================

(defun my/insert-files-to-separate-buffer (file-list)
  "Pega uma lista de caminhos de arquivos, cria (ou limpa) um buffer chamado
'*Arquivos Copiados*' e insere o conteúdo de cada um com um cabeçalho destacado."
  (interactive)
  (let ((target-buffer (get-buffer-create "*Arquivos Copiados*")))
    (with-current-buffer target-buffer
      (erase-buffer))
    (switch-to-buffer target-buffer)
    (dolist (file file-list)
      (if (file-exists-p file)
          (let ((absolute-path (expand-file-name file))
                (file-name (file-name-nondirectory file)))
            (insert (format "\n;; ==========================================\n"))
            (insert (format ";; ARQUIVO: %s\n" file-name))
            (insert (format ";; CAMINHO: %s\n" absolute-path))
            (insert (format ";; ==========================================\n\n"))
            (insert-file-contents absolute-path)
            (goto-char (point-max))
            (insert "\n"))
        (message "Aviso: O arquivo %s não foi encontrado." file)))))

(defun my/create-file-list (name)
  "Cria uma nova lista de arquivos vazia com o NAME fornecido."
  (interactive "sNome da nova lista de arquivos: ")
  (if (assoc name my/file-lists)
      (error "Uma lista com o nome '%s' já existe!" name)
    (push (cons name nil) my/file-lists)
    (setq my/active-file-list name)
	(savehist-save)
    (message "Lista '%s' criada e definida como ATIVA." name)))

(defun my/select-active-list ()
  "Seleciona uma lista existente para ser a lista ativa."
  (interactive)
  (if (null my/file-lists)
      (message "Nenhuma lista criada ainda. Use M-x my/create-file-list")
    (let ((chosen (completing-read "Selecione a lista ativa: " (mapcar #'car my/file-lists))))
      (setq my/active-file-list chosen)
      (message "Lista ativa definida para: '%s'" chosen))))

(defun my/add-current-file-to-active-list ()
  "Adiciona o arquivo do buffer atual à lista ativa."
  (interactive)
  (unless my/active-file-list
    (error "Nenhuma lista ativa selecionada! Use M-x my/select-active-list ou my/create-file-list"))
  (let ((file-path (buffer-file-name)))
    (if (not file-path)
        (message "Este buffer não está visitando um arquivo!")
      (let* ((list-cell (assoc my/active-file-list my/file-lists))
             (current-files (cdr list-cell)))
        (if (member file-path current-files)
            (message "O arquivo já está na lista '%s'." my/active-file-list)
          (setcdr list-cell (append current-files (list file-path)))
		  (savehist-save)
          (message "Arquivo '%s' adicionado à lista '%s'." 
                   (file-name-nondirectory file-path) my/active-file-list))))))

(defun my/remove-current-file-from-active-list ()
  "Remove o arquivo do buffer atual da lista ativa, se ele estiver lá."
  (interactive)
  (unless my/active-file-list
    (error "Nenhuma lista ativa selecionada! Use M-x my/select-active-list"))
  (let ((file-path (buffer-file-name)))
    (if (not file-path)
        (message "Este buffer não está visitando um arquivo!")
      (let* ((list-cell (assoc my/active-file-list my/file-lists))
             (current-files (cdr list-cell)))
        (if (not (member file-path current-files))
            (message "O arquivo '%s' não está na lista '%s'." 
                     (file-name-nondirectory file-path) my/active-file-list)
          (setcdr list-cell (delete file-path current-files))
		  (savehist-save)
          (message "Arquivo '%s' removido da lista '%s'." 
                   (file-name-nondirectory file-path) my/active-file-list))))))

(defun my/process-active-list ()
  "Processa e copia todos os arquivos da lista ativa para o buffer separado."
  (interactive)
  (unless my/active-file-list
    (error "Nenhuma lista ativa para processar!"))
  (let ((files (cdr (assoc my/active-file-list my/file-lists))))
    (if (null files)
        (message "A lista '%s' está vazia." my/active-file-list)
      (my/insert-files-to-separate-buffer files))))



;; =========================================================================
;; 3. MODO VISUAL E GERENCIADOR INTERATIVO (Com estimativa de Tokens)
;; =========================================================================

(defvar-local my/manager-current-list-name nil
  "Variável local de buffer para rastrear qual lista está sendo exibida.")

(define-derived-mode my/file-list-manager-mode tabulated-list-mode "File-List-Manager"
  "Modo para gerenciar interativamente os arquivos de uma lista."
  ;; Adicionamos a coluna "Tokens (~)" com tamanho 12
  (setq tabulated-list-format [("Status" 8 t)
                               ("Arquivo" 25 t)
                               ("Tokens (~)" 12 t)
                               ("Caminho Completo" 0 t)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

;; Binds diretos no mapa gerado pelo modo
(define-key my/file-list-manager-mode-map (kbd "d") 'my/manager-mark-delete)
(define-key my/file-list-manager-mode-map (kbd "u") 'my/manager-unmark)
(define-key my/file-list-manager-mode-map (kbd "x") 'my/manager-execute-deletions)
(define-key my/file-list-manager-mode-map (kbd "g") 'my/manager-refresh)

(defun my/manager-get-token-estimate (file)
  "Retorna uma estimativa do número de tokens para o FILE baseado em caracteres.
Se o arquivo não existir, retorna 0."
  (if (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        ;; Regra dos 4 caracteres por token
        (/ (buffer-size) 4))
    0))

(defun my/manager-mark-delete ()
  "Marca o arquivo na linha atual para remoção."
  (interactive)
  (let ((inhibit-read-only t))
    (tabulated-list-set-col 0 "D" t)
    (forward-line 1)))

(defun my/manager-unmark ()
  "Remove a marcação da linha atual."
  (interactive)
  (let ((inhibit-read-only t))
    (tabulated-list-set-col 0 " " t)
    (forward-line 1)))

(defun my/manager-execute-deletions ()
  "Executa a remoção de todos os arquivos marcados com 'D'."
  (interactive)
  (unless my/manager-current-list-name
    (error "Erro: Nenhuma lista associada a este buffer."))
  (let ((list-cell (assoc my/manager-current-list-name my/file-lists))
        (files-to-delete nil))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let ((id (tabulated-list-get-id))
              (status (aref (tabulated-list-get-entry) 0)))
          (when (string= status "D")
            (push id files-to-delete)))
        (forward-line 1)))
    (if (null files-to-delete)
        (message "Nenhum arquivo marcado para remoção.")
      (when (y-or-n-p (format "Remover %d arquivo(s) da lista '%s'? " 
                              (length files-to-delete) my/manager-current-list-name))
        (dolist (file files-to-delete)
          (setcdr list-cell (delete file (cdr list-cell))))
		(savehist-save)
        (message "Arquivos removidos!")
        (my/manager-refresh)))))

(defun my/manager-refresh ()
  "Regera as linhas do buffer com base no estado atual da lista e calcula o total."
  (interactive)
  (let* ((list-cell (assoc my/manager-current-list-name my/file-lists))
         (total-tokens 0))
    
    ;; Mapeia os arquivos e calcula os tokens individuais e o total
    (setq tabulated-list-entries
          (mapcar (lambda (file)
                    (let ((tokens (my/manager-get-token-estimate file)))
                      (setq total-tokens (+ total-tokens tokens))
                      (list file (vector " " 
                                         (file-name-nondirectory file) 
                                         (number-to-string tokens)
                                         (expand-file-name file)))))
                  (cdr list-cell)))
    
    ;; Atualiza dinamicamente o cabeçalho para mostrar o grande total!
    (setq tabulated-list-format (vector '("Status" 8 t)
                                        '("Arquivo" 25 t)
                                        (list (format "%s Tokens" (number-to-string total-tokens)) 12 t)
                                        '("Caminho Completo" 0 t)))
    (tabulated-list-init-header)
    (tabulated-list-print t)))

(defun my/show-active-list-manager ()
  "Abre o buffer interativo para gerenciar a lista ativa atual."
  (interactive)
  (unless my/active-file-list
    (error "Nenhuma lista ativa selecionada!"))
  (let ((buffer (get-buffer-create my/file-list-manager-buffer)))
    (with-current-buffer buffer
      (my/file-list-manager-mode)
      (setq my/manager-current-list-name my/active-file-list)
      (my/manager-refresh))
    (switch-to-buffer buffer)
    (message "Gerenciando lista: '%s'. Use [d] marcar, [u] desmarcar, [x] executar." my/active-file-list)))

;; =========================================================================
;; 4. KEYBINDINGS GLOBAIS (PREFIXO C-c l)
;; =========================================================================

(define-prefix-command 'my-list-map)
(global-set-key (kbd "C-c l") 'my-list-map)

(define-key my-list-map (kbd "c") 'my/create-file-list)
(define-key my-list-map (kbd "s") 'my/select-active-list)
(define-key my-list-map (kbd "a") 'my/add-current-file-to-active-list)
(define-key my-list-map (kbd "p") 'my/process-active-list)
(define-key my-list-map (kbd "r") 'my/remove-current-file-from-active-list)
(define-key my-list-map (kbd "v") 'my/show-active-list-manager)

#!/usr/bin/env bash
set -e

TMUX_CONF="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

echo "==> Sprawdzam, czy tmux jest zainstalowany..."
if ! command -v tmux >/dev/null 2>&1; then
  echo "Błąd: tmux nie jest zainstalowany. Zainstaluj tmux i uruchom skrypt ponownie."
  exit 1
fi
echo "OK: tmux jest dostępny."

echo "==> Instaluję TPM (tmux plugin manager), jeśli potrzeba..."
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "TPM zainstalowany w $TPM_DIR."
else
  echo "TPM już istnieje w $TPM_DIR – pomijam."
fi

echo "==> Tworzę plik konfiguracyjny $TMUX_CONF, jeśli nie istnieje..."
if [ ! -f "$TMUX_CONF" ]; then
  touch "$TMUX_CONF"
fi

echo "==> Dodaję konfigurację pluginów do $TMUX_CONF (jeśli jeszcze jej nie ma)..."

# Blok konfiguracyjny, który chcemy mieć w .tmux.conf
read -r -d '' PLUGIN_BLOCK <<'EOF'

# --- [tmux plugin manager (TPM)] ---
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Automatyczne zapisywanie sesji co kilka minut
set -g @continuum-restore 'on'          # automatyczne przywracanie sesji przy starcie tmux
set -g @continuum-save-interval '5'    # co ile minut zapisywać (domyślnie 15)

# Klawisze:
#   Prefix + I  -> instalacja/aktualizacja pluginów
#   Prefix + Ctrl-s -> ręczny zapis (tmux-resurrect)
#   Prefix + Ctrl-r -> ręczne przywrócenie (tmux-resurrect)

run-shell '~/.tmux/plugins/tpm/tpm'
# --- [koniec konfiguracji TPM] ---
EOF

# Sprawdź, czy w pliku już jest odniesienie do tmux-resurrect
if grep -q "tmux-plugins/tmux-resurrect" "$TMUX_CONF"; then
  echo "Wygląda na to, że konfiguracja tmux-resurrect/tpm już istnieje w $TMUX_CONF – nie dodaję drugi raz."
else
  {
    echo ""
    echo "$PLUGIN_BLOCK"
  } >>"$TMUX_CONF"
  echo "Dodano konfigurację pluginów do $TMUX_CONF."
fi

echo
echo "==> Gotowe!"

echo "Co dalej:"
echo "1) Uruchom nową sesję tmux (albo dołącz do istniejącej):"
echo "     tmux"
echo "2) W tmux naciśnij: Prefix (domyślnie Ctrl-b), potem wielkie I (Shift+i)"
echo "   To zainstaluje pluginy poprzez TPM."
echo "3) Po instalacji pluginów sesje będą automatycznie zapisywane i przywracane."
echo
echo "Podpowiedź: po restarcie komputera:"
echo "   - uruchom: tmux"
echo "   - tmux-continuum powinien automatycznie przywrócić poprzednie sesje."

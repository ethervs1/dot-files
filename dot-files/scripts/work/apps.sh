#!/bin/bash

echo "🚀 Iniciando entorno de trabajo..."

# 1. Abrir Microsoft Teams
echo "Opening Microsoft Teams..."
open -a "Microsoft Teams"

# 2. Abrir Slack
echo "Opening Slack..."
open -a "Slack"

# 3. Abrir VS Code apuntando a ~/git
echo "Opening VS Code en ~/git..."
if [ -d "$HOME/git" ]; then
    open -a "Visual Studio Code" "$HOME/git"
else
    echo "⚠️  La carpeta ~/git no existe, abriendo VS Code vacío."
    open -a "Visual Studio Code"
fi

# 4. Abrir Google Chrome con 3 perfiles diferentes
echo "Opening Google Chrome con 3 perfiles..."

# NOTA SOBRE CHROME: 
# macOS usa "Profile 1", "Profile 2", etc., o "Default" para el primer perfil.
# Asegúrate de revisar el nombre real de tus carpetas de perfil (ver instrucciones abajo).

# Chrome - Globant (Profile 1)
open -na "Google Chrome" --args \
  --profile-directory="Profile 1" \
  "https://mail.google.com/mail/u/0/#all" \
  "https://calendar.google.com/calendar/u/0/r" \
  "https://gemini.google.com/" \

sleep 2

# Chrome - Personal (Profile 2)
open -na "Google Chrome" --args \
  --profile-directory="Profile 2" \
  "https://mail.google.com/mail/u/0/#all"

sleep 2

# Chrome - Disney (Profile 3)
open -na "Google Chrome" --args \
  --profile-directory="Profile 3" \
  "https://sso.myid.disney.com/app/UserHome"

echo "✅ ¡Todo listo! Buen viaje de código."

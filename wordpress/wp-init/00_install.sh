#!/usr/bin/env bash
set -euo pipefail

# Espera a la base de datos
echo "⏳ Esperando a MySQL…"
until wp db check --path=/var/www/html >/dev/null 2>&1; do
  sleep 2
done
echo "✅ Base de datos lista"

# Si WP no está instalado, lo instala
if ! wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
  echo "⚙️  Instalando WordPress…"
  wp core install \
    --url="$WP_SITE_URL" \
    --title="$WP_SITE_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$(cat /run/secrets/wp_admin_pass)" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --path=/var/www/html
  echo "✅ WordPress instalado"

  # Ejemplos de plugins/temas que quieras activar
  wp plugin install classic-editor --activate --path=/var/www/html
  wp theme install astra --activate     --path=/var/www/html
fi

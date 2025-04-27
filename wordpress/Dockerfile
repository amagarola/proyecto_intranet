FROM wordpress:6.5-php8.2-apache

# Instalar WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Copiar script(s) de bootstrap
COPY wp-init/ /docker-entrypoint-initwp.d/

# 👉 Asegurar permisos de ejecución
RUN chmod +x /docker-entrypoint-initwp.d/*.sh

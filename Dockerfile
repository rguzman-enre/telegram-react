# --- Fase 1: Compilación ---
FROM node:16-alpine AS build
WORKDIR /app/

# Desactivar auditorías para acelerar el proceso
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_FUND=false

# Copiar archivos de dependencias
COPY package.json package-lock.json ./

# Forzar la instalación omitiendo el bloqueo estricto de tdweb
RUN npm install --legacy-peer-deps

# Copiar el resto del código del repositorio
COPY . .

# Mover los binarios indispensables de WebAssembly antes de compilar
RUN cp -v node_modules/tdweb/dist/* public/

# Declarar los argumentos de construcción que React necesita inyectar
ARG TELEGRAM_API_ID
ENV REACT_APP_TELEGRAM_API_ID=${TELEGRAM_API_ID}
ARG TELEGRAM_API_HASH
ENV REACT_APP_TELEGRAM_API_HASH=${TELEGRAM_API_HASH}

# Compilar el sitio web estático
RUN npm run build

# --- Fase 2: Servidor de Producción con Nginx ---
FROM nginx:stable-alpine

WORKDIR /usr/share/nginx/html/
COPY --from=build /app/build/ .

# Enlace simbólico requerido por la estructura interna de rutas de este proyecto
RUN ln -s . telegram-react

# Asegurar que el servidor Nginx responda correctamente en cualquier ruta interna
RUN echo 'server { listen 80; location / { root /usr/share/nginx/html; index index.html index.htm; try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

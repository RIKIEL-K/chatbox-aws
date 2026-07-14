
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --silent

COPY . .
RUN npm run build


FROM nginx:1.27-alpine


COPY nginx.conf /etc/nginx/templates/default.conf.template


COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# envsubst remplace ${API_GATEWAY_URL} dans le template au démarrage
# La variable est injectée par ECS via la task definition
CMD ["/bin/sh", "-c", "envsubst '${API_GATEWAY_URL}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]

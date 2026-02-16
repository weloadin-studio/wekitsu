# Stage 1: Build the Vite application
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --legacy-peer-deps
COPY . .
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine
# Copy built files to /opt/zou/kitsu as specified in nginx config
RUN mkdir -p /opt/zou/kitsu
COPY --from=builder /app/dist /opt/zou/kitsu
# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Stage 1: Build React application
FROM node:20-alpine AS build

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --frozen-lockfile

# Copy source code and build the app
COPY . .
RUN npm run build

# Stage 2: Serve React app with Nginx
FROM nginx:1.25-alpine

# Copy built app to Nginx HTML directory
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80 for the app
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]

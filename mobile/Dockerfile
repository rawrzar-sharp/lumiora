FROM node:18
WORKDIR /app
COPY package*.json ./
COPY assets/ ./assets/
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]

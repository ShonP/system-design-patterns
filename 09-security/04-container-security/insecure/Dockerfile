# Insecure Dockerfile — DO NOT COPY. Each line is a hands-on lesson.
FROM node:latest

WORKDIR /app
COPY . .

RUN apt-get update && apt-get install -y curl python3 build-essential

ENV API_KEY=sk_live_EXAMPLE_FAKE_KEY_FOR_LAB
ENV NODE_ENV=production

RUN npm install

EXPOSE 3000

CMD ["node", "server.js"]

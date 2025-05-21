FROM mcr.microsoft.com/playwright:v1.52.0-jammy

WORKDIR /app-test

COPY package*.json ./
RUN npm ci

COPY . ./

ENV NODE_ENV=production

CMD ["npm", "run", "test"]

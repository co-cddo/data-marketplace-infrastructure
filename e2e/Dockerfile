FROM mcr.microsoft.com/playwright:v1.52.0-jammy

WORKDIR /e2e

COPY package*.json ./
RUN npm ci

COPY . ./

ENV NODE_ENV=production

CMD ["npm", "run", "test"]

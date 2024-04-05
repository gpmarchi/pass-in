FROM node:20.11.1 as base
RUN npm install -g pnpm

FROM base as dependencies
WORKDIR /app
COPY ./package.json ./pnpm-lock.yaml ./
RUN pnpm install

FROM base as build
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN pnpm build
RUN pnpm prune --prod

FROM node:20.11.1-alpine3.19 as deploy
WORKDIR /app
RUN npm i -g pnpm prisma
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/prisma ./prisma
RUN pnpm prisma generate
ENV DATABASE_URL=file:./passin.db
ENV API_BASE_URL=http://localhost:3333
ENV PORT=3333
RUN pnpm prisma migrate deploy
EXPOSE 3333
CMD [ "pnpm", "start" ]
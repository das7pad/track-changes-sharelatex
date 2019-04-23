FROM node:6.11.2 as app

WORKDIR /app

#wildcard as some files may not be in all repos
COPY package*.json npm-shrink*.json /app/

RUN npm install --quiet

COPY . /app


RUN npm run compile:all

FROM node:6.11.2

WORKDIR /app

CMD ["node", "--expose-gc", "app.js"]


COPY --from=app /app /app

USER node

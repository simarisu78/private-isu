FROM node:lts-slim


WORKDIR /home/webapp

COPY app.js ./
COPY views ./views
COPY package.json ./

RUN npm install

EXPOSE 8080

CMD [ "node", "app.js" ]
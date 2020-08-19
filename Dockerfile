FROM node:14-alpine AS npm
COPY ui /ui
WORKDIR /ui
RUN npm install && npm run build

FROM golang:1.15-alpine AS go
COPY . /gohls
WORKDIR /gohls
RUN apk add --no-cache git
RUN cat internal/buildinfo/buildinfo.go.in | sed "s/##VERSION##/dictor-proto/g" | sed "s/##COMMIT##/$(git rev-parse HEAD)/g" | sed "s/##BUILD_TIME##/$(date +%s)/g" > internal/buildinfo/buildinfo.go
RUN CGO_ENABLED=0 go build -o gohls

FROM jrottenberg/ffmpeg:4.0-alpine
RUN mkdir /gohls/ui -p
COPY --from=go /gohls/gohls /gohls/
COPY --from=npm /ui/build /gohls/ui/build
WORKDIR /gohls
RUN apk add --no-cache libc6-compat
ENTRYPOINT ["/gohls/gohls", "serve", "--config", "config.json", "--listen", ":80"] 

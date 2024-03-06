FROM golang:alpine3.19 as builder

WORKDIR /builder

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .
RUN go build -o main

FROM scratch

WORKDIR /app

COPY --from=builder /builder/main ./
COPY static /var/www/static

CMD ["./main"]

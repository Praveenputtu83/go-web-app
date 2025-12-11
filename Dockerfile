FROM golang:1.24 AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o go-web-app .

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /app/go-web-app .
COPY static ./static
EXPOSE 8080
CMD ["./go-web-app"]

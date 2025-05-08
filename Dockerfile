FROM golang:1.24.2-alpine AS build
ARG VERSION="dev"

# Set the working directory
WORKDIR /build

# Install git
RUN --mount=type=cache,target=/var/cache/apk \
    apk add git

# Build the server
# go build automatically download required module dependencies to /go/pkg/mod
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=bind,target=. \
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION} -X main.commit=$(git rev-parse HEAD) -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -o /bin/github-mcp-server cmd/github-mcp-server/main.go

# Make a stage to run the app
FROM alpine:latest
# Set the working directory
WORKDIR /server
# Copy the binary from the build stage
COPY --from=build /bin/github-mcp-server .
# Ensure the binary is executable
RUN chmod +x /server/github-mcp-server
# Command to run the server
ENTRYPOINT ["/server/github-mcp-server"]
CMD ["stdio"]

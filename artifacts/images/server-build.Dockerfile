# Build the proxy-server binary
FROM golang:1.19.6 as builder

# Copy in the go src
WORKDIR /go/src/sigs.k8s.io/apiserver-network-proxy

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# This is required before go mod download because we have a
# replace directive for konnectivity-client in go.mod
# The download will fail without the directory present
COPY konnectivity-client/ konnectivity-client/

# Cache dependencies
RUN go mod download

# Copy the sources
COPY pkg/    pkg/
COPY cmd/    cmd/
COPY proto/  proto/

# Build
ARG ARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -a -ldflags '-extldflags "-static"' -o proxy-server sigs.k8s.io/apiserver-network-proxy/cmd/server

# Copy the loader into a thin image
FROM scratch
WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/apiserver-network-proxy/proxy-server .
ENTRYPOINT ["/proxy-server"]

# Use the official golang image to create a binary.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:1.23 as builder

# Create and change to the app directory.
WORKDIR /app

RUN go mod init invoke && \
    go mod tidy

# Copy local code to the container image.
COPY invoke.go ./

# Build the binary.
RUN go build -mod=readonly -v -o invoke

# Use a gcloud image based on debian:buster-slim for a lean production container.
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:slim

WORKDIR /app

RUN apt-get -y install jq
ENV PATH="/app/google-cloud-sdk/bin:${PATH}"

# Copy the binary to the production image from the builder stage.
COPY --from=builder /app/invoke /app/invoke
COPY update_labels.sh /app/
RUN chmod +x /app/*.sh

# Run the web service on container startup.
ENTRYPOINT ["/app/invoke"]
# Builder Stage / compiles contracts
FROM oven/bun:latest as build

# Define build arguments in the build stage
ARG VITE_CONTROLLER_CHAINID
ARG VITE_RPC_URL
ARG VITE_TORII_URL
ARG VITE_BURNER_ADDRESS
ARG VITE_BURNER_PRIVATE_KEY
ARG VITE_SLOT
ARG VITE_PROFILE

# Set environment variables in the build stage
ENV VITE_CONTROLLER_CHAINID=${VITE_CONTROLLER_CHAINID}
ENV VITE_RPC_URL=${VITE_RPC_URL}
ENV VITE_TORII_URL=${VITE_TORII_URL}
ENV VITE_BURNER_ADDRESS=${VITE_BURNER_ADDRESS}
ENV VITE_BURNER_PRIVATE_KEY=${VITE_BURNER_PRIVATE_KEY}
ENV VITE_SLOT=${VITE_SLOT}
ENV VITE_PROFILE=${VITE_PROFILE}

# Set workdir to the root of the project
WORKDIR /app

# Copy the entire monorepo
COPY . .

# Build the client package
WORKDIR /app/packages/client
RUN bun install
RUN bun run build:slot

# Runtime Stage
FROM oven/bun:slim as serve

WORKDIR /app

RUN bun install -g serve

ARG PORT=3000
ENV PORT=${PORT}

# Copy only the built client files
COPY --from=build /app/packages/client/dist /app

EXPOSE ${PORT}
CMD ["bunx", "--bun", "serve", "-s", "/app"] 
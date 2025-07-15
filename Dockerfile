# --- Final Optimized Dockerfile for LobeChat (v8 - The Official Method) ---

# --- STAGE 1: The Builder ---
# This stage builds the application using the official project scripts.
FROM node:18-alpine AS builder

# Set work directory
WORKDIR /app

# Install system dependencies needed for build and runtime
RUN apk add --no-cache bash cairo-dev jpeg-dev pango-dev giflib-dev librsvg-dev curl unzip

# Install pnpm package manager (as specified in package.json)
# LobeChat uses pnpm, so we use pnpm
RUN npm install -g pnpm

# Install the bun runtime (some scripts use it, e.g., db:migrate)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Copy dependency definition files
COPY package.json pnpm-workspace.yaml ./
COPY .npmrc ./
COPY packages ./packages

# Install project dependencies with pnpm
RUN pnpm install

# Copy all the application source code
COPY . .

# [关键变更] 使用官方指定的 Docker 构建脚本
# This is the correct, official way to build the project for Docker deployment.
# It handles pre-build steps and sets necessary environment variables.
RUN NODE_OPTIONS="--max-old-space-size=6144" pnpm run build:docker

# --- STAGE 2: The Production Image ---
# This stage creates the final, lightweight image for running the app.
FROM node:18-alpine

WORKDIR /app

# Install only the RUNTIME system dependencies.
# This makes the final image smaller and more secure.
RUN apk add --no-cache cairo-dev jpeg-dev pango-dev giflib-dev librsvg-dev

# Copy built assets and necessary files from the 'builder' stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json 
COPY --from=builder /app/public ./public
# The 'standalone' folder is often created by `next build` for optimized deployment
COPY --from=builder /app/standalone ./standalone

# [关键变更] 暴露项目 'start' 脚本中定义的正确端口
# The package.json specifies port 3210.
EXPOSE 3210

# [最终命令] 使用 npm start
# This is the canonical way to run a Node.js app.
# It will execute the "start": "next start -p 3210" script from package.json.
# npm automatically ensures the correct Node.js version and paths are used.
CMD ["npm", "start"]


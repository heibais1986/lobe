# --- The Definitive Dockerfile for LobeChat on GitHub Actions ---

# 使用一个包含 Node.js v18 和必要构建工具的基础镜像
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖，这是构建 @napi-rs/canvas 所必需的
RUN apk add --no-cache libcairo2-dev jpeg-dev pango-dev giflib-dev librsvg-dev

# 安装 pnpm
RUN npm install -g pnpm

# 复制依赖定义文件
COPY package.json pnpm-workspace.yaml ./

# 安装项目依赖
RUN pnpm install

# 复制所有源代码
COPY . .

# [★★★ 核心修复点 ★★★]
# 在执行构建命令时，直接为其注入 NODE_OPTIONS 环境变量。
# 这会强制 pnpm build (即 next build) 使用最高 6GB 的内存。
RUN NODE_OPTIONS="--max-old-space-size=6144" pnpm build

# --- 生产镜像 ---
# 使用一个更轻量的基础镜像来运行应用，减小最终镜像体积
FROM node:18-alpine

WORKDIR /app

# 再次安装系统依赖，但这次只需要运行时的，而不是构建时的
# 对于 LobeChat，@napi-rs/canvas 在运行时也需要 cairo 等库
RUN apk add --no-cache libcairo2-dev jpeg-dev pango-dev giflib-dev librsvg-dev

# 从构建器阶段复制必要的产物
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

# 暴露 LobeChat 的运行端口
EXPOSE 3010

# 定义容器启动时运行的命令
# 在生产环境中，我们使用 `next start` 而不是 `pnpm start`，这更标准且高效
CMD [ "npx", "next", "start", "-p", "3010" ]



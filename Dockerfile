# 使用一个包含 Node.js v18 的基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# [关键步骤] 安装系统依赖，为 @napi-rs/canvas 做准备
# 这里我们用 'apk' 是因为 'node:18-alpine' 这个基础镜像是基于 Alpine Linux 的
# RUN apk add --no-cache libcairo2-dev jpeg-dev pango-dev giflib-dev librsvg-dev

# 安装 pnpm 包管理器
RUN npm install -g pnpm

# 复制依赖定义文件
COPY package.json pnpm-workspace.yaml ./
COPY .npmrc ./
COPY packages ./packages

# 安装依赖
RUN pnpm install

# 复制应用的所有源代码
COPY . .

# 构建 LobeChat 应用
RUN pnpm build

# 暴露 LobeChat 的运行端口
EXPOSE 3010

# 定义容器启动时运行的命令
CMD [ "pnpm", "start" ]

# syntax=docker/dockerfile:1

# ============ 基础镜像：Python 3.12 (Debian slim) ============
FROM python:3.12-slim

# 日志实时输出、不生成 __pycache__
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# ---------- 安装 Node.js（>= 18，QuickJS sentinel 取 OTP 必需）----------
# 没有 node 只能过 sentinel 表层校验，OTP 邮件会被 silent-drop（200 但不下发），
# 导致卡在验证码等待。README 要求 Node >= 18，这里装 Node 20。
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---------- 先装 Python 依赖，利用 Docker 层缓存 ----------
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# ---------- 拷贝源码 ----------
COPY . .

EXPOSE 8765

# 直接用 uvicorn 跑 FastAPI（绕过 start_webui.py 的自动开浏览器 / 自动装依赖）
CMD ["uvicorn", "webui.app:app", "--host", "0.0.0.0", "--port", "8765"]

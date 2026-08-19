#!/usr/bin/env bash
# 检查 fitness-plan-agent 第二层抓取（下载视频 + 关键帧读图 + 音频转写）需要的本地依赖。
# 用法：bash scripts/check_deps.sh

set -u
ok=1

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✅ $1：已安装 ($(command -v "$1"))"
  else
    echo "❌ $1：未安装"
    ok=0
  fi
}

echo "== 命令行工具 =="
check_cmd ffmpeg
check_cmd ffprobe
check_cmd whisper-cli
check_cmd curl

echo
echo "== Whisper 语音模型 =="
MODEL="$HOME/.whisper-models/ggml-small.bin"
if [ -f "$MODEL" ]; then
  size=$(du -h "$MODEL" | cut -f1)
  echo "✅ 模型文件存在：${MODEL}（${size}）"
else
  echo "❌ 模型文件不存在：${MODEL}"
  ok=0
fi

echo
if [ "$ok" -eq 1 ]; then
  echo "全部依赖就绪，可以直接使用第二层抓取（下载视频+关键帧读图+音频转写）。"
else
  echo "缺少依赖，安装方式："
  echo "  brew install ffmpeg whisper-cpp"
  echo "  mkdir -p ~/.whisper-models"
  echo "  curl -sL \"https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin\" -o ~/.whisper-models/ggml-small.bin"
  echo
  echo "不装也没关系：Skill 会自动退回官方字幕/网页文案抓取，最后退回问你要截图，"
  echo "只是拿不到画面里烧录字幕、也没有配音讲解那类视频的细节。"
fi

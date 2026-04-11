#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# System: Overlayd-AI Integrated Automation Framework
# Description: Installs and provisions a fully isolated, offline AI
#              agent environment within the Termux compatibility layer.
#              Links the Llama.cpp inference engine to both a Node.js 
#              Telegram interface and the OpenClaw execution environment.
# =========================================================================

set -e

# ==========================================
# 1. Environment & Hardware Diagnostics
# ==========================================
echo "Initiating Overlayd-AI Framework Installation..."
echo "Note: Setup might take up to 30 minutes depending on your phone's processor and internet speed."
echo "Securing critical storage permissions (Please accept the popup if it appears)..."
termux-setup-storage
sleep 2

echo "Running system diagnostics..."
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
ARCH=$(uname -m)

echo "Detected Architecture: ${ARCH}"
echo "Detected Total Memory: ${TOTAL_RAM} MB"

if [ "$TOTAL_RAM" -lt 6000 ]; then
    echo "Warning: System memory is below 6GB. Using large models may result in severe system degradation and memory thrashing."
fi

# ==========================================
# 2. Intelligent Shizuku Auto-Installer
# ==========================================
if [ ! -f "$PREFIX/bin/rish" ]; then
    echo ""
    echo "========================================================"
    echo "⚠️ CRITICAL REQUIREMENT: SHIZUKU (rish) ⚠️"
    echo "========================================================"
    echo "Your AI cannot physically control your phone without Shizuku."
    echo "Do you want to configure it right now, or skip and do it later?"
    echo "1) Setup Now (Recommended)"
    echo "2) Skip (Bot will lack phone control until manually configured)"
    read -p "Select option (1/2): " SHIZUKU_CHOICE

    if [ "$SHIZUKU_CHOICE" == "1" ]; then
        echo ""
        echo "--- SHIZUKU SETUP INSTRUCTIONS ---"
        echo "1. Install 'Shizuku' from the Play Store & start via Wireless Debugging."
        echo "2. Open Shizuku -> tap 'Use Shizuku in terminal apps' -> 'Export files'."
        echo "3. Create a new folder named 'Shizuku' in your phone's main storage."
        echo "4. Export the files strictly into that 'Shizuku' folder."
        echo ""
        read -p "Press [Enter] ONLY after you have successfully exported the files..."
        
        if ls /sdcard/Shizuku/rish* 1> /dev/null 2>&1; then
            cp /sdcard/Shizuku/rish* $PREFIX/bin/
            chmod +x $PREFIX/bin/rish
            echo "✅ Success! 'rish' was detected in the Shizuku folder and automatically installed!"
        else
            echo "⚠️Warning: 'rish' files were not found in /sdcard/Shizuku/."
            echo "You will need to manually copy them later. Proceeding with text-only setup..."
        fi
    else
        echo "Skipping Shizuku setup. Proceeding..."
    fi
fi

# ==========================================
# 3. Configuration Prompts
# ==========================================
echo ""
echo "Select Target Inference Model:"
echo "1) Qwen2-VL-2B (Target: Vision-capable. Recommended for <8GB Memory)"
echo "2) Llama-3.2-1B (Target: Lightweight text processing) [GATED]"
echo "3) Gemma-2-2B-IT(Target: High-end reasoning) [GATED]"
read -p "Select corresponding index (1/2/3): " MODEL_INDEX

case "$MODEL_INDEX" in
    1)
        PRIMARY_URL="https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/Qwen2-VL-2B-Instruct-Q4_K_M.gguf"
        PRIMARY_FILE="qwen2-vl-2b-q4.gguf"
        VISION_URL="https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/mmproj-Qwen2-VL-2B-Instruct-f16.gguf"
        VISION_FILE="qwen2-vl-mmproj.gguf"
        ;;
    2)
        PRIMARY_URL="https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
        PRIMARY_FILE="llama-3.2-1b-q4.gguf"
        VISION_URL=""
        VISION_FILE=""
        ;;
    3)
        PRIMARY_URL="https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
        PRIMARY_FILE="gemma-2-2b-it-q4.gguf"
        VISION_URL=""
        VISION_FILE=""
        ;;
    *)
        echo "Error: Invalid model index selected. Terminating sequence."
        exit 1
        ;;
esac

echo ""
echo "If you selected Llama or Gemma, they are 'gated' models. You must "
echo "have accepted their terms on HuggingFace, and provide an Access Token."
echo "(If you selected Qwen, you can just press Enter to skip this)"
read -p "Input HuggingFace Token (hf_...): " HF_TOKEN

echo ""
echo "The system requires a Telegram Bot Profile to establish the external command bridge."
read -p "Input Telegram Bot Token: " TELEGRAM_TOKEN
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo "Warning: No token provided. Linking internal fallback flag."
    TELEGRAM_TOKEN="TOKEN_NOT_PROVIDED"
fi

# ==========================================
# 4. Environment Preparation
# ==========================================
echo ""
echo "Updating and downloading compilation dependencies..."
pkg update -y
pkg install clang cmake nodejs python wget git libandroid-spawn make -y

# ==========================================
# 5. Core Engine Procurement
# ==========================================
echo "Cloning Llama.cpp engine repository..."
cd $HOME
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp
fi

# ==========================================
# 6. Model Procurement & Authentication
# ==========================================
echo "Downloading target inference weights..."
mkdir -p "$HOME/llama.cpp/models"
cd "$HOME/llama.cpp/models"

# Temporarily disable exit-on-error so we can catch wget 401s gracefully
set +e

echo "Validating payload permissions and downloading architecture..."
if [ -n "$HF_TOKEN" ] && [ "$HF_TOKEN" != "TOKEN_NOT_PROVIDED" ]; then
    wget --header="Authorization: Bearer $HF_TOKEN" -c "$PRIMARY_URL" -O "$PRIMARY_FILE"
    WGET_STATUS=$?
else
    wget -c "$PRIMARY_URL" -O "$PRIMARY_FILE"
    WGET_STATUS=$?
fi

if [ $WGET_STATUS -ne 0 ]; then
    echo ""
    echo "========================================================"
    echo "❌ CRITICAL ERROR: Model download failed! (HTTP 401/403/404)"
    echo "========================================================"
    echo "You most likely provided an invalid HuggingFace token,"
    echo "or you have not 'Accepted the Terms' on the repository page."
    echo "Terminating script early to save compilation time."
    echo "Please fetch a valid token and try again."
    echo "========================================================"
    exit 1
fi

if [ -n "$VISION_URL" ]; then
    echo "Downloading optical projector sub-module..."
    if [ -n "$HF_TOKEN" ] && [ "$HF_TOKEN" != "TOKEN_NOT_PROVIDED" ]; then
        wget --header="Authorization: Bearer $HF_TOKEN" -c "$VISION_URL" -O "$VISION_FILE"
    else
        wget -c "$VISION_URL" -O "$VISION_FILE"
    fi
fi

# Re-enable strict error catching
set -e

# ==========================================
# 7. Engine Compilation (Intensive Load)
# ==========================================
echo "Compiling Llama.cpp inference engine natively..."
echo "Notice: This requires heavy CPU cycles and may take several minutes."
cd $HOME/llama.cpp

rm -rf build/
export LDFLAGS="-landroid-spawn"
cmake -B build -DLLAMA_BUILD_SERVER=ON -DLLAMA_BUILD_TESTS=OFF
cmake --build build --config Release --target llama-server

# ==========================================
# 8. OpenClaw Linking
# ==========================================
echo "Installing OpenClaw Vision Processor framework..."
wget -q "https://github.com/nethacksalot/OpenClaw/releases/download/latest/openclaw-linux-${ARCH}" -O "$PREFIX/bin/openclaw" 2>/dev/null || echo "Notice: Standard OpenClaw binary unavailable for this architecture."
chmod +x "$PREFIX/bin/openclaw" 2>/dev/null || true

cat << EOF > $PREFIX/bin/openclaw-local
#!/data/data/com.termux/files/usr/bin/bash
export OPENAI_BASE_URL="http://127.0.0.1:8080/v1"
export OPENAI_API_KEY="local-bypass"
export OPENAI_MODEL="local-model"

echo "Initializing OpenClaw Framework mapped to local inference backbone..."
openclaw
EOF
chmod +x $PREFIX/bin/openclaw-local

# ==========================================
# 9. Offline Coding Machine Integration
# ==========================================
echo "Installing Edge Computing AI Developers (Aider & OpenClaude)..."

# Python/Aider (Industry standard pair-programmer for LLMs)
pkg install python -y >/dev/null 2>&1 || true
pip install aider-chat >/dev/null 2>&1 || true

# Node/OpenClaude Wrapper
npm install -g @gitlawb/openclaude >/dev/null 2>&1 || true

# Constructing Local Override Launchers
cat << EOF > $PREFIX/bin/aider-local
#!/data/data/com.termux/files/usr/bin/bash
export OPENAI_API_BASE="http://127.0.0.1:8080/v1"
export OPENAI_API_KEY="local-bypass"
echo "Initializing Aider linked to local Llama.cpp engine..."
aider --model openai/local-model "\$@"
EOF
chmod +x $PREFIX/bin/aider-local

cat << EOF > $PREFIX/bin/openclaude-local
#!/data/data/com.termux/files/usr/bin/bash
export OPENAI_BASE_URL="http://127.0.0.1:8080/v1"
export OPENAI_API_KEY="local-bypass"
export ANTHROPIC_API_KEY="local-bypass"
export ANTHROPIC_BASE_URL="http://127.0.0.1:8080/v1"
echo "Initializing OpenClaude linked to local Llama.cpp engine..."
openclaude "\$@"
EOF
chmod +x $PREFIX/bin/openclaude-local

# ==========================================
# 10. Bridge Protocol Generation
# ==========================================
echo "Configuring Node.js interaction logic..."
cd $HOME
if [ ! -f "package.json" ]; then
    npm init -y > /dev/null
fi
npm install node-telegram-bot-api > /dev/null

cat << 'EOF' > $HOME/telegram_bot.js
const TelegramBot = require('node-telegram-bot-api');
const { exec } = require('child_process');

const token = process.env.TELEGRAM_TOKEN || 'OVERLAYD_INJECT_TOKEN';
const bot = new TelegramBot(token, {polling: true});

bot.on('message', async (msg) => {
  const chatId = msg.chat.id;
  if (!msg.text || msg.text.startsWith('/')) return;
  bot.sendMessage(chatId, "Processing input request.");

  const rawPrompt = `System: You are an autonomous system administration agent. Output Android system commands (CMD:) or direct text replies (MSG:). Output must be concise and literal.

User: query process status
PhoneBot: MSG: Returning system parameters.

User: open youtube
PhoneBot: CMD: monkey -p com.google.android.youtube 1

User: disable wireless networking
PhoneBot: CMD: svc wifi disable

User: invoke dark mode profiles
PhoneBot: CMD: cmd uimode night yes

User: return to primary home screen
PhoneBot: CMD: input keyevent 3

User: launch application background switcher
PhoneBot: CMD: input keyevent 187

User: capture optical state
PhoneBot: CMD: screencap -p /sdcard/screenshot.png

User: ${msg.text.trim()}
PhoneBot:`;

  try {
    const response = await fetch("http://127.0.0.1:8080/v1/completions", {
        method: "POST", headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
            prompt: rawPrompt,
            temperature: 0.1,
            max_tokens: 300,
            stop: ["\nUser:", "User:"]
        })
    });
    
    if (!response.ok) throw new Error("Inference failure.");
    
    const data = await response.json();
    let reply = data.choices[0].text.trim();
    
    if (reply.startsWith('CMD:')) {
        let command = reply.replace('CMD:', '').trim();
        bot.sendMessage(chatId, "Executing localized system parameters.");
        
        const finalCmd = `bash /data/data/com.termux/files/usr/bin/rish -c "export PATH=/sbin:/system/sbin:/system/bin:/system/xbin; ${command.replace(/"/g, '\\"')}"`;
        exec(finalCmd, (error) => {
            if (error) {
                if (error.code === 127 || error.message.includes("not found")) {
                    bot.sendMessage(chatId, "Task failed. 'rish' executable not found. Ensure Shizuku is configured and exported to Termux.");
                } else {
                    bot.sendMessage(chatId, "Task execution failed. Verify Shizuku is actively running in the background.");
                }
            } else {
                bot.sendMessage(chatId, "Task executed successfully.");
            }
        });
    } else {
        let outMsg = reply.replace('MSG:', '').trim();
        bot.sendMessage(chatId, outMsg);
    }
  } catch (e) {
    bot.sendMessage(chatId, "Service offline. Backend linkage terminated.");
  }
});
console.log("Overlayd-AI Bridge running. Awaiting input array.");
EOF

sed -i "s/OVERLAYD_INJECT_TOKEN/$TELEGRAM_TOKEN/g" $HOME/telegram_bot.js

# ==========================================
# 10. Start-Sequence Architecting
# ==========================================
echo "Finalizing standard execution architecture..."
cat << EOF > $HOME/start-overlayd.sh
#!/data/data/com.termux/files/usr/bin/bash
echo "Initiating Overlayd-AI Systems..."
cd ~/llama.cpp

if [ "$MODEL_INDEX" == "1" ]; then
    ./build/bin/llama-server -m models/${PRIMARY_FILE} --mmproj models/${VISION_FILE} -t 4 -c 4096 --port 8080 > ~/overlayd_server.log 2>&1 &
else
    ./build/bin/llama-server -m models/${PRIMARY_FILE} -t 4 -c 2048 --port 8080 > ~/overlayd_server.log 2>&1 &
fi

OVERLAYD_PID=\$!

echo "Allocating inference model into system memory..."
sleep 15

echo "Starting Telegram listener port..."
cd ~
node telegram_bot.js

echo "Termination requested. Unloading inference model."
kill \$OVERLAYD_PID
EOF
chmod +x $HOME/start-overlayd.sh

echo ""
echo "Installation structure successfully resolved."
echo "Execute the system sequence via the following command:"
echo "bash ~/start-overlayd.sh"
echo "--------------------------------------------------------"
echo "To execute computer vision autonomously run:    openclaw-local"
echo "To utilize the phone as a 24/7 coding machine:  aider-local OR openclaude-local"
echo "--------------------------------------------------------"
echo "System deployment finished."
echo "If you found this setup useful, please consider subscribing to 'orailnoor' on YouTube!"

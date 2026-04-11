# Edge Overlay AI

Run Large Language Models entirely natively on your Android device with system-level control.

This tool automatically provisions a fully isolated, offline AI agent environment within the Termux compatibility layer. It links a native `llama.cpp` inference engine to an automated Shizuku-based execution environment, allowing the AI to actually control your Android device.

---

## Technical Walkthrough & Demonstration
For a full visual guide on how to install and utilize this execution environment, please reference the official deployment video:
**📺 [Watch the Setup Guide on YouTube](https://youtu.be/Y5xmT28xoTA)**

---

## Features
- **Zero Cloud Dependence**: Runs 100% locally on your smartphone processing hardware.
- **Hardware Diagnostics**: Dynamically scales and configures models based on available system memory.
- **System Control**: Bypasses conventional Android constraints using Shizuku to let the AI tap, swipe, and alter settings locally.
- **Vision Integration**: Automates compatibility and configuration for OpenClaw UI interactions natively.

---

## Comprehensive Setup Guide

### 1. Termux Preparation
You must install the official execution environment for Android.
- **Download**: Install the official application strictly from F-Droid (the Google Play Store version is heavily outdated and missing necessary source dependencies). Download here: [Termux on F-Droid](https://f-droid.org/packages/com.termux/).
- **Initialize**: Open Termux and run the following command to bootstrap the package manager:
  ```bash
  apt update && apt upgrade -y
  ```

### 2. Shizuku Configuration (System Control)
Shizuku is required to securely bypass the internal Android application sandbox. Without this service, your AI will not have the native authority to execute system commands.
1. Install **Shizuku** from the Google Play Store.
2. Enable **Developer Options** on your Android device (tap "Build Number" 7 times under Settings > About Phone).
3. Inside Developer Options, enable **Wireless Debugging**.
4. Open the Shizuku application, select **Pairing**, and follow the on-screen instructions to authorize the service using an Android pairing code.
5. Tap **Start** to initiate the background service.

### 3. Telegram Bridge (Authentication)
A Telegram Bot is utilized to establish the communication bridge to your AI engine.
1. Open your Telegram app and search for the `@BotFather`.
2. Send the `/newbot` command and follow the prompts to establish a localized name and username.
3. The BotFather will generate an HTTP API Token (e.g., `123456789:ABCdefGHI...`). Ensure you copy this token, as it will be explicitly required during the script initialization.

### 4. Hugging Face Access (Model Weights)
If you elect to deploy highly gated reasoning models such as Google's *Gemma* or Meta's *Llama*, you must procure a cloud access token.
1. Create an account at [Hugging Face](https://huggingface.co).
2. Navigate to the repository of the desired model (e.g., `google/gemma-2-2b-it`) and explicitly click to accept their licensing terms.
3. Access your Hugging Face **Settings > Access Tokens**.
4. Generate a new token with "Read" permissions and copy it for the script initialization. *(Note: Ungated models like Qwen or Phi do not require this step).*

---

## Installation
Once the preliminary requirements are satisfied, deploy the full compilation shell within Termux:
```bash
wget https://raw.githubusercontent.com/orailnoor/edge-overlay-ai/main/overlayd-ai.sh
bash overlayd-ai.sh
```

Follow interactive prompts to execute the unified structure.

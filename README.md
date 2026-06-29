# 🛡️ Sentinela-AI

> Hybrid on-device deepfake detection pipeline combining **Behavioural Pattern Recognition (CNN)** with **Physical Signal Analysis (8×8 Matrix)** — running natively on Android with zero cloud dependency.

![Android](https://img.shields.io/badge/Platform-Android-green?style=flat-square&logo=android)
![Flutter](https://img.shields.io/badge/UI-Flutter-blue?style=flat-square&logo=flutter)
![TFLite](https://img.shields.io/badge/Model-TFLite%20INT8-orange?style=flat-square&logo=tensorflow)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)
![NIT Delhi](https://img.shields.io/badge/MTech-NIT%20Delhi%202025-purple?style=flat-square)

---

## The Problem

Single-model detectors are fundamentally broken:

- **CNNs trained on GANs** → blind against Midjourney / Stable Diffusion
- **Physics-based detectors** → miss traditional StyleGAN face-swaps
- **Whole-image analysis** → a 2.2% AI face composited into a real
  background gets buried by authentic background noise
  *(Global Variance Dilution Problem)*

---

## Architecture: Three-Layer Hybrid Defense

```
Input Image
    │
    ▼
┌─────────────────────────────────────────┐
│ Layer 1 — Cryptographic Scan            │
│  C2PA manifest · SynthID watermark      │
│  → Instant classification if found      │
└────────────────────┬────────────────────┘
                     │ cascade if absent
                     ▼
┌─────────────────────────────────────────┐
│ Layer 2 — Behavioural CNN               │
│  MobileNetV2 · 140k faces · TFLite INT8 │
│  → p_CNN score (GAN artefact detection) │
└────────────────────┬────────────────────┘
                     │ cascade if p_CNN < 0.80
                     ▼
┌─────────────────────────────────────────┐
│ Layer 3 — Physical Signal Matrix ★      │
│  8×8 YCbCr Cb-channel variance grid     │
│  Bayer Sensor Noise + SED tiebreaker    │
│  → Cumulative Integrity Score (CIS)     │
└─────────────────────────────────────────┘
                     │
                     ▼
        🟢 Verified / 🟡 Caution / 🔴 AI Detected
```

### Layer 3: The Core Innovation

Divides each image into **64 independent blocks (8×8 grid)**.  
Within each block, measures Bayer Sensor Noise via Cb-channel variance:

```
Cb = 128 − 0.168736R − 0.331264G + 0.5B    (ITU-R BT.601)

σ²_b = (1/N) Σ(Cb_i − μ_b)²               (per-block variance)
```

| Image Type   | σ²_Cb (typical) |
|--------------|-----------------|
| Real camera  | 10 – 45         |
| AI-generated | 0.8 – 3.5       |

This solves the **face-swap dilution problem**: instead of one global
variance (which the real background dominates), each block is judged
independently — exposing the AI face even when it covers < 3% of pixels.

---

## Results

| Threat            | Layer 2 (CNN) | Layer 3 (Matrix) | Verdict           |
|-------------------|---------------|------------------|-------------------|
| StyleGAN2         | ✅ p=0.91      | Confirms CIS=0.74 | 🔴 AI Detected    |
| Midjourney v5     | ❌ p=0.19      | ✅ CIS=0.71       | 🔴 AI Detected    |
| Face-swap composite | ⚠️ p=0.62   | ✅ CIS=0.51       | 🟡 Caution        |
| Authentic photo   | ✅ p=0.07      | ✅ CIS=0.08       | 🟢 Verified       |

---

## Performance

| Device                   | CNN    | Matrix | Total  |
|--------------------------|--------|--------|--------|
| Snapdragon 8 Gen 2       | 28 ms  | 41 ms  | 85 ms  |
| Snapdragon 778G (mid)    | 54 ms  | 94 ms  | 165 ms |
| Snapdragon 680 (budget)  | 112 ms | 189 ms | 320 ms |

- Model size: **3.5 MB** (MobileNetV2 INT8 quantised)
- Cloud calls: **0**

---

## Tech Stack

| Layer       | Technology                                       |
|-------------|--------------------------------------------------|
| CNN Training | Python · TensorFlow/Keras · Google Colab GPU    |
| On-device ML | TFLite INT8 · NNAPI delegate · Java TFLite API  |
| Signal Engine | Native Android Java · Bitmap API · Parallel threads |
| UI          | Flutter 3.x / Dart · CustomPainter heatmap      |
| Metadata    | Custom C2PA binary stream parser (Java NIO)     |
| Automation  | Android WorkManager + FileObserver (Sentinel Mode) |

---

## Features

- 🔍 **3-layer cascade** — C2PA → CNN → Physical Matrix
- 🧠 **MobileNetV2 CNN** — fine-tuned on 140k+ deepfake faces
- 📐 **8×8 YCbCr Matrix** — Bayer noise + Strong Edge Density tiebreaker
- 📊 **Flutter dashboard** — real-time block heatmap + CIS score
- 🔔 **Sentinel Mode** — background folder monitoring + push alerts
- 📵 **Zero cloud** — full on-device Android execution

---

## Project Structure

```
sentinela-ai/
├── android/
│   ├── PhysicalSignalMatrix.java   ← 8×8 YCbCr variance engine
│   ├── CNNInferenceEngine.java     ← TFLite MobileNetV2 wrapper
│   └── C2PAScanner.java            ← binary stream metadata parser
├── lib/
│   ├── dashboard/                  ← Flutter CIS dashboard
│   ├── heatmap/                    ← 8×8 block visualizer
│   └── sentinel/                   ← background monitoring
├── model/
│   └── sentinela_mobilenetv2.tflite
└── research/
    └── Sentinela_AI_MTech_Report.pdf
```

---

## Setup

```bash
# Clone
git clone https://github.com/arun-kumar/sentinela-ai.git
cd sentinela-ai

# Install Flutter dependencies
flutter pub get

# Build for Android
flutter build apk --release
```

---

## Research

This project is a **2nd-year MTech research project** at NIT Delhi.  
Full technical report available in `/research/`.

Key references: Corvi et al. (2023), Rossler et al. (2019),
Cozzolino & Verdoliva (2020), Frank et al. (2020), Wang et al. (2020).

---

## Team

| Name | Role |
|------|------|
| **Arun Kumar** | Lead Developer |


**Supervisor:** Dr. Anurag singh, Associate Professor, CSE  
**Institution:** National Institute of Technology Delhi  
**Duration:** July – December 2025

---

## License

MIT License — see [LICENSE](LICENSE)

---

*If this helps your research, give it a ⭐ and reach out!*

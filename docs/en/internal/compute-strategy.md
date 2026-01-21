# 🧠 Compute Strategy: Local vs GitHub Actions

This document defines which tasks to run locally and which to leverage from
public runners or GPU containers in GitHub Actions.

---

## ⚖️ Decision matrix

| Task | Resources | Risk | ⚙️ Local | ☁️ GitHub Actions |
|------|-----------|------|----------|------------------|
| 🧪 YAML/Python tests | Low (CPU) | Low | ✅ | ✅ |
| 🧠 SpaCy analysis | Medium (RAM) | Medium | ✅ | ✅ |
| 🧬 ML training | High (GPU) | High | ⚠️ Limited | ✅ (Docker GPU) |
| 🎯 Batch analysis | High (CPU threads) | Medium | ⚠️ | ✅ |
| 📦 Docker build | Medium | Low | ✅ | ✅ |
| 📤 GitOps auto-push | Low | High | ✅ | 🚫 |
| 🔍 CodeQL/Rego scan | Medium | High | ✅ | ✅ |

---

## 🧭 General rules

- **Local**: Fast iterative tests, credential control, controlled GitOps
- **GitHub Actions**: Public validation, heavy training, GPU testing

---

## 🔐 Security
- Never push `.env` or local keys
- GitOps push requires manual validation or GPG signing from dev
- Use GitHub Secrets for API/cloud access

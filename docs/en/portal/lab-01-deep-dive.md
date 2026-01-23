# Lab 01: Deep Dive - Secure Pipeline Baseline

Welcome to the first real challenge of the **Cognitive Suite**. This Lab is not just a software test; it is your gateway to **Cognitive Sovereignty**.

## 🧠 Philosophy: Learn by Doing
In this Lab, you will transform a plain text document into **Structured Cognitive Capital**. You will learn how local AI can protect your privacy while extracting value from your data.

## 🛠️ Prerequisites
Before starting, make sure you have your "superpowers" installed:
- [x] Active virtual environment.
- [x] Dependencies installed (`pip install -r requirements.txt`).
- [x] AI model downloaded (`python -m spacy download es_core_news_md`).

---

## 🚀 Step by Step: The Data Lifecycle

### 1. Ingestion (Preparing the Raw Material)
Create a file at `data/input/my_lab.txt` with sensitive content (names, budgets, emails). Then, "present it" to the Suite:
```powershell
python cogctl.py ingest my_lab.txt
```
*Why? Because the system must centralize and normalize files before analyzing them.*

### 2. Secured Analysis (The Brain of the Suite)
Run the pipeline activating the **Redaction** layer:
```powershell
$env:COGNITIVE_REDACT="1"; python cogctl.py analyze
```
*This is where spaCy looks for entities, Transformers analyze sentiment, and our rules block financial leaks.*

### 3. Instant Validation (Feedback Loop)
Use our validation tool to see if you have met the technical objectives:
```powershell
python cogctl.py verify
```
*If you see all green checks, you have successfully configured the AI and Privacy engine!*

---

## 🏆 Extra Challenges (For Advanced Talent)
If you want to prove that you understand the system as well as its creator, try this:

1. **The Multi-Tag**: Write a text that forces the AI to put 4 or more tags (e.g., talking about an idea, a legal risk, and a pending action).
2. **Extreme Sentiment**: Try to write a text that gets a sentiment `score` greater than 0.85. What keywords "excite" the AI the most?
3. **The Dashboard**: Open Streamlit (`streamlit run frontend/streamlit_app.py`) and verify that characters (like the € symbol) look perfect thanks to our UTF-8 improvement.

## 📝 Evidence for your PR
For your team to validate this Lab, your Pull Request must include:
1. The resulting `outputs/insights/analysis.json` file.
2. The audit logs in `outputs/audit/analysis.jsonl`.
3. A screenshot of your Dashboard with the redacted data.

---
> [!IMPORTANT]
> Remember that in this project **evidence rules over opinion**. If there are no logs, there is no Lab.

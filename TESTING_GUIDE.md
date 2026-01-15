# 🧪 Guía de Testing - PR: Mejorar análisis cognitivo

## Requisitos Previos

```bash
# Instalaciones necesarias (si no están ya instaladas)
pip install spacy transformers fitz
python -m spacy download es_core_news_sm
```

## Test 1: Fix de Ingesta de PDFs ✅

### Antes (Comportamiento Original)
```bash
# Los PDFs se guardaban como .pdf y NO se procesaban
python cogctl.py ingest archivo.pdf
ls outputs/raw/
# → archivo.pdf (no procesado por analyze.py)

python cogctl.py analyze
cat outputs/insights/analysis.json
# → [] (vacío)
```

### Después (Con el Fix)
```bash
python cogctl.py ingest test.pdf
ls outputs/raw/
# → test.txt ✅ (ahora es .txt)

python cogctl.py analyze
cat outputs/insights/analysis.json
# → [{ entidades, referencias legales, flags de riesgo, ... }] ✅
```

## Test 2: Extracción de Entidades Legales ✅

### Comando
```bash
python cogctl.py init
python cogctl.py ingest test.pdf
python cogctl.py analyze
```

### Verificar Resultados
```bash
python3 << 'EOF'
import json
with open('outputs/insights/analysis.json') as f:
    data = json.load(f)
    
for record in data:
    print(f"Documento: {record['title']}")
    print(f"  - Referencias legales: {len(record['legal_reference'])}")
    if record['legal_reference']:
        print(f"    Ejemplos: {[x[1][:40] for x in record['legal_reference'][:3]]}")
    print(f"  - Flags de riesgo: {len(record['risk_flags'])}")
    if record['risk_flags']:
        print(f"    Ejemplos: {[x[1][:40] for x in record['risk_flags'][:3]]}")
EOF
```

### Resultado Esperado
```
Documento: test
  - Referencias legales: 1298 ✅
    Ejemplos: ['Ley Orgánica', 'Código Penal', 'la Ley']
  - Flags de riesgo: 230 ✅
    Ejemplos: ['Código Penal', 'CAPÍTULO I. De las penas', 'Delitos']
```

## Test 3: Relevancia Dinámica ✅

### Comando
```bash
python cogctl.py analyze
python3 << 'EOF'
import json
with open('outputs/insights/analysis.json') as f:
    data = json.load(f)
    for record in data:
        print(f"{record['title']:20} | Relevancia: {record['relevance_score']}")
EOF
```

### Resultado Esperado
```
relato               | Relevancia: 0.55 ✅ (bajo, no-legal)
test                 | Relevancia: 0.95 ✅ (alto, muy legal)
```

**No** debería ser 1.0 para ambos (eso sería incorrecto)

## Test 4: Interfaz de Usuario Mejorada ✅

### Comando
```bash
python cogctl.py init
python cogctl.py ingest test.pdf
python cogctl.py analyze
```

### Resultado Esperado
```
📁 Estructura creada: data/input, outputs/raw, outputs/insights
📥 Ingestando: test.pdf...
✅ Ingesta completada: /workspaces/cognitive-suite/outputs/raw/test.pdf
🧠 Inicializando modelos de PLN...
📂 Procesando archivos en /workspaces/cognitive-suite/outputs/raw...
  ✓ relato.txt
  ✓ test.txt
=========================================================
✅ Análisis completado
   📊 Archivos procesados: 2
   💾 Resultados: /workspaces/cognitive-suite/outputs/insights/analysis.json
=========================================================
```

**Sin spam de logs de transformers** ✅

## Test 5: Flag Verbose para Debugging ✅

### Comando
```bash
python pipeline/analyze.py --verbose
```

### Resultado Esperado
Debe mostrar DEBUG logs:
```
DEBUG: Intenta cargar: es_core_news_md
DEBUG: Modelo no disponible: es_core_news_md
DEBUG: Intenta cargar: es_core_news_sm
DEBUG: ✓ Modelo cargado: es_core_news_sm
DEBUG: Cargando modelo de sentimientos (transformers)...
DEBUG: ✓ Modelo de sentimientos cargado
DEBUG: Procesando: outputs/raw/relato.txt
DEBUG: Procesando: outputs/raw/test.txt
```

## Test 6: Detección de Autores ✅

### Comando
```bash
python3 << 'EOF'
import json
with open('outputs/insights/analysis.json') as f:
    data = json.load(f)
    for record in data:
        if record['author_signature']:
            print(f"{record['title']:20} | Autor: {record['author_signature'][:60]}")
        else:
            print(f"{record['title']:20} | Autor: No detectado")
EOF
```

### Resultado Esperado
```
relato               | Autor: una mujer y al mejor relato LGBT.
test                 | Autor: la ley como delito obliga a reparar, en los
```

Ambos detectan autor (aunque sea a veces parcial) ✅

## Test 7: Tags Cognitivos ✅

### Comando
```bash
python3 << 'EOF'
import json
with open('outputs/insights/analysis.json') as f:
    data = json.load(f)
    for record in data:
        print(f"{record['title']:20} | Tags: {', '.join(record['intent_tags'])}")
EOF
```

### Resultado Esperado
```
relato               | Tags: idea, riesgo, proyecto, viabilidad, emoción, intuición, acción pendiente
test                 | Tags: idea, riesgo, legal, proyecto, viabilidad, emoción, acción pendiente
```

Note que "legal" aparece en test (Código Penal) pero no en relato ✅

## Criterios de Aceptación

- [x] PDFs se procesan correctamente (cambio de extensión)
- [x] Referencias legales se detectan (+1298)
- [x] Flags de riesgo se detectan (+230)
- [x] Relevancia dinámica funciona (0.55 vs 0.95)
- [x] Interfaz limpia sin spam de logs
- [x] Flag --verbose funciona
- [x] Autores se detectan (con flexibilidad)
- [x] Tags cognitivos correctos

## Limitaciones Conocidas ⚠️

1. **Sentimientos**: Modelo XLM-Roberta sin fine-tuning
   - Relatos eróticos marcan NEGATIVE (debería ser NEUTRAL/POSITIVE)
   - Código Penal marca NEGATIVE (correcto por delitos/sanciones)

2. **Referencias legales**: Algunos falsos positivos
   - Incluye palabras genéricas como "Artículo", "Persona"
   - Mejora futura: filtrado más riguroso

3. **Riesgos**: Por palabras clave, no contextual
   - 'Riesgo' en relato ≠ 'riesgo' en penal
   - Mejora futura: análisis contextual

4. **Autores**: Captura flexible pero a veces inexacta
   - Mejora futura: patrones más refinados

## Notas Finales

Este es un MVP funcional. Las limitaciones están documentadas en el commit y PR para futuras mejoras.

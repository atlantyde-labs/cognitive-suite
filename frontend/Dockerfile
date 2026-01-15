FROM python:3.10-slim

# Instalar dependencias específicas de la interfaz. Copiamos el
# ``requirements.txt`` de la raíz del proyecto para instalar las
# bibliotecas necesarias (incluyendo streamlit y rich).
WORKDIR /app
COPY ../requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copiar los archivos de la interfaz dentro del contenedor
COPY frontend/ /app/

# Exponer el puerto usado por Streamlit
EXPOSE 8501

# Por defecto ejecutamos la aplicación de Streamlit. Si se desea
# ejecutar la interfaz de consola (`app.py`) se puede sobrescribir
# ``command`` en docker-compose.
CMD ["streamlit", "run", "streamlit_app.py", "--server.headless=true", "--server.port=8501"]

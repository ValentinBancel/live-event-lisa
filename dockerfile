FROM astral/uv:python3.12-bookworm-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1 \
    PORT=8000

# Create and set the work directory
WORKDIR /app

# Copy dependency list and install dependencies
COPY uv.lock /app/
COPY pyproject.toml /app/

# Install dependencies using uv
RUN uv sync --frozen --no-cache

# Copy the entire project
COPY . /app/

# Create directory for static files
RUN mkdir -p /app/staticfiles

# Collect static files
RUN uv run python manage.py collectstatic --noinput

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port 8000
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD uv run python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/docs/').read()" || exit 1

# Start gunicorn (migrations must be run separately)
CMD ["sh", "-c", "uv run gunicorn mspr2_api.wsgi:application --bind 0.0.0.0:${PORT} --workers 4 --timeout 120 --access-logfile - --error-logfile -"]
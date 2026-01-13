FROM astral/uv:python3.12-bookworm-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1 \
    PORT=8000

# Create and set the work directory
WORKDIR /app

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Copy dependency list and install dependencies
COPY --chown=appuser:appuser uv.lock pyproject.toml /app/

# Switch to non-root user for dependency installation
USER appuser

# Install dependencies using uv
RUN uv sync --frozen --no-cache

# Copy the entire project
COPY --chown=appuser:appuser . /app/

# Create directory for static files
RUN mkdir -p /app/staticfiles

# Collect static files
RUN uv run python manage.py collectstatic --noinput

# Expose port 8000
EXPOSE 8000

# Health check - use Python's urllib for lightweight healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/', timeout=2)" || exit 1

# Start application - run migrations then start gunicorn
CMD ["sh", "-c", "uv run python manage.py migrate --noinput && uv run gunicorn mspr2_api.wsgi:application --bind 0.0.0.0:${PORT} --workers 4 --timeout 120 --access-logfile - --error-logfile -"]
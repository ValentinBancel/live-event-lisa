FROM astral/uv:python3.12-bookworm-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1

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

# Expose port 8000
EXPOSE 8000

# Run migrations and start gunicorn
CMD ["sh", "-c", "uv run python manage.py migrate && uv run gunicorn mspr2_api.wsgi:application --bind 0.0.0.0:8000 --workers 4"]
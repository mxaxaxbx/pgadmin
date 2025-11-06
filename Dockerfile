FROM dpage/pgadmin4:latest

USER root

ENV PORT=8080

# Patch pgAdmin to skip chmod on SQLite database
RUN sed -i 's/os\.chmod(config\.SQLITE_PATH, 0o600)/pass  # Disabled for Cloud Storage/' /pgadmin4/pgadmin/__init__.py

# Switch back to pgadmin user
USER pgadmin

EXPOSE ${PORT}

VOLUME /var/lib/pgadmin

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin.pgAdmin4:app"]
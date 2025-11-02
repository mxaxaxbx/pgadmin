FROM dpage/pgadmin4:latest

ENV PORT=8080

EXPOSE ${PORT}

VOLUME /var/lib/pgadmin

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin.pgAdmin4:app"]

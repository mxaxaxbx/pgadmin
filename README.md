# pgAdmin 4 Docker Setup

A Docker-based setup for running pgAdmin 4, a web-based administration tool for PostgreSQL databases.

## Overview

This project provides a containerized pgAdmin 4 instance that can be easily deployed using Docker Compose. The setup includes:

- pgAdmin 4 web interface
- Persistent data storage
- Health check monitoring
- Automatic restart on failure

## Prerequisites

- Docker Engine (version 20.10 or later)
- Docker Compose (version 2.0 or later)
- A `.env` file with required environment variables (see Configuration section)

## Quick Start

1. **Create a `.env` file** in the project root with the following variables:

```env
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=your_secure_password
PGADMIN_CONFIG_SERVER_MODE=False
```

2. **Start the service**:

```bash
docker-compose up -d
```

3. **Access pgAdmin**:

Open your browser and navigate to `http://localhost:8080`

4. **Log in** using the credentials specified in your `.env` file.

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `PGADMIN_DEFAULT_EMAIL` | Default login email for pgAdmin | Yes |
| `PGADMIN_DEFAULT_PASSWORD` | Default login password for pgAdmin | Yes |
| `PGADMIN_CONFIG_SERVER_MODE` | Server mode configuration (False for standalone) | Optional |

### Additional Configuration

You can add more pgAdmin environment variables as needed. Refer to the [official pgAdmin documentation](https://www.pgadmin.org/docs/) for a complete list of configuration options.

## Features

### Port Mapping

- **Host Port**: `8080`
- **Container Port**: `8080`

Access the pgAdmin interface at `http://localhost:8080`

### Data Persistence

pgAdmin data is persisted in a Docker volume (`pgadmin_data`) mounted at `/var/lib/pgadmin`. This ensures that your server registrations, settings, and configurations are preserved across container restarts.

### Health Checks

The container includes a health check that:
- Runs every 30 seconds
- Checks the pgAdmin ping endpoint
- Has a 10-second timeout
- Allows 3 retries before marking unhealthy
- Provides a 40-second startup grace period

### Auto-restart

The container is configured to restart automatically unless explicitly stopped.

## Usage

### Starting the Service

```bash
docker-compose up -d
```

### Stopping the Service

```bash
docker-compose down
```

To remove volumes as well:

```bash
docker-compose down -v
```

### Viewing Logs

```bash
docker-compose logs -f pgadmin
```

### Checking Status

```bash
docker-compose ps
```

## Connecting to PostgreSQL Servers

Once pgAdmin is running:

1. Log in using your credentials
2. Right-click on "Servers" in the browser panel
3. Select "Register" → "Server"
4. Enter your PostgreSQL server details:
   - **Host**: Your PostgreSQL host (use `host.docker.internal` for Docker Desktop, or the container/service name for Docker Compose networks)
   - **Port**: PostgreSQL port (default: 5432)
   - **Database**: Database name
   - **Username**: PostgreSQL username
   - **Password**: PostgreSQL password

## Troubleshooting

### Container Won't Start

- Verify that port 8080 is not already in use
- Check that your `.env` file exists and contains required variables
- Review logs: `docker-compose logs pgadmin`

### Cannot Connect to PostgreSQL

- Ensure your PostgreSQL server is accessible from the container
- For Docker Compose: Use the service name as the hostname
- For Docker Desktop: Use `host.docker.internal` as the hostname
- Check firewall and network settings

### Password Issues

- Verify your `.env` file has the correct `PGADMIN_DEFAULT_PASSWORD` value
- Ensure there are no extra spaces or quotes in the `.env` file

## Project Structure

```
.
├── Dockerfile          # pgAdmin 4 container definition
├── docker-compose.yml  # Docker Compose configuration
├── .env               # Environment variables (create this)
└── README.md          # This file
```

## Docker Compose Commands Reference

| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start services in detached mode |
| `docker-compose down` | Stop and remove containers |
| `docker-compose logs -f` | Follow log output |
| `docker-compose ps` | List running services |
| `docker-compose restart` | Restart services |
| `docker-compose stop` | Stop services without removing |

## Security Notes

- **Never commit your `.env` file** to version control
- Use strong, unique passwords
- Consider using Docker secrets or environment variable management tools for production
- Ensure your Docker host firewall is properly configured
- Only expose port 8080 to trusted networks

## License

This setup uses the official pgAdmin 4 Docker image. Please refer to the [pgAdmin license](https://www.pgadmin.org/license/) for licensing information.

## Resources

- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [pgAdmin GitHub](https://github.com/pgadmin-org/pgadmin4)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Support

For issues related to:
- **pgAdmin functionality**: Visit [pgAdmin Support](https://www.pgadmin.org/support/)
- **Docker setup**: Check Docker and Docker Compose documentation
- **This project**: Open an issue in the project repository

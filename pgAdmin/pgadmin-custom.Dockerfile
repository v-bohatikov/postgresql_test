FROM dpage/pgadmin4:9

# Copy config files with correct ownership
COPY --chown=pgadmin:pgadmin config/servers.json /pgadmin4/servers.json
COPY --chown=pgadmin:pgadmin config/.pgpass /pgadmin4/.pgpass

# Ensure correct permissions
RUN chmod 600 /pgadmin4/.pgpass
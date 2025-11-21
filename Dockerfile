FROM postgres:15

# Install build tools and PostgreSQL development headers
RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-server-dev-15 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for extension development
WORKDIR /extension

# Copy extension source code
COPY . /extension/

# Build and install the extension
RUN make && make install

# Switch back to postgres user
USER postgres

# Expose PostgreSQL port
EXPOSE 5432

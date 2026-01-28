# --- STAGE 1: Node Build ---
ARG NODE_VERSION
ARG TOMCAT_VERSION

FROM node:${NODE_VERSION} AS build_stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Assuming your build creates a 'dist' folder or a WAR
RUN npm run build 

# --- STAGE 2: Tomcat + SSH ---
FROM tomcat:${TOMCAT_VERSION}
# Install Node.js so we can run NestJS
RUN apt-get update && apt-get install -y \
    curl \
    openssh-server \
    python3 \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Standard SSH setup for Ansible
RUN mkdir /var/run/sshd && \
    echo 'root:password123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy your NestJS build (dist) into a specific folder
COPY --from=build_stage /app/dist /app/nest-app
COPY --from=build_stage /app/node_modules /app/node_modules

RUN mkdir -p /app/nest-app/config

# We still use Tomcat's folder for your Ansible-rendered config
RUN mkdir -p /app/nest-app/config

EXPOSE 3000 8080 22
CMD ["sh", "-c", "/usr/sbin/sshd; node /app/nest-app/main.js & catalina.sh run"]
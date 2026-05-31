# ==========================================================================
# ELITE XAUUSD COGNITIVE GATEWAY - DOCKER CONTAINER DEPLOYMENT
# Base Image: Node.js 20 on lightweight Alpine Linux
# Security Profile: Enforced unprivileged USER context (Non-Root)
# ==========================================================================

FROM node:20-alpine

# Enforce production flags
ENV NODE_ENV=production

# Configure isolated working directory
WORKDIR /usr/src/app

# Copy package descriptor
COPY package.json ./

# Copy all application assets cleanly
COPY . .

# Secure container by shifting from root execution to unprivileged node user
USER node

# Expose bridge port
EXPOSE 3000

# Execute server
CMD ["node", "server.js"]

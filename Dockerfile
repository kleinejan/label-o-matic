# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /app
# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    openscad \
    xvfb \
    libglu1-mesa \
    libxrender1 \
    libxcb1 \
    libx11-xcb1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*


# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy app files
COPY . .

RUN cp ./fonts/* /usr/share/fonts/

# Expose the port your app runs on
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]
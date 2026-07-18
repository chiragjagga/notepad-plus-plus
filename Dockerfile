# Start from the official C++ language base image (Debian-based)
FROM gcc:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies:
# - mingw-w64: To compile Windows binaries
# - wine & wine64: Windows compatibility layer to execute notepad++.exe
# - xvfb: Virtual framebuffer to run Wine GUI headlessly
# - python3-pip & python3-setuptools: For running pytest and the XML validator
RUN apt-get update && apt-get install -y --no-install-recommends \
    mingw-w64 \
    wine64 \
    wine \
    xvfb \
    python3-pip \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Wine and Xvfb display
ENV DISPLAY=:99
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64

# Install Python packages required for testing
RUN pip3 install --no-cache-dir \
    pytest \
    lxml \
    requests

# Create and set workspace directory to /app
WORKDIR /app

# Auto-start Xvfb server in bash sessions so Wine has an active display buffer
RUN echo "Xvfb :99 -screen 0 1024x768x16 &" >> /root/.bashrc

# End with standard bash shell CMD
CMD ["/bin/bash"]

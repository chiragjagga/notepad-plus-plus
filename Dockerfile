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
    xauth \
    python3-pip \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Wine and Xvfb display
ENV DISPLAY=:99
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install Python packages required for testing
RUN pip3 install --no-cache-dir \
    pytest \
    lxml \
    requests

# Create and set workspace directory to /app
WORKDIR /app

# Copy the repository source files into the container
COPY . .

# Run the pre-build generator script using Wine/Xvfb to create version headers
RUN xvfb-run wine cmd.exe /C "PowerEditor/src/NppLibsVersionH-generator.bat"

# Compile the Notepad++ application using MinGW cross-compiler
RUN make -C PowerEditor/gcc -f makefile CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc AR=x86_64-w64-mingw32-ar RC=x86_64-w64-mingw32-windres PREBUILD_EVENT_CMD="true" -j$(nproc)

# Auto-start Xvfb server in bash sessions so Wine has an active display buffer
RUN echo "Xvfb :99 -screen 0 1024x768x16 &" >> /root/.bashrc

# End with standard bash shell CMD
CMD ["/bin/bash"]

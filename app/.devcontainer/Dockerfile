# Use a standard Ubuntu base image for stability
FROM ubuntu:22.04

# --- Environment Configuration ---
# Set paths for Flutter and Android SDKs, mirroring the devcontainer.json
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_ROOT=/usr/local/sdk/flutter
ENV ANDROID_HOME=/usr/local/lib/android/sdk
# Add Flutter, Android platform-tools, and cmdline-tools to PATH
ENV PATH="${FLUTTER_ROOT}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# --- Installation Steps ---

# 1. Install core dependencies (Java 17, Curl, Git, Unzip)
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk curl git unzip wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Flutter SDK (Stable Channel)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_ROOT && \
    # Ensure necessary permissions and run precache for all platforms
    chmod -R 777 $FLUTTER_ROOT && \
    $FLUTTER_ROOT/bin/flutter precache

# 3. Install Android Command-Line Tools
# Download and install the latest command line tools
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O android_tools.zip && \
    unzip -q android_tools.zip -d $ANDROID_HOME/cmdline-tools && \
    # Move directory for correct path setup (must be 'latest')
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm android_tools.zip

# 4. Install necessary Android SDK components (API 34 is modern standard)
# This includes platform-tools, the platform image, and build-tools
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 5. Accept Android licenses (Crucial step, mimics the postCreateCommand)
RUN yes | sdkmanager --licenses

# Set working directory to the project root (where your code will be copied)
WORKDIR /app

# Default command for the container
CMD ["/bin/bash"]

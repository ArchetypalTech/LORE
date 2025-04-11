FROM --platform=linux/amd64 debian:bullseye

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to bash
SHELL ["/bin/bash", "-c"]

# Install basic dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  file \
  git \
  procps \
  wget \
  unzip \
  apt-transport-https \
  ca-certificates \
  gnupg \
  sudo \
  zsh \
  && rm -rf /var/lib/apt/lists/*

# Install Homebrew
RUN useradd -m -s /bin/bash linuxbrew && \
  echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
WORKDIR /home/linuxbrew

# Install Homebrew
RUN mkdir -p ~/.cache && \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Add Bun to PATH
ENV PATH="/home/linuxbrew/.bun/bin:${PATH}"

# Verify installations
RUN echo "Homebrew version:" && brew --version && \
  echo "Bun version:" && bun --version

# Switch back to root for any additional setup
USER root
WORKDIR /root

# Create a non-root user for better security (optional, but recommended)
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create user with checks for existing GID/UID
RUN if getent group $USER_GID > /dev/null 2>&1; then \
  groupadd --gid $((USER_GID+1000)) $USERNAME; \
  else \
  groupadd --gid $USER_GID $USERNAME; \
  fi \
  && if id -u $USER_UID > /dev/null 2>&1; then \
  useradd --uid $((USER_UID+1000)) --gid $(getent group $USERNAME | cut -d: -f3) -m $USERNAME; \
  else \
  useradd --uid $USER_UID --gid $(getent group $USERNAME | cut -d: -f3) -m $USERNAME; \
  fi \
  && apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up user environment
USER $USERNAME
WORKDIR /home/$USERNAME

# Add Homebrew and Bun to user's PATH
RUN echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc && \
  echo 'export PATH="/home/linuxbrew/.bun/bin:$PATH"' >> ~/.bashrc

# Install ASDF with Homebrew
USER linuxbrew
RUN brew install --build-from-source asdf

# Set up ASDF in bashrc
RUN echo '. "$(brew --prefix asdf)/libexec/asdf.sh"' >> ~/.bashrc

# Switch back to dev user
USER $USERNAME

# Create an entrypoint script to run the mounted workspace's entrypoint
RUN echo '#!/bin/bash\n\
  # Check if the workspace entrypoint script exists and run it\n\
  if [ -f "/.devcontainer/entrypoint.sh" ]; then\n\
  echo "Running workspace entrypoint script..."\n\
  chmod +x /.devcontainer/entrypoint.sh\n\
  /.devcontainer/entrypoint.sh\n\
  elif [ -f "/workspaces/*/\.devcontainer/entrypoint.sh" ]; then\n\
  ENTRYPOINT_SCRIPT=$(find /workspaces -name "entrypoint.sh" -path "*/.devcontainer/*" | head -n 1)\n\
  echo "Found workspace entrypoint script at $ENTRYPOINT_SCRIPT"\n\
  chmod +x "$ENTRYPOINT_SCRIPT"\n\
  "$ENTRYPOINT_SCRIPT"\n\
  else\n\
  echo "No workspace entrypoint script found."\n\
  fi\n\
  \n\
  # Continue with the provided command\n\
  exec "$@"' > /home/$USERNAME/entrypoint.sh && \
  chmod +x /home/$USERNAME/entrypoint.sh

# Default command
ENTRYPOINT ["/home/dev/entrypoint.sh"]
CMD ["bash"]
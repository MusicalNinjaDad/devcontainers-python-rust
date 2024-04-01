FROM docker.io/library/fedora

# Enable man pages by commenting out the nodocs flag
COPY <<EOF /etc/dnf/dnf.conf
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
# tsflags=nodocs
EOF

# ---
# Install ...
# ---

# Basic development tools
RUN dnf -y --setopt=install_weak_deps=False install \
    git \
    man \
    man-db \
    man-pages \
    which

# Python
RUN dnf -y install \
    python \
    python-pip \
    python-pytest

# Rust (and python headers)
ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH
RUN dnf -y install \
    clang \
    python3-devel \
    rustup \
&& rustup-init -v -y \
&& rustup component add rust-src

# pyo3 specifics
RUN dnf -y install \
    nox \
&& cargo install cargo-llvm-cov


# ---
# Final setup steps
# ---

# Make CARGO_HOME accessible to all
RUN chmod a+w -R $CARGO_HOME

# Create the default user - most agents mount workspace directory chowned to 1000:1000
ARG USERNAME=pyo3
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} \
&& useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
&& echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
&& chmod 0440 /etc/sudoers.d/${USERNAME}

# Set the default user
USER ${USERNAME}

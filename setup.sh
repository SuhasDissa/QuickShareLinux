
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ! -r /etc/os-release ]]; then
    echo "Error: cannot detect Linux distribution." >&2
    exit 1
fi

source /etc/os-release

if [[ $EUID -eq 0 ]]; then
    SUDO=()
else
    command -v sudo >/dev/null 2>&1 || {
        echo "Error: sudo is required." >&2
        exit 1
    }
    SUDO=(sudo)
fi

install_packages() {
    "${SUDO[@]}" "$@"
}

case "${ID:-}" in
    ubuntu|debian)
        install_packages apt-get update
        install_packages apt-get install -y \
            build-essential \
            cmake \
            ninja-build \
            pkg-config \
            qt6-base-dev \
            qt6-declarative-dev \
            qt6-tools-dev \
            libabsl-dev \
            libprotobuf-dev \
            protobuf-compiler \
            libssl-dev \
            libsdbus-c++-dev \
            nlohmann-json3-dev \
            libcurl4-openssl-dev \
            libsystemd-dev \
            libbluetooth-dev \
            bluez
        ;;

    fedora)
        install_packages dnf install -y \
            gcc-c++ \
            cmake \
            ninja-build \
            pkgconf-pkg-config \
            qt6-qtbase-devel \
            qt6-qtdeclarative-devel \
            qt6-qttools-devel \
            abseil-cpp-devel \
            protobuf-devel \
            protobuf-compiler \
            openssl-devel \
            sdbus-cpp-devel \
            nlohmann-json-devel \
            libcurl-devel \
            systemd-devel \
            bluez-libs-devel \
            bluez
        ;;

    arch|cachyos)
        install_packages pacman -Syu --needed \
            base-devel \
            cmake \
            ninja \
            qt6-base \
            qt6-declarative \
            qt6-tools \
            abseil-cpp \
            protobuf \
            openssl \
            sdbus-cpp \
            nlohmann-json \
            curl \
            systemd \
            bluez-libs \
            bluez
        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Install the dependencies manually." >&2
        exit 1
        ;;
esac

# Check minimum CMake version.
cmake_version=$(cmake --version | awk 'NR == 1 {print $3}')
if ! printf '%s\n' 3.24 "$cmake_version" |
    sort -V -C; then
    echo "Error: CMake 3.24 or newer is required; found $cmake_version." >&2
    exit 1
fi

# Check for a C++ compiler with C++20 support.
compiler=""
for candidate in c++ g++ clang++; do
    if command -v "$candidate" >/dev/null 2>&1; then
        compiler="$candidate"
        break
    fi
done

if [[ -z "$compiler" ]]; then
    echo "Error: no C++ compiler found." >&2
    exit 1
fi

printf 'int main() {}\n' |
    "$compiler" -std=c++20 -x c++ -fsyntax-only - || {
        echo "Error: $compiler does not support C++20." >&2
        exit 1
    }

echo "Build dependencies installed."
echo "CMake: $cmake_version"
echo "C++ compiler: $compiler"
echo "Run CMake configuration to check the remaining dependencies."

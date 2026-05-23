#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[prerequisites] %s\n' "$*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_pkg() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  elif need_cmd sudo; then
    sudo "$@"
  else
    log "Root privileges are required to install packages: $*"
    exit 1
  fi
}

install_macos() {
  if ! need_cmd brew; then
    log 'Homebrew is required on macOS. Install Homebrew first, then rerun this script.'
    exit 1
  fi

  log 'Installing TeX and PDF tools with Homebrew'
  brew install --cask mactex-no-gui
  brew install latexmk ghostscript poppler make

  local texbin="/Library/TeX/texbin"
  if [ -d "$texbin" ] && [[ ":$PATH:" != *":$texbin:"* ]]; then
    log "Add $texbin to your PATH if latexmk is not available in new shells"
  fi
}

install_apt() {
  log 'Installing packages with apt'
  run_pkg apt-get update
  run_pkg apt-get install -y make latexmk texlive-full ghostscript poppler-utils
}

install_dnf() {
  log 'Installing packages with dnf'
  run_pkg dnf install -y make latexmk texlive-scheme-full ghostscript poppler-utils
}

install_pacman() {
  log 'Installing packages with pacman'
  run_pkg pacman -Sy --noconfirm make latexmk texlive-most ghostscript poppler
}

install_zypper() {
  log 'Installing packages with zypper'
  run_pkg zypper --non-interactive install make latexmk texlive-scheme-full ghostscript poppler-tools
}

install_linux() {
  if need_cmd apt-get; then
    install_apt
  elif need_cmd dnf; then
    install_dnf
  elif need_cmd pacman; then
    install_pacman
  elif need_cmd zypper; then
    install_zypper
  else
    log 'Unsupported Linux package manager. Supported managers: apt, dnf, pacman, zypper.'
    exit 1
  fi
}

main() {
  case "$(uname -s)" in
    Darwin)
      install_macos
      ;;
    Linux)
      install_linux
      ;;
    *)
      log "Unsupported operating system: $(uname -s)"
      exit 1
      ;;
  esac

  log 'Done. You can now run: make pdf or make pack'
}

main "$@"

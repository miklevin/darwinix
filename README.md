
      ____                      _       _                        .--.      ___________
     |  _ \  __ _ _ ____      _(_)_ __ (_)_  __    ,--./,-.     |o_o |    |     |     |
     | | | |/ _` | '__\ \ /\ / / | '_ \| \ \/ /   / #      \    |:_/ |    |     |     |
     | |_| | (_| | |   \ V  V /| | | | | |>  <   |          |  //   \ \   |_____|_____|
     |____/ \__,_|_|    \_/\_/ |_|_| |_|_/_/\_\   \        /  (|     | )  |     |     |
                                                   `._,._,'  /'\_   _/`\  |     |     |
     Solving the "Not on my machine" problem well.           \___)=(___/  |_____|_____|

# Nix Flake for Cross-Platform Development Environment

**Darwinix**, for the win! Or would that be *Darwin* for the Apple Unix? Or would that
be *star-nix* for Unix/Linux-like OSes? Or would that be *nix* for the NixOS package
manager that makes this IaC stuff so effective? Yes! It's **Infrastructure as Code**
provided by the Docker-killing dark horse of the Web, the package manager, *nix*!

## It Works on My Machine (be it Mac, Linux or Windows)

Most modern development is done on Linux, but Macs are Unix. If you think
Homebrew and Docker are the solution, you're wrong. Welcome to the world of **Nix
Flakes**! This file defines a complete, reproducible development environment. It's
like a recipe for your perfect workspace, ensuring everyone on your team has the
exact same setup, every time. As a bonus, you can use Nix flakes on Windows
under WSL, and whatever you make will be deployable to the cloud.

# This Darwinix Repo

This Nix flake defines a reproducible development environment that works across
Linux, macOS, and Windows (via WSL). It addresses several common development
challenges:

## Key Features

1. **Cross-platform compatibility**: Works on Linux, macOS, and Windows (WSL).
2. **Reproducibility**: Ensures consistent development environments across team members.
3. **CUDA support**: Automatically detects and configures CUDA on supported systems.
4. **Python environment**: Sets up a virtual environment with pip and required packages.
5. **JupyterLab integration**: Provides easy-to-use scripts for starting and stopping JupyterLab.
6. **Customizable**: Allows for easy addition or removal of packages as needed.

## Benefits

- Eliminates "works on my machine" problems
- Simplifies onboarding of new team members
- Ensures consistent deployment environments
- Reduces configuration drift over time
- Automates setup of complex tools like CUDA

## Usage

1. Install Nix with flakes enabled
2. Clone this repository
3. Run `nix develop` in the project directory

This setup replaces the need for manual environment configuration, Dockerfiles,
or OS-specific scripts, providing a unified solution for development environment
management.

## Understanding the Nix Flake

You can view the complete Nix flake configuration at
[https://github.com/miklevin/darwinix/blob/main/flake.nix](https://github.com/miklevin/darwinix/blob/main/flake.nix).
Here's a brief guide to understanding its structure:

- `commonPackages`: Defines software packages installed on both macOS and Linux hosts.
- `linuxDevShell`: Specifies the development environment for Linux systems.
- `darwinDevShell`: Defines the environment for macOS systems.
- `runScript`: A common script executed at the end of both Linux and macOS
  setups, establishing a Python-based Jupyter Notebooks data science environment.

This multi-OS approach, including Windows support via WSL, demonstrates the
power of **Nix flakes** in creating truly cross-platform development environments.
By examining the flake, you can appreciate how it handles different operating
systems while maintaining a consistent core setup.

## Development Flexibility

This Nix flake is not intended to be the definitive configuration for your
projects; rather, it serves as a foundational starting point for a
Python-centric data science platform. It includes all the necessary C-related
dependencies for building pip packages that may not have pre-built wheels and
can still be compiled from source. Plus, if you've got the accelerated Nvidia
GPU CUDA capable hardware, it uses it.

### Like a Server, But Better

Additionally, this setup provides enough infrastructure to run background
processes, such as web servers, in a way that mimics service behavior without
actually running them as systemd services. This approach allows you to monitor
and debug these processes directly in tmux terminals, which is particularly
useful during development. Unlike traditional service management, where
processes are detached and managed by systemd, this method enables you to log in
and interact with the running processes, making it easier to troubleshoot issues
and observe their behavior in real-time. This flexibility is crucial for
developers who need to iterate quickly and maintain visibility into their
applications while they are being built and tested.


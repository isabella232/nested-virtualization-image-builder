# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.222.0/containers/codespaces-linux/.devcontainer/base.Dockerfile

FROM mcr.microsoft.com/vscode/devcontainers/universal:1-focal

USER root

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

RUN RELEASE=$(curl https://api.github.com/repos/hashicorp/packer/releases/latest | jq -r .tag_name[1:]) \
  && curl -L "https://releases.hashicorp.com/packer/${RELEASE}/packer_${RELEASE}_linux_amd64.zip" -o /tmp/packer.zip \
  && unzip /tmp/packer.zip -d /usr/local/bin \
  && rm /tmp/packer.zip

USER codespace

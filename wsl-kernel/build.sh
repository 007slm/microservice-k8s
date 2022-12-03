docker run --name wsl-kernel-builder --rm -it ubuntu:latest bash

WSL_COMMIT_REF=linux-msft-5.4.72 # change this line to the version you want to build

# Install dependencies
apt update
#kube-proxy iptables 依赖
apt install -y git build-essential flex bison libssl-dev libelf-dev bc

#ebpf 依赖
apt-get install flex bison libssl-dev libelf-dev dwarves


# Checkout WSL2 Kernel repo
mkdir src
cd src
git init
git remote add origin https://github.com/microsoft/WSL2-Linux-Kernel.git
git config --local gc.auto 0
#2022-11-28采用的版本
git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +${WSL_COMMIT_REF}:refs/remotes/origin/build/linux-msft-wsl-5.4.y
git checkout --progress --force -B build/linux-msft-wsl-5.4.y refs/remotes/origin/build/linux-msft-wsl-5.4.y



# Enable xt_recent kernel module
sed -i 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=y/' Microsoft/config-wsl

# Compile the kernel
make -j2 KCONFIG_CONFIG=Microsoft/config-wsl

# From the host terminal copy the newly built kernel
docker cp wsl-kernel-builder:/src/arch/x86/boot/bzImage .
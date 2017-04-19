#!/bin/bash
#############################################################################
log()
{
	echo "$1"
}

usage() { echo "Usage: $0 [-d <0|1>]" 1>&2; exit 1; }

while getopts :d: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    d)  # docker
		export CHAINERONDOCKER=${OPTARG}
		;;
	*)
		usage
		;;
  esac
done

base_pkgs_ubuntu()
{
	log "base_pkgs"
	apt-get update
	apt-get install -y g++
}

setup_python_ubuntu()
{
	log "setup_python_ubuntu"
	apt-get install -y python3-pip
	echo "alias python=/usr/bin/python3" >> ~/.bash_aliases
	apt-get install -y build-essential libssl-dev libffi-dev python3-dev
	pip3 install --upgrade pip
}

setup_cuda8_ubuntu()
{
	log "setup_cuda8_ubuntu"
	apt-get install -y linux-headers-$(uname -r)
	curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	dpkg -i cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	apt-get update
	apt-get install -y cuda

	nvidia-smi

	echo "export CUDA_PATH=/usr/local/cuda" >> ~/.bashrc
	echo "export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}" >> ~/.bashrc
}

setup_numpy()
{
	log "setup_numpy"
	pip3 install numpy
}

setup_cudnn()
{
	log "setup_cudnn"
	curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v5.1/cudnn-8.0-linux-x64-v5.1.tgz -O
	tar -xzf cudnn-8.0-linux-x64-v5.1.tgz -C /usr/local
	rm cudnn-8.0-linux-x64-v5.1.tgz
}

setup_chainer()
{
	log "setup_chainer"
	pip3 install chainer -vvvv
}

# from https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Azure
nvidia_drivers_ubuntu()
{
	log "nvidia_drivers_ubuntu"
	# Install official NVIDIA driver package
	apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
	sh -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
	apt-get update && apt-get install -y --no-install-recommends cuda-drivers
}


# from https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Azure
nvidia_docker()
{
	log "nvidia_docker"
	# Install nvidia-docker and nvidia-docker-plugin
	wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
	dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
}

SETUP_MARKER=/var/local/chainer-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

nvidia_drivers_ubuntu

if [ "$CHAINERONDOCKER" == "1" ]; then
	nvidia_docker
else
	base_pkgs_ubuntu
	setup_python_ubuntu
	setup_cuda8_ubuntu
	setup_numpy
	setup_cudnn
	setup_chainer
fi

# Create marker file so we know we're configured
touch $SETUP_MARKER

shutdown -r +1 &
exit 0

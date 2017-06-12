#!/bin/bash
#############################################################################
log()
{
	echo "$1"
}

usage() { echo "Usage: $0 [-m ] " 1>&2; exit 1; }

while getopts :m: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    m)  # master name
		export CHAINER_MN=${OPTARG}
		;;
	*)
		usage
		;;
  esac
done

is_ubuntu()
{
	python -mplatform | grep -qi Ubuntu
	return $?
}

is_centos()
{
	python -mplatform | grep -qi CentOS
	return $?
}

check_docker()
{
	log "check if docker is installed"
	docker
	if [ $? -eq 0 ]
	then
		export CHAINERONDOCKER=1
	else
		export CHAINERONDOCKER=0
	fi
}

base_pkgs()
{
	log "base_pkgs"
	if is_ubuntu; then
		base_pkgs_ubuntu
	elif is_centos; then
		base_pkgs_centos
	fi
}

base_pkgs_ubuntu()
{
	DEBIAN_FRONTEND=noninteractive apt-mark hold walinuxagent
	DEBIAN_FRONTEND=noninteractive apt-get update
	apt-get install -y g++
}

base_pkgs_centos()
{
	# don't do update as it will break the NVidia drivers
	#yum -x WALinuxAgent -y update
	yum -y install gcc-c++
}

setup_python()
{
	log "setup_python"
	if is_ubuntu; then
		setup_python_ubuntu
	elif is_centos; then
		setup_python_centos
	fi
}

setup_python_ubuntu()
{
	apt-get install -y python3-pip
	apt-get install -y build-essential libssl-dev libffi-dev python3-dev
	pip3 install --upgrade pip
}

setup_python_centos()
{
	yum -y install epel-release
	yum -y install python34 python34-devel
	curl -O https://bootstrap.pypa.io/get-pip.py
	python3 get-pip.py
}

setup_cuda8()
{
	log "setup_cuda8"
	if is_ubuntu; then
		setup_cuda8_ubuntu
	elif is_centos; then
		setup_cuda8_centos
	fi

	echo "export CUDA_PATH=/usr/local/cuda" >> /etc/profile.d/cuda.sh
	echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> /etc/profile.d/cuda.sh
}

setup_cuda8_ubuntu()
{
	apt-get install -y linux-headers-$(uname -r)
	curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	dpkg -i cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	apt-get update
	apt-get install -y cuda

	nvidia-smi
}

setup_cuda8_centos()
{
	yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r) --disableexcludes=all
	rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	yum -y install dkms
	CUDA_RPM=cuda-repo-rhel7-8.0.61-1.x86_64.rpm
	curl -O http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_RPM}
	rpm -i ${CUDA_RPM}
	yum clean expire-cache
	yum -y install cuda

	nvidia-smi
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

nvidia_drivers()
{
	log "nvidia_drivers"
	if is_ubuntu; then
		nvidia_drivers_ubuntu
	fi
}

nvidia_drivers_ubuntu()
{
	# Install official NVIDIA driver package
	apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
	sh -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
	apt-get update && apt-get install -y --no-install-recommends cuda-drivers
}

nvidia_docker()
{
	log "nvidia_docker"
	if is_ubuntu; then
		nvidia_docker_ubuntu
	elif is_centos; then
		nvidia_docker_centos
	fi
}

# from https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Azure
nvidia_docker_centos()
{
	# Install nvidia-docker and nvidia-docker-plugin
	wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker-1.0.1-1.x86_64.rpm
	rpm -i /tmp/nvidia-docker*.rpm && rm /tmp/nvidia-docker*.rpm
	systemctl start nvidia-docker
}

# from https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Azure
nvidia_docker_ubuntu()
{
	# Install nvidia-docker and nvidia-docker-plugin
	wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
	dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
}

setup_chainermn()
{
	setup_cuda8

	if is_centos; then
		yum reinstall -y /opt/microsoft/rdma/rhel73/kmod-microsoft-hyper-v-rdma-4.2.0.144-20170426.x86_64.rpm
	fi

	if is_ubuntu; then
		apt install -y ansible build-essential unzip python-pip
	fi
	pip install --upgrade pip

	#wget https://raw.githubusercontent.com/xpillons/azure-hpc/dev/Compute-Grid-Infra/apps/chainer/setup_chainermn.yml
	#ansible-playbook -i "localhost," -c local setup_chainermn.yml -vv
}

mkdir -p /var/local
SETUP_MARKER=/var/local/chainer-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

nvidia_drivers
check_docker

if [ "$CHAINER_MN" == "1" ]; then
	setup_chainermn
else
	if [ "$CHAINERONDOCKER" == "1" ]; then
		nvidia_docker
	else
		base_pkgs
		setup_python
		setup_cuda8
		setup_numpy
		setup_cudnn
		setup_chainer
	fi
fi

# Create marker file so we know we're configured
touch $SETUP_MARKER

shutdown -r +1 &
exit 0

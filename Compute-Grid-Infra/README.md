# Compute grid infrastructure

This template will build a compute grid made by a single jumpbox VMs and multiple VM Scaleset. The jumpbox have its own subnet and all scalesets are inside a global subnet. Accessing the jumpbox can be done thru SSH and its public address.
This is still work in progress, the goal being to add BeeGFS storage, Ganglia Monitoring, PBS Pro OSS as a job scheduler.
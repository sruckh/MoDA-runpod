** GOALS of Project **

The goal of this project is to take the existing github project,       [lixinyyang/MoDA: MoDA: Multi-modal Diffusion Architecture for       Talking Head Generation](https://github.com/lixinyyang/MoDA), and make it a container to be run on the Runpod platform.  The program, app.py, is the entry point of the docker container.  It is the gradio    interface for this project. The base image should be a small base image.  All the components, software, AI models, and dependencies should be installed at runtime into the /workspace filesystem.
Use this as the base image:     [dist/12.8.1/ubuntu2404/runtime · master    · nvidia /    container-images / cuda ·       GitLab](https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/12.8.1/ubuntu2404/runtime)
install this version of pytorch:  pip install torch==2.7.1       torchvision==0.22.1 torchaudio==2.7.1 --index-url       https://download.pytorch.org/whl/cu128
Install this version of       flash_attn:        https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.2/flash_attn-2.8.2+cu12torch2.7cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
Ask context7 for documentation on how to install conda using a Docker    file Use conda to setup up python 3.10 environment

The github repository for this project is    [sruckh/MoDA-runpod](https://github.com/sruckh/MoDA-runpod).  This is    repository is accessed using SSH keys.  This is the repository where all the the commits and pushes will be made.
The github secrets       DOCKER_USERNAME and DOCKER_PASSWORD, have been created.  They are to     be used for creating a github action to build container and push to the docker hub repository gemneye/. 
Make sure the container is only built for linux/amd64 architecture. 
Absolutely do not build this container on the LOCALHOST.  This is strictly for RUNPOD and will not    work on the LOCALHOST.
'docker-compose' has been deprecated; always use 'docker compose' instead.
This is project is a trivial process to containerize an existing project.  Do not overcomplicate the process. 
Always ask context7 to provide recent documentation when needed.  For    example for the optimal way to create containers for Runpod. 
Always ask fetch to retrieve web documentation when needed. Always ask serena for memories when context about the project is needed.

Some other possible resources for building docker containers:    [Templates and Docker Images | runpod/docs |       DeepWiki](https://deepwiki.com/runpod/docs/3.3-templates-and-docker-images)
 
 Use the documentation from [lixinyyang/MoDA: MoDA: Multi-modal    Diffusion Architecture for Talking Head       Generation](https://github.com/lixinyyang/MoDA) to know how to setup    the evironment:

Example:
# 1. Create base environment
conda create -n moda python=3.10 -y
conda activate moda 

# 2. Install requirements
pip install -r requirements.txt

# 3. Install ffmpeg
sudo apt-get update  
sudo apt-get install ffmpeg -y
If you ever have questions ask the user for an answer.


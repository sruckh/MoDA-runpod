#!/bin/bash
# =============================================================================
# MoDA RunPod Deployment Script
# Automated deployment helper for RunPod GPU cloud instances
# =============================================================================

set -e

# Configuration
PROJECT_NAME="moda-talking-head"
DOCKER_IMAGE="moda-runpod:pytorch271-cuda128"
REGISTRY_URL="your-registry.com"  # Replace with your container registry
RUNPOD_API_KEY="${RUNPOD_API_KEY}"  # Set in environment
MODEL_WEIGHTS_SIZE="5GB"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print deployment banner
print_banner() {
    cat << 'EOF'
==============================================================================
🚀 MoDA RunPod Deployment Assistant
==============================================================================
Multi-modal Diffusion Architecture for Talking Head Generation
PyTorch 2.7.1 + CUDA 12.8 | Optimized for RunPod GPU Cloud
==============================================================================
EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking deployment prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    
    # Check NVIDIA Docker
    if ! docker run --rm --gpus all nvidia/cuda:12.8.1-runtime-ubuntu24.04 nvidia-smi &> /dev/null; then
        log_warning "NVIDIA Docker runtime not available - GPU testing skipped"
    fi
    
    # Check RunPod CLI (optional)
    if command -v runpodctl &> /dev/null; then
        log_success "RunPod CLI detected"
    else
        log_info "RunPod CLI not found - manual deployment required"
    fi
    
    log_success "Prerequisites checked"
}

# Build Docker image
build_image() {
    log_info "Building MoDA Docker image..."
    
    cd "$(dirname "$0")/.."
    
    # Copy dockerignore
    if [ -f "config/.dockerignore" ]; then
        cp config/.dockerignore .dockerignore
    fi
    
    # Build with multi-stage optimization
    docker build \
        --file Dockerfile \
        --tag ${DOCKER_IMAGE} \
        --build-arg PYTHON_VERSION=3.10 \
        --build-arg PYTORCH_VERSION=2.7.1 \
        --build-arg CUDA_VERSION=128 \
        --build-arg FLASH_ATTN_VERSION=2.8.2 \
        --target app-stage \
        .
    
    log_success "Docker image built: ${DOCKER_IMAGE}"
}

# Test image locally
test_image() {
    log_info "Testing Docker image locally..."
    
    # Create test directories
    mkdir -p {models,data,outputs,logs}
    
    # Run container with health check
    docker run -d \
        --name moda-test \
        --gpus all \
        -p 7860:7860 \
        -v $(pwd)/models:/workspace/models \
        -v $(pwd)/outputs:/workspace/outputs \
        ${DOCKER_IMAGE}
    
    # Wait for health check
    log_info "Waiting for service to be healthy..."
    sleep 30
    
    if docker inspect --format='{{.State.Health.Status}}' moda-test | grep -q "healthy"; then
        log_success "Container is healthy"
        docker logs moda-test --tail 20
    else
        log_error "Container health check failed"
        docker logs moda-test
        docker rm -f moda-test
        exit 1
    fi
    
    # Cleanup
    docker rm -f moda-test
    log_success "Local test completed successfully"
}

# Push to registry
push_image() {
    log_info "Pushing image to container registry..."
    
    if [ "$REGISTRY_URL" == "your-registry.com" ]; then
        log_warning "Please configure REGISTRY_URL in script"
        log_info "Example: docker tag ${DOCKER_IMAGE} your-registry.com/${DOCKER_IMAGE}"
        log_info "Then: docker push your-registry.com/${DOCKER_IMAGE}"
        return
    fi
    
    # Tag and push
    docker tag ${DOCKER_IMAGE} ${REGISTRY_URL}/${DOCKER_IMAGE}
    docker push ${REGISTRY_URL}/${DOCKER_IMAGE}
    
    log_success "Image pushed to ${REGISTRY_URL}/${DOCKER_IMAGE}"
}

# Generate RunPod deployment configuration
generate_runpod_config() {
    log_info "Generating RunPod deployment configuration..."
    
    cat > runpod-config.json << EOF
{
    "name": "${PROJECT_NAME}",
    "image": "${REGISTRY_URL}/${DOCKER_IMAGE}",
    "gpu": {
        "type": "RTX4090",
        "count": 1
    },
    "ports": [
        {
            "containerPort": 7860,
            "publicPort": 7860,
            "type": "http"
        }
    ],
    "volumes": [
        {
            "name": "model-storage",
            "mountPath": "/workspace/models",
            "size": "10GB"
        }
    ],
    "environment": [
        {
            "name": "GRADIO_SERVER_NAME",
            "value": "0.0.0.0"
        },
        {
            "name": "GRADIO_SERVER_PORT", 
            "value": "7860"
        }
    ],
    "resources": {
        "cpu": "8vCPU",
        "memory": "32GB",
        "storage": "50GB"
    }
}
EOF
    
    log_success "RunPod configuration saved to runpod-config.json"
}

# Print deployment instructions
print_deployment_instructions() {
    cat << EOF

==============================================================================
🎯 DEPLOYMENT INSTRUCTIONS
==============================================================================

1️⃣ RUNPOD SETUP:
   • Login to RunPod Console: https://runpod.io/console
   • Navigate to "Pods" → "Deploy New Pod"
   • Select GPU: RTX 4090 or A100 (24GB+ VRAM recommended)
   
2️⃣ CONTAINER CONFIGURATION:
   • Docker Image: ${REGISTRY_URL}/${DOCKER_IMAGE}
   • Container Port: 7860
   • Expose HTTP Port: Yes
   • Volume: Mount 10GB+ at /workspace/models

3️⃣ MODEL WEIGHTS SETUP:
   • Download MoDA model weights (~${MODEL_WEIGHTS_SIZE})
   • Upload to /workspace/models/pretrained/ via RunPod interface
   • Or use Network Volume for persistence

4️⃣ ENVIRONMENT VARIABLES:
   • GRADIO_SERVER_NAME=0.0.0.0
   • GRADIO_SERVER_PORT=7860
   • PYTHONPATH=/workspace

5️⃣ ACCESS YOUR SERVICE:
   • Service URL: https://[pod-id]-7860.proxy.runpod.net
   • Health Check: /health endpoint
   • Gradio Interface: Web UI for talking head generation

==============================================================================
📋 RESOURCE RECOMMENDATIONS
==============================================================================

Minimum Configuration:
• GPU: RTX 4090 (24GB VRAM)
• RAM: 16GB
• Storage: 50GB
• Network Volume: 10GB for models

Recommended Configuration:
• GPU: A100 (40GB VRAM)  
• RAM: 32GB
• Storage: 100GB
• Network Volume: 50GB for models + datasets

==============================================================================
🔧 TROUBLESHOOTING
==============================================================================

Common Issues:
• CUDA OOM → Reduce batch size or use smaller GPU
• Model not found → Check /workspace/models/pretrained/
• Port not accessible → Verify RunPod port configuration
• Health check failing → Check container logs

Monitoring:
• Container logs: docker logs [container-id]
• GPU usage: nvidia-smi (inside container)
• Health status: curl localhost:7860/health

==============================================================================
EOF
}

# Main deployment workflow
main() {
    print_banner
    
    case "${1:-all}" in
        "check")
            check_prerequisites
            ;;
        "build")
            check_prerequisites
            build_image
            ;;
        "test")
            build_image
            test_image
            ;;
        "push")
            push_image
            ;;
        "config")
            generate_runpod_config
            ;;
        "all")
            check_prerequisites
            build_image
            test_image
            generate_runpod_config
            print_deployment_instructions
            ;;
        *)
            echo "Usage: $0 [check|build|test|push|config|all]"
            exit 1
            ;;
    esac
    
    log_success "Deployment script completed successfully!"
}

# Execute main function
main "$@"
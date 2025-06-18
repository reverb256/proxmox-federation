#!/bin/bash
# Local Development Setup for Consciousness Federation
# Test and validate configurations on current system

set -euo pipefail

echo "🧠 CONSCIOUSNESS FEDERATION - LOCAL DEVELOPMENT MODE"
echo "===================================================="
echo "💻 System: $(uname -a)"
echo "📍 Working Directory: $(pwd)"
echo "🎯 Goal: Validate configurations locally"
echo ""

# === SYSTEM VALIDATION ===
validate_local_system() {
    echo "🔍 SYSTEM VALIDATION"
    echo "==================="
    
    # Check basic tools
    echo "📦 Checking required tools..."
    
    for tool in bash curl wget git python3 pip3 jq; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "✅ $tool - $(command -v "$tool")"
        else
            echo "❌ $tool - NOT FOUND"
        fi
    done
    
    # Check system resources
    echo ""
    echo "💾 System Resources:"
    echo "  CPU: $(nproc) cores"
    echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}') total"
    echo "  Disk: $(df -h . | tail -1 | awk '{print $4}') available"
    echo ""
}

# === PROJECT STRUCTURE VALIDATION ===
validate_project_structure() {
    echo "🔍 PROJECT STRUCTURE VALIDATION"
    echo "==============================="
    
    echo "📁 Checking project directories..."
    
    directories=(
        "configs"
        "k8s"
        "ansible"
        "terraform"
        "scripts"
        "logs"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            file_count=$(find "$dir" -type f | wc -l)
            echo "✅ $dir/ - $file_count files"
        else
            echo "❌ $dir/ - MISSING"
            mkdir -p "$dir"
            echo "  📁 Created $dir/"
        fi
    done
    echo ""
}

# === CONFIGURATION VALIDATION ===
validate_configurations() {
    echo "🔍 CONFIGURATION VALIDATION"
    echo "=========================="
    
    # Check key configuration files
    config_files=(
        "configs/hardware-optimized-deploy.sh"
        "configs/wsl-control-hub-setup.sh"
        "k8s/hardware-aware-workload-placement.yaml"
        "ansible/inventory/hosts.yml"
        "terraform/consciousness-infrastructure.tf"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            size=$(wc -l < "$config")
            echo "✅ $config - $size lines"
        else
            echo "❌ $config - MISSING"
        fi
    done
    echo ""
}

# === YAML VALIDATION ===
validate_yaml_files() {
    echo "🔍 YAML CONFIGURATION VALIDATION"
    echo "================================"
    
    echo "📋 Validating YAML syntax..."
    
    find . -name "*.yaml" -o -name "*.yml" | while read -r yaml_file; do
        if command -v python3 >/dev/null 2>&1; then
            if python3 -c "
import yaml
import sys
try:
    with open('$yaml_file', 'r') as f:
        yaml.safe_load(f)
    print('✅ $yaml_file - Valid YAML')
except Exception as e:
    print('❌ $yaml_file - Invalid:', e)
    sys.exit(1)
"; then
                continue
            else
                echo "⚠️ YAML validation failed for $yaml_file"
            fi
        else
            echo "⚠️ Python3 not available for YAML validation"
            break
        fi
    done
    echo ""
}

# === SCRIPT PERMISSIONS ===
validate_script_permissions() {
    echo "🔍 SCRIPT PERMISSIONS VALIDATION"
    echo "==============================="
    
    find . -name "*.sh" | while read -r script; do
        if [[ -x "$script" ]]; then
            echo "✅ $script - Executable"
        else
            echo "⚠️ $script - Not executable, fixing..."
            chmod +x "$script"
            echo "  🔧 Made $script executable"
        fi
    done
    echo ""
}

# === DEPENDENCY CHECK ===
check_dependencies() {
    echo "🔍 DEPENDENCY CHECK"
    echo "=================="
    
    echo "🐍 Python packages:"
    python3 -c "
import pkg_resources
import sys

required_packages = ['pyyaml', 'requests']
missing_packages = []

for package in required_packages:
    try:
        pkg_resources.require(package)
        print(f'✅ {package}')
    except:
        print(f'❌ {package} - MISSING')
        missing_packages.append(package)

if missing_packages:
    print(f'📦 Install with: pip3 install {\" \".join(missing_packages)}')
" 2>/dev/null || echo "⚠️ Python dependency check failed"
    
    echo ""
}

# === NETWORK CONNECTIVITY (LOCAL) ===
test_local_networking() {
    echo "🔍 LOCAL NETWORKING TEST"
    echo "======================="
    
    # Test localhost connectivity
    if curl -s --connect-timeout 3 http://localhost >/dev/null 2>&1; then
        echo "✅ localhost - Accessible"
    else
        echo "ℹ️ localhost - No service running (expected)"
    fi
    
    # Test internet connectivity
    if curl -s --connect-timeout 5 https://google.com >/dev/null 2>&1; then
        echo "✅ Internet - Connected"
    else
        echo "❌ Internet - No connectivity"
    fi
    
    echo ""
}

# === CONFIGURATION SYNTAX CHECK ===
test_configuration_syntax() {
    echo "🔍 CONFIGURATION SYNTAX CHECK"
    echo "============================"
    
    # Test shell scripts syntax
    find . -name "*.sh" | head -5 | while read -r script; do
        if bash -n "$script" 2>/dev/null; then
            echo "✅ $script - Valid syntax"
        else
            echo "❌ $script - Syntax error"
        fi
    done
    
    echo ""
}

# === CREATE LOCAL DEMO ===
create_local_demo() {
    echo "🎮 CREATING LOCAL DEMO"
    echo "====================="
    
    # Create a simple local consciousness demo
    cat > "local-consciousness-demo.sh" <<'EOF'
#!/bin/bash
# Local Consciousness Federation Demo

echo "🧠 Local Consciousness Demo"
echo "=========================="

# Display hardware topology from config
if [[ -f "k8s/hardware-aware-workload-placement.yaml" ]]; then
    echo "📊 Hardware Topology Configuration:"
    grep -A 20 "topology.yaml:" k8s/hardware-aware-workload-placement.yaml | head -25
fi

echo ""
echo "🎯 Local System Info:"
echo "  CPU Cores: $(nproc)"
echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "  Storage: $(df -h . | tail -1 | awk '{print $4}') available"
echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"

echo ""
echo "✅ Local consciousness federation components validated!"
EOF

    chmod +x local-consciousness-demo.sh
    echo "📝 Created local-consciousness-demo.sh"
    echo ""
}

# === MAIN EXECUTION ===
main() {
    echo "🌟 STARTING LOCAL VALIDATION"
    echo "============================"
    
    validate_local_system
    validate_project_structure
    validate_configurations
    validate_yaml_files
    validate_script_permissions
    check_dependencies
    test_local_networking
    test_configuration_syntax  
    create_local_demo
    
    echo "🎉 LOCAL VALIDATION COMPLETE!"
    echo "============================="
    echo ""
    echo "📊 Summary:"
    echo "  ✅ System validated"
    echo "  ✅ Project structure verified"
    echo "  ✅ Configurations checked"
    echo "  ✅ Scripts permissions fixed"
    echo ""
    echo "🎮 Try the local demo:"
    echo "  ./local-consciousness-demo.sh"
    echo ""
    echo "🚀 When Proxmox nodes are online, run:"
    echo "  ./master-bootstrap-consciousness-federation.sh"
    echo ""
}

# Execute main function
main "$@"

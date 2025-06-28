Write-Host "Checking Project Completeness..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$BASE_DIR = "c:\Users\Ramish Taha\Desktop\kubernetes project based learning"

function Test-ProjectStructure {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )
    
    if (Test-Path $ProjectPath) {
        Write-Host "OK $ProjectName - Directory exists" -ForegroundColor Green
        
        # Check for README.md
        if (Test-Path "$ProjectPath\README.md") {
            Write-Host "  README.md: OK" -ForegroundColor Green
        } else {
            Write-Host "  README.md: MISSING" -ForegroundColor Red
        }
        
        # Check for manifests directory
        if (Test-Path "$ProjectPath\manifests") {
            $manifestFiles = @()
            $manifestFiles += Get-ChildItem "$ProjectPath\manifests" -Filter "*.yaml" -Recurse -ErrorAction SilentlyContinue
            $manifestFiles += Get-ChildItem "$ProjectPath\manifests" -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue
            $manifestCount = $manifestFiles.Count
            Write-Host "  manifests/: OK ($manifestCount files)" -ForegroundColor Green
        } else {
            Write-Host "  manifests/: MISSING" -ForegroundColor Red
        }
        
        # Check for scripts directory
        if (Test-Path "$ProjectPath\scripts") {
            $scriptFiles = @()
            $scriptFiles += Get-ChildItem "$ProjectPath\scripts" -Filter "*.sh" -Recurse -ErrorAction SilentlyContinue
            $scriptFiles += Get-ChildItem "$ProjectPath\scripts" -Filter "*.bat" -Recurse -ErrorAction SilentlyContinue
            $scriptFiles += Get-ChildItem "$ProjectPath\scripts" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
            $scriptCount = $scriptFiles.Count
            Write-Host "  scripts/: OK ($scriptCount files)" -ForegroundColor Green
        } else {
            Write-Host "  scripts/: MISSING" -ForegroundColor Red
        }
        
    } else {
        Write-Host "MISSING $ProjectName - Directory missing" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "BEGINNER PROJECTS:" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Yellow
Test-ProjectStructure "$BASE_DIR\01-beginner\01-hello-kubernetes" "Project 1: Hello Kubernetes"
Test-ProjectStructure "$BASE_DIR\01-beginner\02-multi-container-app" "Project 2: Multi-Container App"
Test-ProjectStructure "$BASE_DIR\01-beginner\03-database-integration" "Project 3: Database Integration"
Test-ProjectStructure "$BASE_DIR\01-beginner\04-load-balancing" "Project 4: Load Balancing"
Test-ProjectStructure "$BASE_DIR\01-beginner\05-configuration-management" "Project 5: Configuration Management"

Write-Host "INTERMEDIATE PROJECTS:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
Test-ProjectStructure "$BASE_DIR\02-intermediate\06-microservices-architecture" "Project 6: Microservices Architecture"
Test-ProjectStructure "$BASE_DIR\02-intermediate\07-cicd-pipeline" "Project 7: CI/CD Pipeline"
Test-ProjectStructure "$BASE_DIR\02-intermediate\08-monitoring-logging" "Project 8: Monitoring & Logging"
Test-ProjectStructure "$BASE_DIR\02-intermediate\09-security-rbac" "Project 9: Security & RBAC"
Test-ProjectStructure "$BASE_DIR\02-intermediate\10-disaster-recovery" "Project 10: Disaster Recovery"

Write-Host "ADVANCED PROJECTS:" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Yellow
Test-ProjectStructure "$BASE_DIR\03-advanced\11-multi-cluster-management" "Project 11: Multi-cluster Management"
Test-ProjectStructure "$BASE_DIR\03-advanced\12-custom-controllers" "Project 12: Custom Controllers"
Test-ProjectStructure "$BASE_DIR\03-advanced\13-ml-pipeline" "Project 13: ML Pipeline"
Test-ProjectStructure "$BASE_DIR\03-advanced\14-edge-computing" "Project 14: Edge Computing"
Test-ProjectStructure "$BASE_DIR\03-advanced\15-enterprise-platform" "Project 15: Enterprise Platform"

Write-Host "Completeness check finished!" -ForegroundColor Cyan

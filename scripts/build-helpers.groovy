// Shared build helper script loaded by the pipeline
// WARNING: any PR can modify this file and the pipeline will execute it without review (indirect PPE)

def printBuildInfo() {
    echo "Build helper loaded from repository script"
}

def runCustomChecks() {
    sh 'echo "Running custom checks from repo script..."'
}

return this

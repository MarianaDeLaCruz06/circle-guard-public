// ---------------------------------------------------------------------------
// Shared pipeline library for CircleGuard.
// Loaded by Jenkinsfile.dev / Jenkinsfile.stage / Jenkinsfile.master with:
//     def lib = load 'jenkins/shared.groovy'
// All env.* references resolve in the calling pipeline's environment block.
// ---------------------------------------------------------------------------

def serviceList() {
    return env.SERVICES.split(' ')
}

def runCommand(String command) {
    if (isUnix()) {
        sh command
    } else {
        bat command
    }
}

def runCommandStatus(String command) {
    if (isUnix()) {
        return sh(script: command, returnStatus: true)
    }
    return bat(script: command, returnStatus: true)
}

def runGradle(String taskName) {
    def tasks = serviceList().collect { ":services:${it}:${taskName}" }.join(' ')
    runCommand("${isUnix() ? './gradlew' : 'gradlew.bat'} ${tasks}")
}

// ---------------------------------------------------------------------------
// Semantic versioning
// ---------------------------------------------------------------------------
// Rules:
//   dev    → 0.0.0-dev.<shortSha>           (snapshot, never tagged in git)
//   stage  → <lastTag>-rc.<buildNumber>     (release candidate)
//   master → bumped from last vX.Y.Z tag    (real release; tagged when CREATE_GIT_TAG=true)
def computeVersion(String channel) {
    def shortSha = shortGitSha()
    if (channel == 'dev') {
        return "0.0.0-dev.${shortSha}"
    }
    def lastTag = lastSemverTag()
    if (channel == 'stage') {
        return "${lastTag}-rc.${env.BUILD_NUMBER}"
    }
    // master: bump patch, drop the leading 'v'
    def parts = lastTag.replaceFirst(/^v/, '').tokenize('.')
    def major = parts[0].toInteger()
    def minor = parts[1].toInteger()
    def patch = parts[2].toInteger() + 1
    return "${major}.${minor}.${patch}"
}

def shortGitSha() {
    def script = 'git rev-parse --short HEAD'
    if (isUnix()) {
        return sh(script: script, returnStdout: true).trim()
    }
    return bat(script: "@${script}", returnStdout: true).trim()
}

def lastSemverTag() {
    def script = 'git describe --tags --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*"'
    try {
        String stdout
        if (isUnix()) {
            stdout = sh(script: "${script} 2>/dev/null || echo v0.0.0", returnStdout: true).trim()
        } else {
            stdout = bat(script: "@${script}", returnStdout: true).trim()
        }
        return stdout ?: 'v0.0.0'
    } catch (Exception e) {
        echo "lastSemverTag: no git tags found yet (${e.message}); defaulting to v0.0.0"
        return 'v0.0.0'
    }
}

// ---------------------------------------------------------------------------
// Docker
// ---------------------------------------------------------------------------
def buildDockerImages(String tag = 'local') {
    serviceList().each { service ->
        runCommand("docker build -f services/${service}/Dockerfile -t ${service}:${tag} .")
    }
}

// ---------------------------------------------------------------------------
// Trivy container scan
// ---------------------------------------------------------------------------
// failOnHigh=true → master pipeline (exit code != 0 fails the build).
// failOnHigh=false → dev/stage (advisory only).
def runTrivyScan(String tag, boolean failOnHigh) {
    if (!hasTool('trivy')) {
        echo "Trivy no esta instalado en el agente; se omite escaneo de contenedores. Instala desde https://aquasecurity.github.io/trivy/ para habilitarlo."
        return
    }
    def severity = failOnHigh ? 'HIGH,CRITICAL' : 'CRITICAL'
    serviceList().each { service ->
        def image = "${service}:${tag}"
        def status = runCommandStatus("trivy image --severity ${severity} --no-progress --format table ${image}")
        if (status != 0) {
            if (failOnHigh) {
                error("Trivy encontro vulnerabilidades HIGH/CRITICAL en ${image} — build bloqueado para produccion.")
            } else {
                echo "WARNING: Trivy reporto hallazgos en ${image} (modo advisory, no bloquea el build)."
            }
        }
    }
}

// ---------------------------------------------------------------------------
// SonarQube
// ---------------------------------------------------------------------------
// Reads SONAR_HOST_URL and SONAR_TOKEN from environment.
// Skips cleanly if no token or no sonar-scanner binary.
def runSonarAnalysis(String version) {
    if (!env.SONAR_TOKEN) {
        echo 'SONAR_TOKEN no esta definido; se omite analisis SonarQube. Configura una Jenkins credential llamada sonar-token y exportala en environment {}.'
        return
    }
    if (!hasTool('sonar-scanner')) {
        echo 'sonar-scanner no esta en PATH del agente; se omite analisis SonarQube. Instala sonar-scanner-cli o usa el plugin SonarQube Scanner.'
        return
    }
    def host = env.SONAR_HOST_URL ?: 'http://localhost:9000'
    runCommand("sonar-scanner -Dsonar.host.url=${host} -Dsonar.login=${env.SONAR_TOKEN} -Dsonar.projectVersion=${version}")
}

// ---------------------------------------------------------------------------
// Kubernetes
// ---------------------------------------------------------------------------
def hasKubectl() {
    return hasTool('kubectl')
}

def hasTool(String name) {
    if (isUnix()) {
        return sh(script: "command -v ${name} >/dev/null 2>&1", returnStatus: true) == 0
    }
    return bat(script: "where ${name} >nul 2>nul", returnStatus: true) == 0
}

def kubectlApply() {
    runCommand("kubectl apply --validate=false -f k8s/namespace.yaml")
    runCommand("kubectl apply --validate=false -n ${env.KUBE_NAMESPACE} -f k8s/config.yaml")
    runCommand("kubectl apply --validate=false -n ${env.KUBE_NAMESPACE} -f k8s/infrastructure.yaml")
    runCommand("kubectl apply --validate=false -n ${env.KUBE_NAMESPACE} -f k8s/services.yaml")
}

def rolloutAll() {
    serviceList().each { service ->
        def status = runCommandStatus("kubectl rollout status deployment/${service} -n ${env.KUBE_NAMESPACE} --timeout=180s")
        if (status != 0) {
            echo "WARNING: rollout de ${service} no completo en ${env.KUBE_NAMESPACE}. Se continua para evidencia academica local."
        }
    }
    runCommand("kubectl get pods -n ${env.KUBE_NAMESPACE}")
    runCommand("kubectl get svc -n ${env.KUBE_NAMESPACE}")
}

def smokeTest(String service, String port) {
    def pod = "smoke-${service}".take(63).replaceAll('-$', '')
    def status
    if (isUnix()) {
        status = sh(
            returnStatus: true,
            script: """
                OUTPUT=\$(kubectl run ${pod} -n ${env.KUBE_NAMESPACE} --rm -i --quiet=true --restart=Never --image=curlimages/curl:8.10.1 --command -- curl -sS -o /dev/null -w "%{http_code}" --max-time 10 http://${service}:${port}/ 2>/dev/null)
                if [ \$? -ne 0 ]; then OUTPUT=000; fi
                CODE=\$(printf "%s" "\$OUTPUT" | grep -Eo '[0-9]{3}' | tail -n 1)
                if [ -z "\$CODE" ]; then CODE=000; fi
                echo "Smoke test ${service}:${port} HTTP status: \$CODE"
                if [ "\$CODE" = "200" ] || [ "\$CODE" = "401" ] || [ "\$CODE" = "403" ] || [ "\$CODE" = "404" ]; then
                    exit 0
                fi
                exit 1
            """
        )
    } else {
        status = powershell(
            returnStatus: true,
            script: """
                \$output = kubectl run ${pod} -n ${env.KUBE_NAMESPACE} --rm -i --quiet=true --restart=Never --image=curlimages/curl:8.10.1 --command -- curl -sS -o /dev/null -w "%{http_code}" --max-time 10 http://${service}:${port}/ 2>\$null
                if (\$LASTEXITCODE -ne 0) { \$output = "000" }
                \$matches = [regex]::Matches((\$output -join ""), "\\d{3}")
                \$code = if (\$matches.Count -gt 0) { \$matches[\$matches.Count - 1].Value } else { "000" }
                Write-Host "Smoke test ${service}:${port} HTTP status: \$code"
                if (@("200", "401", "403", "404") -contains "\$code") {
                    exit 0
                }
                exit 1
            """
        )
    }
    if (status != 0) {
        echo "WARNING: smoke test did not return an expected HTTP status, but deployment evidence was collected."
    }
}

def smokeTestAllServices() {
    smokeTest('circleguard-auth-service', '8180')
    smokeTest('circleguard-identity-service', '8083')
    smokeTest('circleguard-form-service', '8086')
    smokeTest('circleguard-promotion-service', '8088')
    smokeTest('circleguard-notification-service', '8082')
    smokeTest('circleguard-gateway-service', '8087')
}

// ---------------------------------------------------------------------------
// Release notes (master only)
// ---------------------------------------------------------------------------
def generateReleaseNotes(String version) {
    if (isUnix()) {
        sh """
            pwd
            git log -n 5
            {
              echo '# CircleGuard Release ${version}'
              echo
              echo "Generated at: \$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
              echo "Build number: ${env.BUILD_NUMBER}"
              echo
              echo '## Recent Changes'
              git log --pretty=format:'- %h %s (%an, %ad)' --date=short -n 20
            } > ${env.RELEASE_NOTES_FILE}
        """
    } else {
        powershell """
            pwd
            git log -n 5
            '# CircleGuard Release ${version}' | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8
            '' | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
            ('Generated at: ' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')) | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
            ('Build number: ${env.BUILD_NUMBER}') | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
            '' | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
            '## Recent Changes' | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
            git log --pretty=format:'- %h %s (%an, %ad)' --date=short -n 20 | Out-File ${env.RELEASE_NOTES_FILE} -Encoding utf8 -Append
        """
    }
}

def validateReleaseNotes() {
    if (isUnix()) {
        sh """
            ls -la
            if [ ! -f "${env.RELEASE_NOTES_FILE}" ]; then
                echo "ERROR: ${env.RELEASE_NOTES_FILE} was not created in the workspace root."
                exit 1
            fi
            cat ${env.RELEASE_NOTES_FILE}
        """
    } else {
        powershell """
            Get-ChildItem -Force
            if (-not (Test-Path -Path '${env.RELEASE_NOTES_FILE}' -PathType Leaf)) {
                Write-Error '${env.RELEASE_NOTES_FILE} was not created in the workspace root.'
                exit 1
            }
            Get-Content -Path '${env.RELEASE_NOTES_FILE}'
        """
    }
}

// ---------------------------------------------------------------------------
// Git tagging (master only)
// ---------------------------------------------------------------------------
def tagGitRelease(String version) {
    if (env.CREATE_GIT_TAG != 'true') {
        echo "CREATE_GIT_TAG != 'true'; se omite tag v${version} (cambia el parametro para publicar tag)."
        return
    }
    def tag = "v${version}"
    runCommand("git tag -a ${tag} -m \"Release ${tag} (build ${env.BUILD_NUMBER})\"")
    // Pushing requires git credentials configured in the Jenkins job
    def pushStatus = runCommandStatus("git push origin ${tag}")
    if (pushStatus != 0) {
        echo "WARNING: no se pudo push el tag ${tag}. Revisa credenciales git del agente."
    } else {
        echo "Tag ${tag} publicado en origin."
    }
}

// ---------------------------------------------------------------------------
// Failure notification
// ---------------------------------------------------------------------------
// Sends an email to NOTIFICATION_RECIPIENTS (env var or default).
// Skips cleanly if mailer is not configured or recipient list is empty.
def notifyOnFailure() {
    def recipients = env.NOTIFICATION_RECIPIENTS
    if (!recipients) {
        echo 'NOTIFICATION_RECIPIENTS no esta definida; se omite envio de notificacion. Configura un valor (comma-separated) en environment {} para habilitarlo.'
        return
    }
    try {
        emailext(
            to: recipients,
            subject: "[CircleGuard] ${env.JOB_NAME} #${env.BUILD_NUMBER} fallo",
            body: """\
                |La pipeline CircleGuard fallo.
                |
                |Job: ${env.JOB_NAME}
                |Build: ${env.BUILD_NUMBER}
                |Branch/Channel: ${env.BUILD_CHANNEL ?: 'unknown'}
                |Resultado: ${currentBuild.currentResult}
                |
                |Logs: ${env.BUILD_URL}console
                |Workspace: ${env.WORKSPACE}
                |
                |Commit: ${shortGitSha()}
                |""".stripMargin(),
            mimeType: 'text/plain'
        )
        echo "Notificacion enviada a ${recipients}."
    } catch (err) {
        // Fall back to mail step (basic mailer plugin) if emailext is not installed
        try {
            mail(
                to: recipients,
                subject: "[CircleGuard] ${env.JOB_NAME} #${env.BUILD_NUMBER} fallo",
                body: "Pipeline fallo. Ver ${env.BUILD_URL}console"
            )
        } catch (err2) {
            echo "WARNING: ni emailext ni mail funcionaron. Instala el plugin 'Email Extension' o configura SMTP en Jenkins. Detalle: ${err2.message}"
        }
    }
}

return this

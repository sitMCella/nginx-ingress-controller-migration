import { useMemo, useState } from 'react'
import DOMPurify from 'dompurify'
import { marked } from 'marked'

function App() {
  const [viewMode, setViewMode] = useState<'markdown' | 'html'>('markdown')

  const notesContent = `# ingress-nginx deprecation and migration notes

## Context: ingress-nginx retirement

Reference: https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/

Key points from the Kubernetes announcement:
- Ingress NGINX is entering retirement due to long-term maintainability and security challenges.
- Best-effort maintenance continues until March 2026.
- After March 2026, no new releases, bug fixes, or security patches are expected.
- Existing deployments will keep running, but risk will increase over time as vulnerabilities remain unpatched.
- Kubernetes SIG Network and SRC recommend migration to Gateway API or another maintained ingress controller.

## Why migrate now

- Security posture: no future fixes after retirement date.
- Operational risk: critical bugs may remain unresolved.
- Platform longevity: moving to an actively maintained controller reduces future outages and emergency migrations.

## Target option: HAProxy Ingress Controller

Useful references:
- https://github.com/haproxytech/kubernetes-ingress
- https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress
- https://www.haproxy.com/documentation/kubernetes-ingress/

## Migration plan to HAProxy Ingress Controller

### 1) Inventory current ingress-nginx usage

- Detect running ingress-nginx controller:

\`\`\`bash
kubectl get pods -A -l app.kubernetes.io/name=ingress-nginx
\`\`\`

- List all Ingress resources and classes:

\`\`\`bash
kubectl get ingress -A
kubectl get ingressclass
\`\`\`

- Collect nginx-specific annotations and snippets (high-risk for portability):

\`\`\`bash
kubectl get ingress -A -o yaml > ingress-backup.yaml
\`\`\`

Look for patterns like:
- nginx.ingress.kubernetes.io/*
- configuration-snippet, server-snippet, location-snippet
- auth, rewrite, canary, rate-limit, custom headers annotations

### 2) Install HAProxy Ingress alongside nginx (parallel run)

Keep both controllers during migration to reduce risk.

\`\`\`bash
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update
\`\`\`

Example install with dedicated class \`haproxy\`:

\`\`\`bash
helm upgrade --install haproxy-ingress haproxytech/kubernetes-ingress \\
  --namespace haproxy-controller \\
  --create-namespace \\
  --set controller.ingressClass=haproxy \\
  --set controller.service.type=LoadBalancer
\`\`\`

Note for AKS: you may need LB health probe annotations (for example probe path \`/healthz\`) as documented by the HAProxy chart.

### 3) Create or confirm IngressClass for HAProxy

Depending on chart values/version, this may be created automatically. Confirm:

\`\`\`bash
kubectl get ingressclass
\`\`\`

Ensure class \`haproxy\` is available and intended for the new controller.

### 4) Migrate Ingress resources incrementally

For each Ingress:
- Set \`spec.ingressClassName: haproxy\`.
- Replace nginx annotations with HAProxy equivalents where needed.
- Remove unsupported nginx-specific snippets.

Recommended approach:
- Start with low-risk services.
- Deploy copied Ingress manifests with \`haproxy\` class.
- Validate traffic, TLS, redirects, rewrites, sticky sessions, and websocket behavior.

### 5) Annotation and feature mapping pass

Build a migration matrix from current annotations to HAProxy config:
- TLS termination and cert references
- Path rewrites and regex behavior
- Auth (basic/OIDC/external auth)
- Rate limiting
- CORS and security headers
- Timeouts and body size limits
- Canary or weighted traffic

Important:
- Do not assume 1:1 annotation compatibility.
- Validate each behavior with integration tests or synthetic probes.

### 6) Canary and cutover

- Shift selected host/path traffic to HAProxy-managed Ingress resources.
- Watch logs, latency, error rates, and 4xx/5xx deltas.
- Keep rollback manifests ready (revert \`ingressClassName\` to previous class if needed).

### 7) Decommission ingress-nginx

After all routes are validated on HAProxy:

\`\`\`bash
helm uninstall ingress-nginx -n ingress-nginx
\`\`\`

Then verify no workloads still reference the old class or nginx annotations.

### 8) Post-migration hardening

- Enable and scrape controller metrics.
- Add alerting for error-rate spikes and config reload failures.
- Update runbooks and onboarding docs.
- Schedule periodic review for Gateway API adoption (future-proofing).

## Suggested execution order for production

1. Dev/staging dry run with real traffic patterns.
2. Production parallel controller deployment.
3. Batch migration by domain/team.
4. Full cutover window with rollback plan.
5. ingress-nginx uninstall only after burn-in period.

## Risks to track explicitly

- Annotation incompatibilities causing subtle behavior changes.
- TLS chain/cipher policy differences.
- Rewrite/regex edge cases.
- Health check and LoadBalancer annotation differences per cloud provider.
- Missing observability during cutover.`

  const safeHtml = useMemo(() => {
    const parsed = marked.parse(notesContent)
    const unsafeHtml = typeof parsed === 'string' ? parsed : ''
    return DOMPurify.sanitize(unsafeHtml)
  }, [notesContent])

  return (
    <main className="min-h-screen bg-slate-950 px-4 py-8 text-slate-100 sm:px-8">
      <div className="mx-auto max-w-5xl rounded-xl border border-slate-800 bg-slate-900/60 p-6 shadow-xl">
        <h1 className="mb-4 text-2xl font-semibold tracking-tight sm:text-3xl">
          ingress-nginx retirement and HAProxy migration notes
        </h1>

        <div className="mb-6 inline-flex rounded-lg border border-slate-700 bg-slate-950 p-1">
          <button
            type="button"
            onClick={() => setViewMode('markdown')}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition ${
              viewMode === 'markdown'
                ? 'bg-emerald-500 text-slate-950'
                : 'text-slate-300 hover:bg-slate-800'
            }`}
          >
            Markdown
          </button>
          <button
            type="button"
            onClick={() => setViewMode('html')}
            className={`rounded-md px-3 py-1.5 text-sm font-medium transition ${
              viewMode === 'html'
                ? 'bg-emerald-500 text-slate-950'
                : 'text-slate-300 hover:bg-slate-800'
            }`}
          >
            HTML
          </button>
        </div>

        {viewMode === 'markdown' ? (
          <pre className="overflow-x-auto whitespace-pre-wrap break-words rounded-lg bg-slate-950 p-4 text-sm leading-7 text-slate-200">
            {notesContent}
          </pre>
        ) : (
          <article
            className="rounded-lg bg-slate-950 p-4 leading-7 text-slate-200 [&_a]:text-emerald-300 [&_a]:underline [&_code]:rounded [&_code]:bg-slate-900 [&_code]:px-1.5 [&_code]:py-0.5 [&_h1]:mb-3 [&_h1]:text-2xl [&_h1]:font-semibold [&_h2]:mb-2 [&_h2]:mt-6 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mb-2 [&_h3]:mt-5 [&_h3]:text-lg [&_h3]:font-semibold [&_li]:ml-5 [&_li]:list-disc [&_ol_li]:list-decimal [&_pre]:overflow-x-auto [&_pre]:rounded [&_pre]:bg-slate-900 [&_pre]:p-3 [&_pre]:text-sm [&_pre]:leading-6 [&_ul]:space-y-1"
            dangerouslySetInnerHTML={{ __html: safeHtml }}
          />
        )}
      </div>
    </main>
  )
}

export default App

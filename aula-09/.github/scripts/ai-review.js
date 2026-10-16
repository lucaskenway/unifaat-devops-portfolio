#!/usr/bin/env node
// ============================================
// AI Code Review — TechNova (Aula 09)
// ============================================
// Analisa o diff de um Pull Request e gera um relatório Markdown com os
// achados classificados por severidade. A análise é baseada em regras
// (pattern matching sobre as linhas ADICIONADAS do diff); o ponto de extensão
// para um modelo de IA (Bedrock) está documentado em aula-09/ia-cicd-analise.md.
//
// Variáveis de ambiente:
//   DIFF_FILE         diff unificado do PR          (default: /tmp/pr-diff.txt)
//   REVIEW_OUTPUT     relatório Markdown gerado     (default: /tmp/ai-review-result.md)
//   GITHUB_OUTPUT     preenchida pelo Actions: exporta critical/warning/info
//   FAIL_ON_CRITICAL  "true" → exit 1 se houver CRITICAL (uso local)
//
// Suprimir um falso positivo: adicionar o comentário `ai-review-ignore` na linha.

const fs = require('fs');

const MARKER = '<!-- technova-ai-review -->';

const SEVERITY = {
  CRITICAL: { key: 'CRITICAL', label: '🔴 CRITICAL', order: 0 },
  WARNING: { key: 'WARNING', label: '🟡 WARNING', order: 1 },
  INFO: { key: 'INFO', label: '🔵 INFO', order: 2 }
};

// Arquivos que nunca são analisados (documentação, lockfiles, o próprio script)
const SKIP_FILES = /(\.md|\.diff|\.txt|package-lock\.json|ai-review\.js)$/i;

const JS_FILES = /\.(c|m)?(j|t)sx?$/i;
const DOCKERFILES = /(^|\/)Dockerfile[^/]*$/;
const TEST_FILES = /(__tests__\/|\.test\.|\.spec\.)/;

const RULES = [
  // ---------- Segurança (CRITICAL) ----------
  {
    id: 'hardcoded-secret',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /\b\w*(password|passwd|pwd|secret|api[_-]?key|apikey|access[_-]?key|token)\w*['"]?\s*[:=]\s*['"`][^'"`\s]{4,}['"`]/i,
    message: 'Possível secret/credencial hardcoded — use variável de ambiente ou GitHub Secrets',
    mask: true
  },
  {
    id: 'aws-access-key',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /\b(AKIA|ASIA)[0-9A-Z]{16}\b/,
    message: 'AWS Access Key ID no código — revogue a chave e use OIDC/Secrets',
    mask: true
  },
  {
    id: 'private-key',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----/,
    message: 'Chave privada commitada no repositório',
    mask: true
  },
  {
    id: 'eval',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /(^|[^\w.])eval\s*\(/,
    message: 'Uso de eval() — risco de code injection',
    files: JS_FILES
  },
  {
    id: 'new-function',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /\bnew\s+Function\s*\(/,
    message: 'new Function() executa string como código — mesmo risco do eval()',
    files: JS_FILES
  },
  {
    id: 'sql-injection',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /(\b(query|execute|raw)\s*\(\s*(`[^`]*\$\{|['"][^'"]*['"]\s*\+))|(['"`]\s*(SELECT|INSERT|UPDATE|DELETE)\b[^'"`]*['"`]\s*\+)|(`\s*(SELECT|INSERT|UPDATE|DELETE)\b[^`]*\$\{)/i,
    message: 'Possível SQL injection — SQL montado por concatenação; use query parametrizada',
    files: JS_FILES
  },
  {
    id: 'command-injection',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /\b(exec|execSync|spawn|spawnSync)\s*\(\s*(`[^`]*\$\{|['"][^'"]*['"]\s*\+)/,
    message: 'Possível command injection — comando de shell montado com dados dinâmicos',
    files: JS_FILES
  },
  {
    id: 'tls-disabled',
    category: 'Segurança',
    severity: SEVERITY.CRITICAL,
    pattern: /rejectUnauthorized\s*:\s*false|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*['"]?0/,
    message: 'Validação de certificado TLS desabilitada — permite man-in-the-middle'
  },

  // ---------- Qualidade / hardening (WARNING) ----------
  {
    id: 'xss-sink',
    category: 'Segurança',
    severity: SEVERITY.WARNING,
    pattern: /\.innerHTML\s*=|\.outerHTML\s*=|dangerouslySetInnerHTML|document\.write\s*\(/,
    message: 'Escrita de HTML não escapado — risco de XSS',
    files: JS_FILES
  },
  {
    id: 'cors-wildcard',
    category: 'Segurança',
    severity: SEVERITY.WARNING,
    pattern: /origin\s*:\s*['"]\*['"]|Access-Control-Allow-Origin['"]?\s*[,:]\s*['"]\*['"]/i,
    message: 'CORS liberado para qualquer origem (*)'
  },
  {
    id: 'bind-all-interfaces',
    category: 'Segurança',
    severity: SEVERITY.WARNING,
    pattern: /['"`]0\.0\.0\.0['"`]|--(host|bind)[= ]0\.0\.0\.0\b/,
    message: 'Bind em 0.0.0.0 — expõe o serviço em todas as interfaces; fora de container, prefira 127.0.0.1 ou um HOST configurável'
  },
  {
    id: 'open-cidr',
    category: 'Segurança',
    severity: SEVERITY.WARNING,
    pattern: /0\.0\.0\.0\/0|::\/0/,
    message: 'CIDR aberto para a internet (0.0.0.0/0) — restrinja a origem (ex.: SSH só do seu IP)',
    files: /\.(tf|tfvars|ya?ml|json)$/i
  },
  {
    id: 'console-log',
    category: 'Qualidade',
    severity: SEVERITY.WARNING,
    pattern: /\bconsole\.(log|debug|info)\s*\(/,
    message: 'console.log em código de produção — remova ou use um logger',
    files: JS_FILES,
    skipTests: true
  },
  {
    id: 'empty-catch',
    category: 'Qualidade',
    severity: SEVERITY.WARNING,
    pattern: /catch\s*(\(\s*[\w$]*\s*\))?\s*\{\s*\}/,
    message: 'catch vazio — erros silenciados escondem bugs',
    files: JS_FILES
  },
  {
    id: 'debugger',
    category: 'Qualidade',
    severity: SEVERITY.WARNING,
    pattern: /^\s*debugger\s*;?\s*$/,
    message: 'Instrução debugger esquecida no código',
    files: JS_FILES
  },
  {
    id: 'docker-latest',
    category: 'Container',
    severity: SEVERITY.WARNING,
    pattern: /^\s*FROM\s+\S+:latest\b/i,
    message: 'Imagem base com tag :latest — build não reprodutível; fixe a versão',
    files: DOCKERFILES
  },
  {
    id: 'docker-root',
    category: 'Container',
    severity: SEVERITY.WARNING,
    pattern: /^\s*USER\s+(root|0)\s*$/i,
    message: 'Container rodando como root',
    files: DOCKERFILES
  },
  {
    id: 'chmod-777',
    category: 'Segurança',
    severity: SEVERITY.WARNING,
    pattern: /chmod\s+(-R\s+)?0?777\b/,
    message: 'Permissão 777 — qualquer usuário pode escrever/executar'
  },

  // ---------- Sugestões (INFO) ----------
  {
    id: 'todo',
    category: 'Manutenção',
    severity: SEVERITY.INFO,
    pattern: /\b(TODO|FIXME|HACK|XXX)\b/,
    message: 'Comentário TODO/FIXME — resolver ou abrir issue antes do merge'
  },
  {
    id: 'var',
    category: 'Qualidade',
    severity: SEVERITY.INFO,
    pattern: /^\s*var\s+[\w$]+/,
    message: 'Uso de var — prefira const/let (escopo de bloco)',
    files: JS_FILES
  }
];

// Esconde o valor de literais de string para não vazar o secret no comentário do PR
function maskSecrets(code) {
  return code
    .replace(/(['"`])([^'"`]{4,})\1/g, (_m, q, value) => `${q}${value.slice(0, 2)}****${q}`)
    .replace(/\b(AKIA|ASIA)[0-9A-Z]{16}\b/g, '$1****************');
}

function analyzeDiff(diffContent) {
  const findings = [];
  let currentFile = null;
  let newLine = 0;

  for (const line of diffContent.split('\n')) {
    if (line.startsWith('+++ ')) {
      const target = line.slice(4).trim();
      currentFile = target === '/dev/null' ? null : target.replace(/^b\//, '');
      continue;
    }
    if (line.startsWith('--- ') || line.startsWith('diff --git')) {
      continue;
    }

    const hunk = line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
    if (hunk) {
      newLine = parseInt(hunk[1], 10);
      continue;
    }

    if (!currentFile) {
      continue;
    }

    if (line.startsWith('+')) {
      const code = line.slice(1);
      if (!SKIP_FILES.test(currentFile) && !code.includes('ai-review-ignore')) {
        for (const rule of RULES) {
          if (rule.files && !rule.files.test(currentFile)) continue;
          if (rule.skipTests && TEST_FILES.test(currentFile)) continue;
          if (rule.pattern.test(code)) {
            const snippet = code.trim();
            findings.push({
              rule: rule.id,
              category: rule.category,
              severity: rule.severity,
              message: rule.message,
              file: currentFile,
              line: newLine,
              code: rule.mask ? maskSecrets(snippet) : snippet
            });
          }
        }
      }
      newLine++;
    } else if (line.startsWith(' ')) {
      newLine++;
    }
    // linhas '-' e '\ No newline at end of file' não avançam o contador do arquivo novo
  }

  return findings.sort((a, b) =>
    a.severity.order - b.severity.order ||
    a.file.localeCompare(b.file) ||
    a.line - b.line);
}

function escapeCell(text, max) {
  const clipped = text.length > max ? `${text.slice(0, max - 3)}...` : text;
  return clipped.replace(/\|/g, '\\|').replace(/`/g, '\'');
}

function generateReport(findings, meta = {}) {
  const header = [MARKER, '## 🤖 AI Code Review — TechNova', ''];
  const footer = [
    '',
    '---',
    `*Review automatizado (${RULES.length} regras) · ${meta.sha ? `commit \`${meta.sha.slice(0, 7)}\` · ` : ''}` +
      'complementa, mas não substitui, o review humano.*',
    '*⚠️ Falsos positivos são possíveis — para suprimir um achado legítimo, use `ai-review-ignore` na linha.*'
  ];

  if (findings.length === 0) {
    return [
      ...header,
      '✅ **Nenhum problema encontrado.**',
      '',
      'O código adicionado neste PR passou pela análise automatizada sem achados.',
      ...footer
    ].join('\n');
  }

  const count = (sev) => findings.filter(f => f.severity === sev).length;
  const criticals = count(SEVERITY.CRITICAL);

  const lines = [
    ...header,
    `**Resumo:** ${findings.length} achado(s)`,
    '',
    '| Severidade | Quantidade |',
    '|:-----------|:----------:|',
    `| ${SEVERITY.CRITICAL.label} | ${criticals} |`,
    `| ${SEVERITY.WARNING.label} | ${count(SEVERITY.WARNING)} |`,
    `| ${SEVERITY.INFO.label} | ${count(SEVERITY.INFO)} |`,
    ''
  ];

  if (criticals > 0) {
    lines.push('> ⛔ **Quality gate: BLOQUEADO.** Corrija os achados CRITICAL antes do merge.', '');
  } else {
    lines.push('> ✅ **Quality gate: APROVADO.** Sem achados CRITICAL — avalie os WARNING/INFO.', '');
  }

  lines.push(
    '### Achados',
    '',
    '| Severidade | Categoria | Arquivo | Linha | Problema | Código |',
    '|:----------:|-----------|---------|:-----:|----------|--------|'
  );

  for (const f of findings) {
    lines.push(
      `| ${f.severity.label} | ${f.category} | \`${escapeCell(f.file, 45)}\` | ${f.line} | ` +
      `${f.message} | \`${escapeCell(f.code, 50)}\` |`
    );
  }

  return [...lines, ...footer].join('\n');
}

function main() {
  const diffFile = process.env.DIFF_FILE || '/tmp/pr-diff.txt';
  const outputFile = process.env.REVIEW_OUTPUT || '/tmp/ai-review-result.md';

  const diff = fs.readFileSync(diffFile, 'utf8');
  const findings = analyzeDiff(diff);
  const report = generateReport(findings, { sha: process.env.HEAD_SHA });
  fs.writeFileSync(outputFile, report);

  const summary = {
    critical: findings.filter(f => f.severity === SEVERITY.CRITICAL).length,
    warning: findings.filter(f => f.severity === SEVERITY.WARNING).length,
    info: findings.filter(f => f.severity === SEVERITY.INFO).length
  };

  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT,
      `critical=${summary.critical}\nwarning=${summary.warning}\ninfo=${summary.info}\n`);
  }

  console.log(report);
  console.log(`\nAnálise concluída: ${summary.critical} CRITICAL, ${summary.warning} WARNING, ${summary.info} INFO`);

  if (summary.critical > 0 && process.env.FAIL_ON_CRITICAL === 'true') {
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { RULES, SEVERITY, MARKER, analyzeDiff, generateReport, maskSecrets };

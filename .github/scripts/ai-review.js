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
//   BEDROCK_MODEL_ID  se definido, também envia o diff ao Amazon Bedrock (Converse API,
//                     via AWS CLI com as credenciais da sessão do Learner Lab). Se o
//                     Bedrock falhar, o review continua só com as regras (fallback).
//   AWS_REGION        região do Bedrock (default: us-east-1)
//
// Suprimir um falso positivo: adicionar o comentário `ai-review-ignore` na linha.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

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

// ---------- Amazon Bedrock (LLM) ----------

const BEDROCK_MAX_DIFF = 12000;
const LLM_SEVERITIES = { CRITICAL: SEVERITY.CRITICAL, WARNING: SEVERITY.WARNING, INFO: SEVERITY.INFO };

function buildBedrockPrompt(diff) {
  // Chaves AWS e chaves privadas não saem do runner, nem para o Bedrock
  const safeDiff = diff
    .replace(/\b(AKIA|ASIA)[0-9A-Z]{16}\b/g, '$1****************')
    .replace(/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, '[CHAVE PRIVADA REMOVIDA]');
  const truncated = safeDiff.length > BEDROCK_MAX_DIFF;
  const body = truncated ? safeDiff.slice(0, BEDROCK_MAX_DIFF) : safeDiff;

  return {
    truncated,
    system: 'Você é um revisor de código sênior da TechNova (API Node.js/Express, Docker, Terraform). ' +
      'Analise SOMENTE as linhas adicionadas (prefixo +) do diff. Seja objetivo e não invente problemas: ' +
      'se não houver achados, responda []. Responda APENAS com um array JSON, sem texto fora dele.',
    user: 'Classifique cada achado como CRITICAL (vulnerabilidade explorável ou credencial exposta), ' +
      'WARNING (bug provável, má prática, performance, hardening) ou INFO (sugestão). ' +
      'Formato de cada item: {"file": "caminho", "line": <número da linha no arquivo novo>, ' +
      '"severity": "CRITICAL|WARNING|INFO", "category": "Segurança|Qualidade|Performance|Manutenção", ' +
      '"message": "problema e correção sugerida, em português, até 160 caracteres"}.\n\n' +
      `Diff do PR${truncated ? ` (truncado em ${BEDROCK_MAX_DIFF} caracteres)` : ''}:\n\`\`\`diff\n${body}\n\`\`\``
  };
}

function parseLlmFindings(text) {
  const start = text.indexOf('[');
  const end = text.lastIndexOf(']');
  if (start === -1 || end < start) throw new Error('resposta do modelo sem array JSON');
  const items = JSON.parse(text.slice(start, end + 1));
  if (!Array.isArray(items)) throw new Error('resposta do modelo não é um array');

  return items
    .filter(i => i && typeof i.message === 'string' && LLM_SEVERITIES[String(i.severity).toUpperCase()])
    .slice(0, 30)
    .map(i => ({
      rule: 'llm',
      category: String(i.category || 'Geral'),
      severity: LLM_SEVERITIES[String(i.severity).toUpperCase()],
      message: i.message,
      file: String(i.file || '?'),
      line: Number.isInteger(i.line) ? i.line : '?',
      code: ''
    }));
}

// Usa o AWS CLI (já presente no runner e na máquina do aluno) em vez do SDK: sem dependência npm
function reviewWithBedrock(diff, modelId, region) {
  const prompt = buildBedrockPrompt(diff);
  const input = {
    modelId,
    system: [{ text: prompt.system }],
    messages: [{ role: 'user', content: [{ text: prompt.user }] }],
    inferenceConfig: { maxTokens: 2048, temperature: 0 }
  };
  const tmp = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'bedrock-')), 'input.json');
  fs.writeFileSync(tmp, JSON.stringify(input));

  try {
    const out = execFileSync('aws', [
      'bedrock-runtime', 'converse',
      '--region', region,
      '--cli-input-json', `file://${tmp}`,
      '--output', 'json'
    ], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 90000 });
    const response = JSON.parse(out);
    const text = response.output.message.content.map(c => c.text || '').join('');
    return {
      ok: true,
      modelId,
      truncated: prompt.truncated,
      findings: parseLlmFindings(text),
      usage: response.usage
    };
  } catch (err) {
    // Sem ARN/Account ID no comentário público do PR
    const detail = String(err.stderr || err.message)
      .replace(/\s+/g, ' ')
      .replace(/.*operation: /, '')
      .replace(/arn:aws:sts::\d{12}:assumed-role\/\S+/g, '<role da sessão>')
      .replace(/arn:aws:bedrock:([\w-]+):\d{12}:/g, 'arn:aws:bedrock:$1:<conta>:')
      .trim();
    return { ok: false, modelId, error: detail.slice(0, 300) };
  } finally {
    fs.rmSync(path.dirname(tmp), { recursive: true, force: true });
  }
}

function llmSection(llm) {
  if (!llm) return [];
  if (!llm.ok) {
    return [
      '',
      '### 🧠 Análise do LLM (Amazon Bedrock)',
      '',
      `> ⚠️ Bedrock indisponível (\`${llm.modelId}\`): ${escapeCell(llm.error, 300)}`,
      '> O review acima usou só as regras (fallback).'
    ];
  }
  const lines = [
    '',
    `### 🧠 Análise do LLM (Amazon Bedrock · \`${llm.modelId}\`)`,
    '',
    '> Consultiva: os achados do LLM **não** acionam o quality gate (o modelo é não determinístico). ' +
      'Um CRITICAL aqui deve ser confirmado por um humano.'
  ];
  if (llm.truncated) lines.push(`> Diff truncado em ${BEDROCK_MAX_DIFF} caracteres.`);
  if (llm.findings.length === 0) {
    lines.push('', '✅ O modelo não apontou problemas.');
    return lines;
  }
  lines.push(
    '',
    '| Severidade | Categoria | Arquivo | Linha | Problema |',
    '|:----------:|-----------|---------|:-----:|----------|'
  );
  for (const f of llm.findings) {
    lines.push(`| ${f.severity.label} | ${escapeCell(f.category, 20)} | \`${escapeCell(f.file, 45)}\` | ${f.line} | ${escapeCell(f.message, 200)} |`);
  }
  return lines;
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
      ...llmSection(meta.llm),
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

  return [...lines, ...llmSection(meta.llm), ...footer].join('\n');
}

function main() {
  const diffFile = process.env.DIFF_FILE || '/tmp/pr-diff.txt';
  const outputFile = process.env.REVIEW_OUTPUT || '/tmp/ai-review-result.md';

  const diff = fs.readFileSync(diffFile, 'utf8');
  const findings = analyzeDiff(diff);

  let llm = null;
  if (process.env.BEDROCK_MODEL_ID) {
    llm = reviewWithBedrock(diff, process.env.BEDROCK_MODEL_ID, process.env.AWS_REGION || 'us-east-1');
    console.log(llm.ok
      ? `Bedrock (${llm.modelId}): ${llm.findings.length} achado(s) consultivo(s)`
      : `Bedrock indisponível, seguindo só com as regras: ${llm.error}`);
  }

  const report = generateReport(findings, { sha: process.env.HEAD_SHA, llm });
  fs.writeFileSync(outputFile, report);

  const summary = {
    critical: findings.filter(f => f.severity === SEVERITY.CRITICAL).length,
    warning: findings.filter(f => f.severity === SEVERITY.WARNING).length,
    info: findings.filter(f => f.severity === SEVERITY.INFO).length
  };

  if (process.env.GITHUB_OUTPUT) {
    fs.appendFileSync(process.env.GITHUB_OUTPUT,
      `critical=${summary.critical}\nwarning=${summary.warning}\ninfo=${summary.info}\n` +
      `llm=${llm ? (llm.ok ? 'ok' : 'indisponivel') : 'desligado'}\n`);
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

module.exports = { RULES, SEVERITY, MARKER, analyzeDiff, generateReport, maskSecrets, buildBedrockPrompt, parseLlmFindings };

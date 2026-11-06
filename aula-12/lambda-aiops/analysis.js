// lambda-aiops/analysis.js
// Lógica de análise compartilhada entre a Lambda (index.js) e o simulador local.
// Sem dependências: roda igual no runtime da Lambda e no Node local.

const SEVERITY_EMOJI = { P1: '🚨', P2: '⚠️', P3: '📋', P4: 'ℹ️' };

const series = (context, label) =>
  (context.metrics.find(m => m.Label === label || m.Id === label) || {}).Values || [];

const last = arr => (arr.length ? arr[arr.length - 1] : 0);
const first = arr => (arr.length ? arr[0] : 0);

// Converte o evento do EventBridge ("CloudWatch Alarm State Change") ou um evento manual
function parseAlarmEvent(event) {
  const detail = event.detail || {};
  const metric = detail.configuration?.metrics?.[0]?.metricStat?.metric || {};
  return {
    alarmName: detail.alarmName || event.alarmName || 'Unknown',
    metricName: metric.name || metric.metricName || event.metricName || 'Unknown',
    state: detail.state?.value || 'ALARM',
    previousState: detail.previousState?.value || 'OK',
    timestamp: detail.state?.timestamp || new Date().toISOString(),
    reason: detail.state?.reason || event.reason || 'Anomaly detected'
  };
}

// Fallback determinístico (sem LLM): regras de SRE sobre logs + tendência das métricas
function ruleBasedAnalysis(alarmInfo, context) {
  const logs = context.errorLogs || [];
  const has = re => logs.some(l => re.test(l));
  const latency = series(context, 'ResponseTime').concat(series(context, 'response_time'));
  const errors = series(context, 'Error5xx').concat(series(context, 'error_5xx'));
  const memory = series(context, 'MemoryUsedMB');
  const evidencias = [];

  if (has(/TypeError|ReferenceError|Cannot read prop/i) && (logs.length >= 3 || last(errors) > 10)) {
    evidencias.push('Logs com TypeError repetido no código da aplicação');
    if (last(errors) > first(errors)) evidencias.push(`Error5xx subiu de ${first(errors)} para ${last(errors)}/min`);
    if (has(/deploy|version|a12-sha-/i)) evidencias.push('Erros começaram logo depois de um deploy');
    return {
      severidade: 'P1',
      causa_raiz_provavel: 'Bug introduzido no último deploy (TypeError no código de pedidos).',
      confianca: 'alta',
      evidencias,
      acao_recomendada: 'Rollback para a imagem anterior (scripts/rollback.sh) ou desligar a feature nova via flag.',
      rollback_necessario: true,
      resumo: 'TypeError em produção após deploy — rollback recomendado'
    };
  }

  if (has(/heap|out of memory|ENOMEM|memory/i) || (memory.length > 2 && last(memory) > first(memory) * 2)) {
    if (memory.length) evidencias.push(`Memória cresceu de ${first(memory)} MB para ${last(memory)} MB sem queda`);
    evidencias.push('Logs de heap/GC indicando pressão de memória');
    return {
      severidade: 'P2',
      causa_raiz_provavel: 'Vazamento de memória: o uso cresce continuamente e a latência acompanha (GC).',
      confianca: 'media',
      evidencias,
      acao_recomendada: 'Restart do container para mitigar agora; heap snapshot para achar o vazamento. Rollback se começou no último deploy.',
      rollback_necessario: false,
      resumo: 'Provável memory leak — mitigar com restart e investigar'
    };
  }

  if (has(/timeout|pool exhausted|ECONNREFUSED|connection/i)) {
    evidencias.push('Logs com timeout/pool de conexões esgotado');
    if (latency.length) evidencias.push(`ResponseTime subiu de ${first(latency)} ms para ${last(latency)} ms`);
    return {
      severidade: 'P1',
      causa_raiz_provavel: 'Dependência lenta (banco/serviço externo): pool de conexões esgotado.',
      confianca: 'media',
      evidencias,
      acao_recomendada: 'Verificar o banco (queries lentas, conexões). Restart libera o pool; rollback não resolve problema de infra.',
      rollback_necessario: false,
      resumo: 'Timeouts de dependência — problema de infraestrutura, não de código'
    };
  }

  // 5xx alto sem stack trace nos logs: incidente real mesmo sem saber a causa.
  // Com latência alta junto (ou o alarme composto) é P1.
  if (last(errors) >= 10 || /Error5xx|Incident/.test(alarmInfo.alarmName)) {
    const slow = latency.length && last(latency) > 1000;
    if (errors.length) evidencias.push(`Error5xx em ${last(errors)}/min (limite 10/min)`);
    if (slow) evidencias.push(`ResponseTime em ${last(latency)} ms ao mesmo tempo`);
    evidencias.push('Nenhum stack trace nos logs: a causa não aparece no código');
    return {
      severidade: slow ? 'P1' : 'P2',
      causa_raiz_provavel: slow
        ? 'Degradação geral (erros + latência) sem erro de código nos logs: recurso saturado ou dependência falhando.'
        : 'Erros 5xx sem stack trace: falha em dependência ou na infraestrutura.',
      confianca: 'baixa',
      evidencias,
      acao_recomendada: 'Comparar o início com o último deploy (/version). Se coincidir, rollback; senão, checar EC2 (CPU/memória) e dependências.',
      rollback_necessario: false,
      resumo: slow ? 'Erros 5xx + latência alta — incidente P1, causa a confirmar' : `Error5xx em ${last(errors)}/min — investigar`
    };
  }

  if (latency.length && last(latency) > 1000) {
    evidencias.push(`ResponseTime em ${last(latency)} ms (limite 1000 ms) sem erros nos logs`);
    return {
      severidade: 'P2',
      causa_raiz_provavel: 'Latência alta sem erros nos logs: carga acima do normal ou recurso saturado.',
      confianca: 'baixa',
      evidencias,
      acao_recomendada: 'Conferir CPU/memória da EC2 e o volume de requests; escalar se for carga.',
      rollback_necessario: false,
      resumo: `Latência ${last(latency)} ms — investigar saturação`
    };
  }

  return {
    severidade: 'P3',
    causa_raiz_provavel: `Anomalia em ${alarmInfo.metricName} sem sinal claro nos logs.`,
    confianca: 'baixa',
    evidencias: ['Nenhum padrão conhecido nos logs dos últimos 15 min'],
    acao_recomendada: 'Análise manual: comparar com o último deploy e com o tráfego.',
    rollback_necessario: false,
    resumo: `Anomalia em ${alarmInfo.metricName} — investigação necessária`
  };
}

function buildAnalysisPrompt(alarmInfo, context) {
  const metricsStr = context.metrics
    .map(m => `${m.Label || m.Id}: [${(m.Values || []).slice(0, 15).join(', ')}]`)
    .join('\n');
  const logsStr = (context.errorLogs || []).slice(0, 15).join('\n');

  return `Você é um engenheiro SRE da TechNova analisando um incidente em produção.

ALARME:
- Nome: ${alarmInfo.alarmName}
- Métrica: ${alarmInfo.metricName}
- Estado: ${alarmInfo.previousState} -> ${alarmInfo.state}
- Timestamp: ${alarmInfo.timestamp}
- Razão: ${alarmInfo.reason}

MÉTRICAS DOS ÚLTIMOS 15 MINUTOS (1 ponto por minuto, do mais antigo ao mais recente):
${metricsStr || 'Sem dados'}

LOGS DE ERRO RECENTES:
${logsStr || 'Sem erros nos logs'}

SISTEMA: TechNova API (Node.js/Express) em Docker numa EC2, imagens no ECR,
deploy com rollback automático e feature flags FF_* (new_shipping_calc, bulk_orders).

Responda APENAS com JSON válido:
{
  "severidade": "P1|P2|P3|P4",
  "causa_raiz_provavel": "descrição concisa",
  "confianca": "alta|media|baixa",
  "evidencias": ["evidência 1", "evidência 2"],
  "acao_recomendada": "ação específica",
  "rollback_necessario": true,
  "resumo": "uma frase para a notificação"
}`;
}

// Bônus: rascunho de post-mortem gerado a partir do alarme + análise + logs
function buildPostmortem(alarmInfo, analysis, context) {
  const logs = (context.errorLogs || []).slice(0, 5).map(l => `    ${l}`).join('\n') || '    (sem logs de erro)';
  return [
    `POST-MORTEM (rascunho automático) — ${alarmInfo.alarmName}`,
    `  Início: ${alarmInfo.timestamp}`,
    `  Severidade: ${analysis.severidade} | confiança da análise: ${analysis.confianca}`,
    `  Impacto: ${analysis.resumo}`,
    `  Causa raiz provável: ${analysis.causa_raiz_provavel}`,
    `  Evidências: ${(analysis.evidencias || []).join('; ') || '-'}`,
    `  Ação tomada/recomendada: ${analysis.acao_recomendada}`,
    `  Rollback necessário: ${analysis.rollback_necessario ? 'SIM' : 'não'}`,
    '  Logs relevantes:',
    logs,
    '  Pendências: confirmar a causa com um humano, ação preventiva, atualizar o runbook.'
  ].join('\n');
}

function formatNotification(alarmInfo, analysis) {
  return `${SEVERITY_EMOJI[analysis.severidade] || '📋'} AIOps Alert — TechNova
Alarme: ${alarmInfo.alarmName} (${alarmInfo.metricName})
Severidade: ${analysis.severidade}
Resumo: ${analysis.resumo}
Causa raiz provável: ${analysis.causa_raiz_provavel}
Confiança: ${analysis.confianca} | Fonte: ${analysis.fonte || 'regras'}
Ação recomendada: ${analysis.acao_recomendada}
Rollback necessário: ${analysis.rollback_necessario ? 'SIM' : 'Não'}
Timestamp: ${alarmInfo.timestamp}`;
}

module.exports = {
  parseAlarmEvent,
  ruleBasedAnalysis,
  buildAnalysisPrompt,
  buildPostmortem,
  formatNotification
};

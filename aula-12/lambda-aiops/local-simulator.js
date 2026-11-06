#!/usr/bin/env node
// lambda-aiops/local-simulator.js
// Simulador local do fluxo AIOps (sem AWS, sem Bedrock): 3 cenários de incidente.
//
//   node local-simulator.js            → menu interativo
//   node local-simulator.js 1|2|3      → roda um cenário
//   node local-simulator.js all        → roda os três
//   node local-simulator.js 2 --prompt → imprime também o prompt para colar no Kiro AI
//
// Para cada cenário: roda a MESMA análise por regras da Lambda, compara com a análise
// esperada de um SRE e gera o rascunho de post-mortem.

const readline = require('readline');
const { ruleBasedAnalysis, buildAnalysisPrompt, buildPostmortem, formatNotification } = require('./analysis');

const now = () => new Date().toISOString();

const scenarios = {
  1: {
    id: 'high-latency',
    alarm: {
      alarmName: 'TechNova-ResponseTime-Anomaly',
      metricName: 'ResponseTime',
      state: 'ALARM',
      previousState: 'OK',
      reason: 'ResponseTime acima da banda de anomalia (2 desvios) por 2 de 3 períodos'
    },
    context: {
      metrics: [
        { Label: 'ResponseTime', Values: [120, 145, 200, 380, 520, 650, 800, 850] },
        { Label: 'Error5xx', Values: [0, 0, 0, 2, 5, 8, 12, 15] },
        { Label: 'OrdersCreated', Values: [45, 42, 38, 30, 22, 15, 8, 5] }
      ],
      errorLogs: [
        'ERROR [14:32:01] Connection timeout to database after 5000ms',
        'ERROR [14:32:15] Query execution exceeded 3s limit',
        'ERROR [14:33:02] Pool exhausted - all connections busy',
        'FATAL [14:33:45] Unable to acquire connection from pool'
      ]
    },
    expected: { severidade: 'P1', rollback_necessario: false, causa: 'pool de conexões do banco esgotado' }
  },
  2: {
    id: 'bug-no-deploy',
    alarm: {
      alarmName: 'TechNova-HighError5xx',
      metricName: 'Error5xx',
      state: 'ALARM',
      previousState: 'OK',
      reason: 'Threshold Crossed: Sum Error5xx > 10 por 2 períodos'
    },
    context: {
      metrics: [
        { Label: 'ResponseTime', Values: [150, 155, 160, 145, 155, 150] },
        { Label: 'Error5xx', Values: [1, 0, 2, 15, 28, 45] },
        { Label: 'OrdersCreated', Values: [40, 42, 38, 25, 10, 3] }
      ],
      errorLogs: [
        'INFO  [15:09:30] deploy a12-sha-9f3c2d1 concluído (anterior: a12-sha-4b7e1aa)',
        'ERROR [15:10:01] TypeError: Cannot read properties of undefined (reading \'id\')',
        'ERROR [15:10:02]     at processOrder (/app/routes/orders.js:47:23)',
        'ERROR [15:10:03] TypeError: Cannot read properties of undefined (reading \'id\')',
        'ERROR [15:10:05] TypeError: Cannot read properties of undefined (reading \'id\')'
      ]
    },
    expected: { severidade: 'P1', rollback_necessario: true, causa: 'bug no último deploy' }
  },
  3: {
    id: 'memory-leak',
    alarm: {
      alarmName: 'TechNova-HighLatency',
      metricName: 'ResponseTime',
      state: 'ALARM',
      previousState: 'OK',
      reason: 'Threshold Crossed: Average ResponseTime > 1000 por 3 períodos'
    },
    context: {
      metrics: [
        { Label: 'ResponseTime', Values: [140, 180, 260, 420, 700, 1100, 1350] },
        { Label: 'Error5xx', Values: [0, 0, 0, 1, 1, 3, 4] },
        { Label: 'MemoryUsedMB', Values: [180, 230, 290, 350, 410, 470, 505] }
      ],
      errorLogs: [
        'WARN  [16:20:11] GC pause 850ms (heap 480MB / 512MB)',
        'ERROR [16:24:40] FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory',
        'WARN  [16:25:02] container technova-api restarted (exit 134)'
      ]
    },
    expected: { severidade: 'P2', rollback_necessario: false, causa: 'vazamento de memória' }
  }
};

function run(key, showPrompt) {
  const s = scenarios[key];
  const alarm = { ...s.alarm, timestamp: now() };
  const analysis = { ...ruleBasedAnalysis(alarm, s.context), fonte: 'regras (simulador local)' };

  console.log(`\n${'='.repeat(72)}\n🧪 Cenário ${key}: ${s.id}\n${'='.repeat(72)}`);
  console.log('📊 Métricas:');
  s.context.metrics.forEach(m => console.log(`   ${m.Label.padEnd(14)} ${m.Values.join(' → ')}`));
  console.log('📜 Logs:');
  s.context.errorLogs.forEach(l => console.log(`   ${l}`));

  console.log('\n🤖 Análise:');
  console.log(JSON.stringify(analysis, null, 2));

  const okSev = analysis.severidade === s.expected.severidade;
  const okRb = analysis.rollback_necessario === s.expected.rollback_necessario;
  console.log(`\n🎯 Esperado (SRE): ${s.expected.severidade}, rollback=${s.expected.rollback_necessario}, causa: ${s.expected.causa}`);
  console.log(`   severidade ${okSev ? '✅' : '❌'} | decisão de rollback ${okRb ? '✅' : '❌'}`);

  console.log('\n📨 Notificação que iria para o SNS:\n' + formatNotification(alarm, analysis));
  console.log('\n' + buildPostmortem(alarm, analysis, s.context));

  if (showPrompt) {
    console.log('\n💬 Prompt para colar no Kiro AI (mesmo prompt que a Lambda manda ao Bedrock):\n');
    console.log(buildAnalysisPrompt(alarm, s.context));
  }
  return okSev && okRb;
}

const [arg] = process.argv.slice(2);
const showPrompt = process.argv.includes('--prompt');

if (arg === 'all') {
  const results = Object.keys(scenarios).map(k => run(k, showPrompt));
  console.log(`\n🏁 ${results.filter(Boolean).length}/${results.length} cenários com a decisão esperada`);
  process.exitCode = results.every(Boolean) ? 0 : 1;
} else if (scenarios[arg]) {
  process.exitCode = run(arg, showPrompt) ? 0 : 1;
} else {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  console.log('Cenários: 1) high-latency  2) bug-no-deploy  3) memory-leak');
  rl.question('Escolha (1-3): ', answer => {
    rl.close();
    if (!scenarios[answer]) return console.log('Opção inválida');
    run(answer, true);
  });
}

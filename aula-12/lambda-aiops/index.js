// lambda-aiops/index.js
// Lambda AIOps: recebe o alarme (EventBridge), coleta métricas e logs dos últimos 15 min,
// pede a análise ao Claude Haiku no Bedrock e notifica pelo SNS.
// Roda com a role pré-existente LabRole (o Learner Lab não cria roles IAM).
// Sem acesso ao Bedrock, cai para a análise por regras (analysis.js) — o fluxo não para.
//
// O AWS SDK v3 já vem no runtime nodejs20.x: o zip leva só index.js e analysis.js.

const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');
const { CloudWatchClient, GetMetricDataCommand } = require('@aws-sdk/client-cloudwatch');
const { CloudWatchLogsClient, FilterLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const {
  parseAlarmEvent,
  ruleBasedAnalysis,
  buildAnalysisPrompt,
  buildPostmortem,
  formatNotification
} = require('./analysis');

const REGION = process.env.AWS_REGION || 'us-east-1';
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;
const LOG_GROUP = process.env.LOG_GROUP || '/technova/api';
const ENVIRONMENT = process.env.APP_ENVIRONMENT || 'production';
const MODEL_ID = process.env.BEDROCK_MODEL_ID || 'anthropic.claude-3-haiku-20240307-v1:0';
const USE_BEDROCK = process.env.USE_BEDROCK !== 'false';

const bedrock = new BedrockRuntimeClient({ region: REGION });
const cloudwatch = new CloudWatchClient({ region: REGION });
const logs = new CloudWatchLogsClient({ region: REGION });
const sns = new SNSClient({ region: REGION });

exports.handler = async (event) => {
  console.log('📥 Evento:', JSON.stringify(event));
  const alarmInfo = parseAlarmEvent(event);

  let context = { metrics: [], errorLogs: [] };
  try {
    context = await gatherContext();
  } catch (error) {
    console.warn('⚠️ Falha ao coletar contexto:', error.message);
  }
  console.log('📊 Contexto:', JSON.stringify({
    metrics: context.metrics.map(m => ({ id: m.Id, values: m.Values })),
    errorLogs: context.errorLogs.length
  }));

  const analysis = await analyze(alarmInfo, context);
  const postmortem = buildPostmortem(alarmInfo, analysis, context);
  console.log('🤖 Análise:', JSON.stringify(analysis));
  console.log(postmortem);

  await notify(alarmInfo, analysis, postmortem);
  return { statusCode: 200, alarm: alarmInfo, analysis };
};

async function gatherContext() {
  const end = new Date();
  const start = new Date(end.getTime() - 15 * 60 * 1000);
  const query = (id, name, stat) => ({
    Id: id,
    Label: name,
    MetricStat: {
      Metric: { Namespace: 'TechNova/API', MetricName: name, Dimensions: [{ Name: 'Environment', Value: ENVIRONMENT }] },
      Period: 60,
      Stat: stat
    }
  });

  const metrics = await cloudwatch.send(new GetMetricDataCommand({
    StartTime: start,
    EndTime: end,
    ScanBy: 'TimestampAscending',
    MetricDataQueries: [
      query('response_time', 'ResponseTime', 'Average'),
      query('error_5xx', 'Error5xx', 'Sum'),
      query('orders_created', 'OrdersCreated', 'Sum')
    ]
  }));

  let errorLogs = [];
  try {
    const res = await logs.send(new FilterLogEventsCommand({
      logGroupName: LOG_GROUP,
      startTime: start.getTime(),
      endTime: end.getTime(),
      filterPattern: '?ERROR ?FATAL ?TypeError ?Exception ?timeout',
      limit: 20
    }));
    errorLogs = (res.events || []).map(e => e.message.trim());
  } catch (error) {
    console.warn('⚠️ Logs indisponíveis:', error.message);
  }

  return { metrics: metrics.MetricDataResults || [], errorLogs };
}

async function analyze(alarmInfo, context) {
  if (USE_BEDROCK) {
    try {
      const response = await bedrock.send(new InvokeModelCommand({
        modelId: MODEL_ID,
        contentType: 'application/json',
        accept: 'application/json',
        body: JSON.stringify({
          anthropic_version: 'bedrock-2023-05-31',
          max_tokens: 1024,
          messages: [{ role: 'user', content: buildAnalysisPrompt(alarmInfo, context) }]
        })
      }));
      const text = JSON.parse(new TextDecoder().decode(response.body)).content[0].text;
      const json = text.match(/\{[\s\S]*\}/);
      if (json) return { ...JSON.parse(json[0]), fonte: `bedrock:${MODEL_ID}` };
      console.warn('⚠️ Bedrock respondeu sem JSON, usando regras');
    } catch (error) {
      console.warn(`⚠️ Bedrock indisponível (${error.name}: ${error.message}) — usando análise por regras`);
    }
  }
  return { ...ruleBasedAnalysis(alarmInfo, context), fonte: 'regras (fallback sem Bedrock)' };
}

async function notify(alarmInfo, analysis, postmortem) {
  const message = `${formatNotification(alarmInfo, analysis)}\n\n${postmortem}`;
  console.log('📨 Notificação:\n' + message);
  if (!SNS_TOPIC_ARN) return;
  try {
    await sns.send(new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Subject: `[${analysis.severidade}] TechNova AIOps: ${alarmInfo.alarmName}`.slice(0, 99),
      Message: message
    }));
  } catch (error) {
    console.warn('⚠️ SNS falhou:', error.message);
  }
}

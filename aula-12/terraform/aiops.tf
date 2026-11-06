# =============================================================
# AIOps: logs, SNS, alarmes (fixo + anomaly band + composto),
# dashboard, Lambda (LabRole) e regra EventBridge
# =============================================================

locals {
  namespace = "TechNova/API"
  dims      = { Environment = "production" }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/technova/api"
  retention_in_days = 7
}

resource "aws_sns_topic" "alerts" {
  name = "technova-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- Alarmes com threshold fixo ----------

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "TechNova-HighLatency"
  alarm_description   = "Latência média > ${var.latency_threshold_ms} ms por 3 minutos consecutivos"
  namespace           = local.namespace
  metric_name         = "ResponseTime"
  dimensions          = local.dims
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.latency_threshold_ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "TechNova-HighError5xx"
  alarm_description   = "Mais de ${var.error5xx_threshold} erros 5xx por minuto em 2 minutos"
  namespace           = local.namespace
  metric_name         = "Error5xx"
  dimensions          = local.dims
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = var.error5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---------- Anomaly Detection (o detector é criado junto com o alarme) ----------

resource "aws_cloudwatch_metric_alarm" "latency_anomaly" {
  alarm_name          = "TechNova-ResponseTime-Anomaly"
  alarm_description   = "Latência acima da banda de anomalia (${var.anomaly_band_width} desvios) em 2 de 3 minutos"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold_metric_id = "ad1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      namespace   = local.namespace
      metric_name = "ResponseTime"
      dimensions  = local.dims
      period      = 60
      stat        = "Average"
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "ResponseTime (banda esperada)"
    return_data = true
  }
}

# Detector para os 5xx: aprende o baseline mesmo sem alarme ligado a ele
resource "aws_cloudwatch_metric_alarm" "error5xx_anomaly" {
  alarm_name          = "TechNova-Error5xx-Anomaly"
  alarm_description   = "Erros 5xx acima da banda de anomalia"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold_metric_id = "ad1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      namespace   = local.namespace
      metric_name = "Error5xx"
      dimensions  = local.dims
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "Error5xx (banda esperada)"
    return_data = true
  }
}

# ---------- Bônus: alarme composto (latência E erros = incidente real) ----------

resource "aws_cloudwatch_composite_alarm" "incident" {
  alarm_name        = "TechNova-Incident-LatencyAndErrors"
  alarm_description = "Latência alta (fixo ou anomalia) E erros 5xx ao mesmo tempo: incidente P1"
  alarm_rule = join(" AND ", [
    "(ALARM(\"${aws_cloudwatch_metric_alarm.high_latency.alarm_name}\") OR ALARM(\"${aws_cloudwatch_metric_alarm.latency_anomaly.alarm_name}\"))",
    "ALARM(\"${aws_cloudwatch_metric_alarm.high_5xx.alarm_name}\")"
  ])
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ---------- Bônus: dashboard ----------

resource "aws_cloudwatch_dashboard" "technova" {
  dashboard_name = "TechNova-Aula12"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ResponseTime (ms) + banda de anomalia"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            [local.namespace, "ResponseTime", "Environment", "production", { id = "m1" }],
            [{ expression = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})", id = "ad1", label = "Banda esperada" }]
          ]
          annotations = { horizontal = [{ label = "Limite fixo", value = var.latency_threshold_ms }] }
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Erros 5xx / 4xx por minuto"
          region  = var.aws_region
          view    = "timeSeries"
          stat    = "Sum"
          period  = 60
          metrics = [[local.namespace, "Error5xx", "Environment", "production"], [local.namespace, "Error4xx", "Environment", "production"]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Pedidos criados / falhos (negócio)"
          region  = var.aws_region
          view    = "timeSeries"
          stat    = "Sum"
          period  = 60
          metrics = [[local.namespace, "OrdersCreated", "Environment", "production"], [local.namespace, "OrdersFailed", "Environment", "production"]]
        }
      },
      {
        type = "alarm", x = 12, y = 6, width = 12, height = 6
        properties = {
          title = "Alarmes"
          alarms = [
            aws_cloudwatch_metric_alarm.high_latency.arn,
            aws_cloudwatch_metric_alarm.high_5xx.arn,
            aws_cloudwatch_metric_alarm.latency_anomaly.arn,
            aws_cloudwatch_metric_alarm.error5xx_anomaly.arn,
            aws_cloudwatch_composite_alarm.incident.arn
          ]
        }
      }
    ]
  })
}

# ---------- Lambda AIOps com a LabRole ----------

data "aws_iam_role" "lab" {
  name = "LabRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/.build/lambda-aiops.zip"
  source {
    content  = file("${path.module}/../lambda-aiops/index.js")
    filename = "index.js"
  }
  source {
    content  = file("${path.module}/../lambda-aiops/analysis.js")
    filename = "analysis.js"
  }
}

resource "aws_lambda_function" "aiops" {
  function_name    = "TechNovaAIOpsAnalyzer"
  description      = "Analisa alarmes TechNova-* (Bedrock Claude Haiku, fallback por regras)"
  role             = data.aws_iam_role.lab.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      SNS_TOPIC_ARN   = aws_sns_topic.alerts.arn
      LOG_GROUP       = aws_cloudwatch_log_group.api.name
      APP_ENVIRONMENT = "production"
      USE_BEDROCK     = tostring(var.use_bedrock)
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.aiops.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "alarm_to_lambda" {
  name        = "TechNova-Anomaly-Trigger"
  description = "Alarme TechNova-* em ALARM dispara a análise AIOps"
  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [{ prefix = "TechNova-" }]
      state     = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.alarm_to_lambda.name
  target_id = "AIOpsAnalyzer"
  arn       = aws_lambda_function.aiops.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "EventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aiops.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_to_lambda.arn
}

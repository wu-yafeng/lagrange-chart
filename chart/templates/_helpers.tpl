{{/*
Expand the name of the chart.
*/}}
{{- define "lagrange-onebot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lagrange-onebot.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lagrange-onebot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lagrange-onebot.labels" -}}
helm.sh/chart: {{ include "lagrange-onebot.chart" . }}
{{ include "lagrange-onebot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lagrange-onebot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagrange-onebot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lagrange-onebot.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lagrange-onebot.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate access token
*/}}
{{- define "lagrange-onebot.accessToken" -}}
{{- if .Values.config.accessToken.autoGenerate }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace (printf "%s-token" (include "lagrange-onebot.fullname" .))) }}
{{- if $existingSecret }}
{{- index $existingSecret.data "access-token" | b64dec }}
{{- else }}
{{- randAlphaNum (.Values.config.accessToken.length | int) }}
{{- end }}
{{- else }}
{{- .Values.config.accessToken.value }}
{{- end }}
{{- end }}

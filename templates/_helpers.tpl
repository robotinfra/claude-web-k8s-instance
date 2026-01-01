{{/*
Expand the name of the chart.
*/}}
{{- define "claude-web-k8s-instance.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "claude-web-k8s-instance.fullname" -}}
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
{{- define "claude-web-k8s-instance.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create default labels
*/}}
{{- define "claude-web-k8s-instance.labels" -}}
helm.sh/chart: {{ include "claude-web-k8s-instance.chart" . }}
{{ include "claude-web-k8s-instance.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create selector labels
*/}}
{{- define "claude-web-k8s-instance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "claude-web-k8s-instance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: instance
{{- end }}

{{/*
Create ServiceAccount name
*/}}
{{- define "claude-web-k8s-instance.serviceAccountName" -}}
{{- .Values.instanceName }}
{{- end }}

{{/*
Create the instance hash (SHA256 of description)
*/}}
{{- define "claude-web-k8s-instance.hash" -}}
{{- .Values.instanceDescription | sha256sum | trunc 12 }}
{{- end }}

{{/*
Get the ingress hostname
*/}}
{{- define "claude-web-k8s-instance.ingressHost" -}}
{{- if .Values.ingress.hostname }}
{{- .Values.ingress.hostname }}
{{- else }}
{{- printf "%s.dev.robotinfra.com" (include "claude-web-k8s-instance.hash" .) }}
{{- end }}
{{- end }}

{{- define "intranet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "intranet.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "intranet.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "intranet.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "intranet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default "latest" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "intranet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{- default (include "intranet.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{- default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

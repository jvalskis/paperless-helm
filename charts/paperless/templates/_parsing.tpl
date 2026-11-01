{{- define "paperless.tikaServiceName" -}}
{{- $name := .Values.tika.nameOverride | default "tika" -}}
{{- if .Values.tika.fullnameOverride -}}
{{- .Values.tika.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "paperless.gotenbergServiceName" -}}
{{- $name := .Values.gotenberg.nameOverride | default "gotenberg" -}}
{{- if .Values.gotenberg.fullnameOverride -}}
{{- .Values.gotenberg.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "paperless.dbName" -}}
{{- if .Values.database.external.enabled -}}
{{- .Values.database.external.name -}}
{{- else if .Values.cloudnativepg.enabled -}}
{{- .Values.cloudnativepg.cluster.initdb.database -}}
{{- else -}}
{{- .Values.postgresql.auth.database -}}
{{- end -}}
{{- end -}}

{{- define "paperless.dbUser" -}}
{{- if .Values.cloudnativepg.enabled -}}
{{- .Values.cloudnativepg.cluster.initdb.owner -}}
{{- else -}}
{{- .Values.postgresql.auth.username -}}
{{- end -}}
{{- end -}}

{{- define "paperless.dbHost" -}}
{{- if .Values.database.external.enabled -}}
{{- .Values.database.external.host -}}
{{- else if .Values.cloudnativepg.enabled -}}
{{- $name := .Values.cloudnativepg.fullnameOverride | default (printf "%s-cluster" .Release.Name) -}}
{{- printf "%s-rw" $name -}}
{{- else -}}
{{- .Values.postgresql.fullnameOverride | default (printf "%s-postgresql" .Release.Name) -}}
{{- end -}}
{{- end -}}

{{- define "paperless.dbSecretName" -}}
{{- if .Values.database.external.enabled -}}
  {{- .Values.database.external.existingSecret.name -}}
{{- else if .Values.cloudnativepg.enabled -}}
  {{- if and .Values.cloudnativepg.cluster.initdb.secret .Values.cloudnativepg.cluster.initdb.secret.name -}}
    {{- .Values.cloudnativepg.cluster.initdb.secret.name -}}
  {{- else -}}
    {{- $name := .Values.cloudnativepg.fullnameOverride | default (printf "%s-cluster" .Release.Name) -}}
    {{- printf "%s-app" $name -}}
  {{- end -}}
{{- else -}}
  {{- .Values.postgresql.auth.existingSecret | default (printf "%s-db-credentials" .Release.Name) -}}
{{- end -}}
{{- end -}}

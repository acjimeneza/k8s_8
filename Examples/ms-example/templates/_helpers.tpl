{{/* Ejemplo básico */}}
{{- define "example.labels" }}
  labels:
    name: {{ .Release.Name }}-conf
    generator: helm
    date: {{ now | htmlDate }}
{{- end }}
# Octava sesión - Helm 

## Step 0 - Creación de un microservicio base

Se debe construir la imagen y publicarla en un respositorio de docker, en este caso, se usara el repositorio de [Docker Hub](https://hub.docker.com/).

```
cd Step0/ms-chart
docker build -f .docker/Dockerfile -t yourhubusername/ms-chart:a1 .
docker login <registry> -u <User> -p $(registryPassword)
docker push yourhubusername/ms-chart:a1
```

Ejecutar el siguiente comando para validar la imagen generada:

```
docker run -p 5000:5000 -d yourhubusername/ms-chart:a1
```

Abrir un navegador e ingresar a Swagger. 

```
http://localhost:5000/swagger
```

## Step 1 - Creeación de un chart básico

Validar que tienen instalado [Helm](https://helm.sh/docs/intro/install/), para esto, solo se debe ejecutar el siguiente comando:

```
helm version
```

Una vez validada la información, vamos a crear la carpeta donde se va a crear nuestro chart.

```
mkdir siigo_chart
cd siigo_chart

helm create ms-chart
```

Borrar todos los ficheros creados dentro de la carpeta `template`, y luego crear los siguientes archivos **Deployment.yaml** y **service.yaml** con la siguiente información:

### Deployment.yaml

Agregar este código al archivo **Deployment.yaml**:

```
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: name-deploy
  labels:
    app: name-app
spec:
  selector:
    matchLabels:
      app: name-app
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: name-app
    spec:
      containers:
        - name: name-app
          image: acjimeneza/ms-chart:a1
          imagePullPolicy: Always
          ports:
            - containerPort: 5000
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "256Mi"
              cpu: "500m"
```

### service.yaml

Agregar este código al archivo **service.yaml**:

```
apiVersion: v1
kind: Service
metadata:
  name: name-service
  labels:
    app: name-app
spec:
  type: LoadBalancer
  selector:
    app: name-app
  ports:
    - protocol: TCP
      name: http
      port: 8000
      targetPort: 5000

```

### Testing the chart

Dentro de la carpeta `Step1/siigo_chart` ejecutar el siguiente comando `helm template ms-chart ms-chart`. Esto mostrara en la consola el resultado previo antes de la ejecución en el cluster.

Despues de validar los resultados en la consola, se puede realizar la instalación en el cluster con el siguiente comando `helm install ms-chart ms-chart`.

### Validando la instalación

1. Estado del despleigue de Helm: `helm ls` -> Lista todos los despliegues realizados, junto con su estado.
1. Validar el estado del despliegue en el cluster: `kubectl get deploy`
1. Validar el estado del servicio en el cluster: `kubectl get service`

## Step 2 - Agregar variables declarativas

### Cambiar las etiquetas y los nombres usados en los despliegues:

Reemplazar el cambio de los nombres con la respectiva etiqueta {{Release.name}}, por ejemplo:

```
apiVersion: v1
kind: Service
metadata:
  name: {{.Release.Name}}
  labels:
    app: {{.Release.Name}}
```

Validar el proceso de cambio de etiqueta usando el siguiente comando `helm upgrade ms-chart ms-chart`

### Cambiar los limiter de los recursos

Despues de validar los cambios, realicemos una declaración condicional en Helm, para eso se deben agregar las sigueintes lineas en el archivo `values.yaml`:

```
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

Y luego agregar las siguientes lineas al archivo`deployment.yaml`.

```
resources:
  {{- if .Values.resources }}
  {{- toYaml .Values.resources | nindent 12}}
  {{- else }}
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100"
  {{- end}}
```

### Agregar un archivo de configuración para nuestro proyecto (Config Map)

Crear un archivo con el nombre`configmap.yaml` y agregar el siguiente comando:

```
{{- if .Values.environmentVar}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-conf
data:
  {{- range $key,$value := .Values.environmentVar}}
  {{ $key }} : {{ $value | quote }}
  {{- end}}
{{- end}}
```

Agregar las sisguientes lineas al archivo`deployment.yaml` esto permite la conexión del ConfigMap con el contenedor:

```
{{- if .Values.environmentVar }}
envFrom:
- configMapRef:
    name: {{ .Release.Name }}-conf
    optional: true
{{- end}}
```

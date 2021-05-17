# kube-logrotate

Build the image:

```console
$ docker build -t emandret/kube-logrotate:latest .
```

The s6-overlay includes [s6](https://skarnet.org/software/s6/overview.html) and configures s6-svscan and s6-supervise to manage init daemons. Init daemons can be configured in `/etc/services.d` (see the `rootfs` folder).

Create the ConfigMaps to store the configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logrotate
data:
  docker-logs.conf: |
    /var/lib/docker/containers/*/*.log {
      copytruncate
      daily
      dateext
      missingok
      nocompress
      rotate 5
    }
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: logrotate-cronjob
data:
  # Run every quarter hour
  logrotate: |
    */15 * * * * root /usr/sbin/logrotate /etc/logrotate.conf
```

Create the DaemonSet to schedule a Pod on every Node:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-logrotate
  namespace: kube-system
  labels:
    k8s-app: kube-logrotate
spec:
  selector:
    matchLabels:
      name: kube-logrotate
  template:
    metadata:
      labels:
        name: kube-logrotate
    spec:
      containers:
        - name: kube-logrotate
          image: emandret/kube-logrotate
          resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 200Mi
          volumeMounts:
            - name: logrotate-conf
              mountPath: /etc/logrotate.d
              readOnly: true
            - name: cronjob-conf
              mountPath: /etc/cron.d/logrotate
              readOnly: true
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
      restartPolicy: Always
      dnsPolicy: Default
      terminationGracePeriodSeconds: 30
      volumes:
        - name: logrotate-conf
          configMap:
            name: logrotate
        - name: cronjob-conf
          configMap:
            name: logrotate-cronjob
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

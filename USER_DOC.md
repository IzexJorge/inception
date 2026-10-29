



You can easily check if you can access the website by asking only for the HTTPS header.

```bash
curl -vkI https://jescuder.42.fr 2>&1
```

With `grep` you can see just the SSL/TLS certificate line.

```bash
curl -vkI https://jescuder.42.fr 2>&1 | grep -E "SSL connection"
```
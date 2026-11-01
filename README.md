# Paperless Helm chart

Paperless is a community-supported supercharged document management system: scan, index and archive all your documents

# Paperless project

https://github.com/paperless-ngx/paperless-ngx

## Database options

The chart uses Paperless's SQLite database by default and stores it in the `data` volume. Choose a database configuration with these values:

- **Bundled PostgreSQL:** set `postgresql.enabled: true`. Set `postgresql.auth.password`, or set `postgresql.auth.existingSecret` to a Secret with `password` and `postgres-password` keys. The default database and user are both `paperless`.
- **Bundled CloudNativePG:** install the CloudNativePG operator, then set `cloudnativepg.enabled: true`. The chart uses the generated application credentials Secret. To supply one instead, set `cloudnativepg.cluster.initdb.secret.name` to a Secret with `username` and `password` keys.
- **External PostgreSQL or MariaDB:** leave both bundled options disabled and set `database.external.enabled: true`. Set `database.external.engine` to `postgresql` or `mariadb`, then provide a host, database name, and a pre-existing Secret containing the username and password. Their default ports are 5432 and 3306 respectively; set `database.external.port` to override either port.

For example:

```yaml
database:
  external:
    enabled: true
    engine: postgresql
    host: postgres.example.test
    name: paperless
    existingSecret:
      name: paperless-db-credentials
      usernameKey: username
      passwordKey: password
```

Only one database option may be enabled. The chart sets Paperless's database connection variables automatically for the selected option. Direct `controllers.main.containers.main.env` overrides remain available. To use an existing SQLite database file, mount its volume as `persistence.data` so that the file is available at `/usr/src/paperless/data/db.sqlite3`. Changing the database engine of an existing installation requires migrating its data separately.

If upgrading from values that use `cluster:`, rename that key to `cloudnativepg:`. The chart rejects the old key to prevent an accidental switch to SQLite.

## Office documents and email parsing

Set both `tika.enabled: true` and `gotenberg.enabled: true` to install [Apache Tika](https://github.com/apache/tika-helm) and [Gotenberg](https://github.com/MaikuMori/helm-charts/tree/master/charts/gotenberg) with Paperless. The chart then enables Paperless's Tika integration and sets the in-cluster service endpoints automatically:

```yaml
tika:
  enabled: true
gotenberg:
  enabled: true
```

Both services are disabled by default. Gotenberg's bundled configuration disables JavaScript and limits Chromium file access to `/tmp`, which is useful when converting email. If using an external Tika or Gotenberg server, set the corresponding `PAPERLESS_TIKA_ENDPOINT` or `PAPERLESS_TIKA_GOTENBERG_ENDPOINT` under `controllers.main.containers.main.env`. You can enable only one bundled service when the other endpoint is provided explicitly. Explicit Paperless environment values take precedence over chart-generated values.
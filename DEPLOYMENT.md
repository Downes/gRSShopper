# Deployment Notes (Docker)

This repository is deployed using Docker Compose on a VPS.

## Overview

- The application is a legacy Perl CGI app (gRSShopper).
- Apache runs from the official `httpd:2.4` image.
- Perl modules are split between:
  - **System packages** installed via `apt` in the Dockerfile
  - **Local modules** under `site/cgi-bin/modules/` (runtime, not committed)

## Important Paths (inside container)

- Document root:  
  `/usr/local/apache2/htdocs/`

- CGI directory:  
  `/usr/local/apache2/htdocs/cgi-bin/`

- Runtime data directory (NOT in Git):  
  `/usr/local/apache2/htdocs/cgi-bin/data/`

The application must use container-native paths.  
Host-style paths such as `/home/*/public_html` are **not valid** in Docker.

## gRSShopper Configuration

- `st_cgif` is resolved at runtime and must point to:  
  `/usr/local/apache2/htdocs/cgi-bin/`

- Environment-specific configuration (including database credentials) lives in:  
  `site/cgi-bin/data/multisite.txt`

  This file is **intentionally excluded from Git**.

  Format for multisite.txt is:
  __SITEURL__	__DBNAME__	127.0.0.1	__DBUSER__	__DBPASS__	en
  Values are tab delimited
  one line for each site url


## Perl Modules

- Most Perl dependencies are installed via Debian packages in the Dockerfile.
- Some CPAN-only or local modules (e.g. custom `Blockchain.pm`) live under:  
  `site/cgi-bin/modules/`

- The `modules/` directory is **generated at runtime** and is ignored by Git.

## Rebuild / Restart

To rebuild the application image:

```sh
docker compose build
docker compose up -d


## To restart Apache inside the running container:
docker exec -it grsshopper-grsshopper-1 /usr/local/apache2/bin/apachectl -k restart

## Test server environment
[site_url]/cgi-bin/server_test_basic.cgi



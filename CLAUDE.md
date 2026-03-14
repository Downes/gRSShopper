# gRSShopper (/srv/apps/grsshopper)

## Overview
Perl/Apache CMS and RSS aggregation system.
GitHub: https://github.com/Downes/gRSShopper (branch: Live)

## Container
- Name: grsshopper-grsshopper-1  Port: 80
- Serves: www.downes.ca, change.mooc.ca, ethics.mooc.ca, el30.mooc.ca,
  cck11.mooc.ca, cck12.mooc.ca, connect.downes.ca, eadcm.downes.ca,
  grsshopper.downes.ca, fallacies.ca

## Volumes
- ./site → /usr/local/apache2/htdocs  (generated content — do not delete)
- /srv/www → /srv/www  (shared static files, read-write)

## Generated Content
Files in site/feed/, site/post/, site/news/ are gitignored and generated at runtime.
Do not delete them.

## Networks
- web (external), db (external)

## Database
- Engine: MariaDB (not MySQL) — use `mariadb` client, not `mysql`
- Container: grsshopper-mariadb
- Multiple databases exist (downes, el30_mooc_ca, ethics, fallacy, plenk, etc.) — each site has its own DB
- **Always ask which site/database is in scope before running queries**
- Credentials in: `/usr/local/apache2/htdocs/cgi-bin/data/multisite.txt` (inside app container)
- The `mysql` client is not available in the app container (grsshopper-grsshopper-1); run DB queries via grsshopper-mariadb

## Language
Perl. Maintain existing code conventions.

## Adding External Service Accounts
External service credentials are stored in the site config table and exposed in the Admin UI under **Social → Accounts**. To add a new service:

1. Add a new `admin_configtable` block in the Accounts section of `site/cgi-bin/admin.cgi` (around line 614):
   ```perl
   $content .= &admin_configtable($dbh,$query,"Service Name",
       ("Label:config_key","Label2:config_key2"));
   ```
   Each field is `"Label:config_key"` — the key becomes `$Site->{config_key}` in Perl code.
2. Optionally append a `$content .= qq|...|` line after for a link or usage note.
3. Values are saved to the site config table automatically — no schema changes needed.

Example (Amazon SES, already in place):
```perl
$content .= &admin_configtable($dbh,$query,"Amazon SES",
    ("SMTP User:ses_smtp_user","SMTP Password:ses_smtp_password","SMTP Server:ses_smtp_server"));
```
Accessed in code as `$Site->{ses_smtp_user}`, `$Site->{ses_smtp_password}`, etc.

## Admin Panel Architecture

The UI is a single-page app in `site/PLE.html`. Admin panels are loaded asynchronously into named divs via `openDiv()` in `site/assets/js/grsshopper_admin.js`.

### How tabs work
- `main_window($tabs, $starting_tab)` in `site/cgi-bin/editor/editor.pl` generates the tab shell: tab buttons and content divs
- Tab buttons call `openTab(event, 'mainWindow$tab', 'editorlinks')`
- Content divs have id `mainWindow$tab` (e.g. `mainWindowNewsletters`)
- Each tab's content is rendered server-side by `Tab_$tab()` in `site/cgi-bin/editor/tabs.pl`
- The starting tab gets `style="display:block"`, others `style="display:none"`

### Known timing quirk
`openDiv()` calls `openTab()` immediately but the `.load()` is async — on first load the tab switch may fire before content exists. A page reload resolves it. Don't chase this as a bug.

### Admin panel contexts (api.cgi commands)
- `cmd=admin` → tabs: Database, API, Harvester, Newsletters, Users, Permissions, Logs, General
- `cmd=social` → tabs: Sharing, Subscribers, Newsletters, Accounts, Meetings
- `cmd=publishing` → tabs: Subscribers, Newsletters, Accounts, Meetings (default starting tab: Newsletters)

### Newsletter tab specifically
- `Tab_Newsletters` renders an `<iframe src="admin.cgi?action=newsletters">`
- `admin_newsletters()` in admin.cgi handles that iframe request
- Newsletter dropdown shows only pages with `page_sub='yes'` in the DB
- Direct URL: `https://www.downes.ca/cgi-bin/admin.cgi?action=newsletters`

## Perl Module Policy
Whenever a new Perl module is used in gRSShopper code:
1. Add it to the `@modules` list in `site/cgi-bin/server_test_basic.cgi`
2. Add it to the Dockerfile — prefer `apt-get install lib<name>-perl` for Debian packages,
   or `cpanm` for CPAN-only modules
Dockerfile changes take effect the next time the image is built and deployed. No immediate rebuild is required though it might be necessary to install the module in the current running container.

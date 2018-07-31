SuiteCRM - CRM for the world
============================

`SuiteCRM`_ is a free and open source alternative customer 
relationship management (CRM) to Salesforce, Dynamics and other 
proprietary software. Feature rich, powerful, flexible and 
user-friendly, it is one of the most popular CRM applications 
globally.

SuiteCRM is SugarCRM supercharged. It's SugarCRM Community Edition (no
longer available) with Products, Quotes, Contracts, Projects, Reporting,
Teams, Workflow, Portal, Maps, Events, greatly improved Cases and enhanced
Search.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- SuiteCRM configurations:
   
   - Installed from upstream source code to /var/www/suitecrm
   - Includes cronjob to trigger SuiteCRM cron tasks.
   - Web-folder permissions can be configured via confconsole:
         System settings > Suitecrm permissions

   **Security note**: Updates to SuiteCRM may require supervision so
   they **ARE NOT** configured to install automatically. See `SuiteCRM
   documentation`_ for upgrading.

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Adminer: username **adminer**
-  SuiteCRM: username **admin**

.. _SuiteCRM: https://www.suitecrm.com
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Adminer: https://www.adminer.org/
.. _SuiteCRM documentation: https://docs.suitecrm.com/admin/installation-guide/upgrading/

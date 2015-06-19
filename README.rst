SuiteCRM - CRM for the world
============================

`SuiteCRM`_ is a free and open source alternative customer 
relationship management (CRM) to Salesforce, Dynamics and other 
proprietary software. Feature rich, powerful, flexible and 
user-friendly, it is one of the most popular CRM applications 
globally.

SuiteCRM is SugarCRM supercharged. It's SugarCRM Community Edition with
Products, Quotes, Contracts, Projects, Reporting, Teams, Workflow,
Portal, Maps, Events, greatly improved Cases and enhanced Search.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- SuiteCRM configurations:
   
   - Installed from upstream source code to /var/www/suitecrm
   - Includes cronjob to trigger SuiteCRM cron tasks.

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL, phpMyAdmin: username **root**
-  SuiteCRM: username **admin**


.. _SuiteCRM: http://www.suitecrm.com
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _Adminer: http://www.adminer.org/

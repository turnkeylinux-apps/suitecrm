SugarCRM - Business & Social CRM software
=========================================

`SugarCRM`_ is an affordable and easy to use customer relationship
management (CRM) platform, designed to help your business communicate
with prospects, share sales information, close deals and keep customers
happy. Thousands of successful companies use Sugar everyday to manage
sales, marketing and support.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- SugarCRM configurations:
   
   - Installed from upstream source code to /var/www/sugarcrm
   - Includes cronjob to trigger SugarCRM cron tasks.

- SSL support out of the box.
- `PHPMyAdmin`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL, phpMyAdmin: username **root**
-  SugarCRM: username **admin**


.. _SugarCRM: http://www.sugarcrm.com
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _PHPMyAdmin: http://www.phpmyadmin.net

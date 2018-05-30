#!/usr/bin/python
"""Set SuiteCRM admin password

Option:
    --pass=     unless provided, will ask interactively
    --domain=   unless provided, will ask interactively
                DEFAULT=www.example.com
"""

import sys
import getopt
import hashlib

from dialog_wrapper import Dialog
from mysqlconf import MySQL

def usage(s=None):
    if s:
        print >> sys.stderr, "Error:", s
    print >> sys.stderr, "Syntax: %s [options]" % sys.argv[0]
    print >> sys.stderr, __doc__
    sys.exit(1)

DEFAULT_DOMAIN="www.example.com"


def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'domain='])
    except getopt.GetoptError, e:
        usage(e)

    password = ""
    domain = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val
        elif opt == '--domain':
            domain = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "SuiteCRM Password",
            "Enter new password for the SuiteCRM 'admin' account.")

    if not domain:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        domain = d.get_input(
            "SuiteCRM Domain",
            "Enter the domain to serve SuiteCRM.",
            DEFAULT_DOMAIN)

    if domain == "DEFAULT":
        domain = DEFAULT_DOMAIN

    with open('/var/www/suitecrm/config.php', 'r') as file :
        filedata = file.read()
        filedata = filedata.replace('http://127.0.0.1', domain)
    with open('/var/www/suitecrm/config.php', 'w') as file:
        file.write(filedata)

    hash_pass = hashlib.md5(password).hexdigest()

    m = MySQL()
    m.execute('UPDATE suitecrm.users SET user_hash=\"%s\" WHERE user_name=\"admin\";' % hash_pass)

if __name__ == "__main__":
    main()


#!/usr/bin/python3
"""Set SuiteCRM admin password

Option:
    --pass=     unless provided, will ask interactively
    --domain=   unless provided, will ask interactively
                DEFAULT=www.example.com
"""

import sys
import getopt
import bcrypt
from hashlib import md5

from libinithooks.dialog_wrapper import Dialog
from mysqlconf import MySQL
import subprocess

DEFAULT_DOMAIN="www.example.com"


def usage(s=None):
    if s:
        print("Error:", s, file=sys.stderr)
    print(f"Syntax: {sys.argv[0]} [options]", file=sys.stderr)
    print(__doc__, file=sys.stderr)
    sys.exit(1)


def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'domain='])
    except getopt.GetoptError as e:
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

    for conf in ['config.php', 'config_si.php']:
        conf = f'/var/www/suitecrm/public/legacy/{conf}'
        with open(conf, 'r') as fob:
            new_contents = []
            for line in fob:
                newline = ''
                if 'site_url' in line:
                    _lchar = ''
                    for char in line:
                        newline = f"{newline}{char}"
                        if _lchar == '=' and char == '>':
                            newline = f"{newline} '{domain}',\n"
                            break
                        _lchar = char
                    if newline:
                        new_contents.append(newline)
                else:
                    new_contents.append(line)

        if new_contents:
            with open(conf, 'w') as fob:
                fob.writelines(new_contents)

    # For some weird reason SuiteCRM MD5 hashes the password first?!
    password_md5 = md5(password.encode()).hexdigest()
    hash_pass = subprocess.run([
        'php', '-r', f'print(password_hash($argv[1], PASSWORD_BCRYPT));',
        password_md5
    ], capture_output=True).stdout

    m = MySQL()
    m.execute('UPDATE suitecrm.users SET user_hash=%s WHERE user_name=\"admin\";', (hash_pass,))


if __name__ == "__main__":
    main()

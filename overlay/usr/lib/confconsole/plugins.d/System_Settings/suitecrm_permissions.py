'''Update crm folder permissions'''

import os
from os import path
import subprocess

TITLE = 'Update CRM Folder Permissions'
TEXT = 'The permissions in the SuiteCRM appliance do not currently support updates via WebUI. Here you can setup permissions to use the WebUI to upgrade SuiteCRM.'

def run():
    retcode, choice = console.menu(TITLE, TEXT, [
        ('Default', "Safe and Default TurnKey permission settings"),
        ('Risky', "Set risky settings required for updating via WebUI.")
    ])
    if choice:
        cmd = path.join(path.dirname(__file__), 'suitecrm_permissions.sh')
        subprocess.run([cmd, choice])
        console.msgbox(TITLE, choice + ' settings was set.')
        return


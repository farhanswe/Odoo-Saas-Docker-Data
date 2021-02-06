#!/bin/bash

#set -e

echo "Entering The entrypoint.sh"
echo "Setting up Pip3 dependency if any"

if [ -f /mnt/extra-addons/requirements.txt ];
then
        pip3 install -r /mnt/extra-addons/requirements.txt
fi

echo "Call sent for starting Odoo"

while true; do /bin/bash run_odoo.sh; echo "Odoo Exited"; done


echo "Start the Exta bash"
exec /bin/bash

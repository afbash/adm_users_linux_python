#!/bin/bash

# Nombre del proyecto
PROJECT_NAME="adm_users_linux_python"

# Crear directorios
mkdir -p $PROJECT_NAME/{src/{ssh_connection,user_operations,permissions_management,reporting},docs}

# Crear un entorno virtual
cd $PROJECT_NAME
python3 -m venv venv
source venv/bin/activate

# Instalar librerías necesarias
pip install paramiko click colorama prettytable

# Crear archivo README
cat <<EOL > README.md
# $PROJECT_NAME

Este proyecto permite administrar usuarios en servidores Linux remotos a través de SSH. Implementa funcionalidades como alta, baja, modificación de usuarios, gestión de permisos y reportes de actividad.

## Requisitos

- Python 3
- Librerías: paramiko, click, colorama, prettytable

## Instalación

1. Clonar el repositorio.
2. Crear un entorno virtual y activarlo:
   \`\`\`
   python3 -m venv venv
   source venv/bin/activate
   \`\`\`
3. Instalar las dependencias:
   \`\`\`
   pip install -r requirements.txt
   \`\`\`

## Uso

Ejecutar el comando:
\`\`\`
python main.py
\`\`\`
EOL

# Crear archivo requirements.txt
cat <<EOL > requirements.txt
paramiko
click
colorama
prettytable
EOL

# Crear archivo main.py
cat <<EOL > src/main.py
import click
from colorama import init, Fore
from ssh_connection.ssh_connection import SSHConnection
from user_operations.user_operations import manage_users, list_users, view_user_details
from permissions_management.permissions_management import manage_permissions
from reporting.reporting import view_reports

# Inicializar colorama
init(autoreset=True)

@click.group()
def cli():
    pass

@cli.command()
def start():
    print(Fore.GREEN + "Bienvenido al sistema de administración de usuarios.")
    
    ip = input("Ingrese la IP del servidor: ")
    ssh_conn = SSHConnection(ip)
    
    if ssh_conn.connect():
        while True:
            print(Fore.CYAN + """
            Menú principal:
            0: Gestión de usuarios (Alta/Baja/Modificación)
            1: Listar usuarios del sistema
            2: Ver detalles de usuario específico
            3: Gestión de permisos
            4: Ver reportes de actividad
            5: Salir
            """)
            option = input(Fore.YELLOW + "Seleccione una opción: ")
            if option == "0":
                manage_users(ssh_conn)
            elif option == "1":
                list_users(ssh_conn)
            elif option == "2":
                view_user_details(ssh_conn)
            elif option == "3":
                manage_permissions(ssh_conn)
            elif option == "4":
                view_reports(ssh_conn)
            elif option == "5":
                print(Fore.GREEN + "Saliendo del sistema...")
                break
            else:
                print(Fore.RED + "Opción no válida. Intente nuevamente.")
    else:
        print(Fore.RED + "Error al conectar con el servidor.")

if __name__ == "__main__":
    cli()
EOL

# Crear archivo ssh_connection.py
cat <<EOL > src/ssh_connection/ssh_connection.py
import paramiko
from colorama import Fore

class SSHConnection:
    def __init__(self, ip):
        self.ip = ip
        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    def connect(self):
        try:
            user = input(Fore.YELLOW + "Ingrese el usuario SSH: ")
            password = input(Fore.YELLOW + "Ingrese la contraseña SSH: ")
            self.ssh_client.connect(self.ip, username=user, password=password)
            print(Fore.GREEN + "Conexión SSH exitosa.")
            return True
        except Exception as e:
            print(Fore.RED + f"Error al conectar con el servidor: {e}")
            return False

    def execute_command(self, command):
        stdin, stdout, stderr = self.ssh_client.exec_command(command)
        return stdout.read().decode(), stderr.read().decode()
EOL

# Crear archivo user_operations.py
cat <<EOL > src/user_operations/user_operations.py
from colorama import Fore
from prettytable import PrettyTable

def manage_users(ssh_conn):
    print(Fore.GREEN + "Gestión de usuarios:")
    while True:
        print(Fore.CYAN + """
        0: Alta de usuario
        1: Baja de usuario
        2: Modificación de usuario
        3: Volver al menú principal
        """)
        option = input(Fore.YELLOW + "Seleccione una opción: ")
        if option == "0":
            username = input("Ingrese el nombre de usuario: ")
            password = input("Ingrese la contraseña: ")
            primary_group = input("Ingrese el grupo primario: ")
            ssh_conn.execute_command(f"sudo useradd -m -g {primary_group} {username}")
            ssh_conn.execute_command(f"echo '{username}:{password}' | sudo chpasswd")
            print(Fore.GREEN + f"Usuario {username} creado.")
        elif option == "1":
            username = input("Ingrese el nombre de usuario a eliminar: ")
            backup_home = input("¿Desea hacer un backup del home? (s/n): ")
            if backup_home.lower() == "s":
                ssh_conn.execute_command(f"sudo tar czf /backup/{username}.tar.gz /home/{username}")
            ssh_conn.execute_command(f"sudo userdel -r {username}")
            print(Fore.GREEN + f"Usuario {username} eliminado.")
        elif option == "2":
            username = input("Ingrese el nombre de usuario a modificar: ")
            new_password = input("Ingrese la nueva contraseña: ")
            ssh_conn.execute_command(f"echo '{username}:{new_password}' | sudo chpasswd")
            print(Fore.GREEN + f"Contraseña del usuario {username} actualizada.")
        elif option == "3":
            break
        else:
            print(Fore.RED + "Opción no válida. Intente nuevamente.")

def list_users(ssh_conn):
    print(Fore.GREEN + "Listar usuarios:")
    stdout, _ = ssh_conn.execute_command("cut -d: -f1 /etc/passwd")
    users = stdout.splitlines()
    table = PrettyTable()
    table.field_names = ["Usuario"]
    for user in users:
        table.add_row([user])
    print(table)

def view_user_details(ssh_conn):
    print(Fore.GREEN + "Ver detalles de usuario:")
    username = input("Ingrese el nombre de usuario: ")
    stdout, _ = ssh_conn.execute_command(f"id {username}")
    print(Fore.CYAN + stdout)
EOL

# Crear archivo permissions_management.py
cat <<EOL > src/permissions_management/permissions_management.py
from colorama import Fore

def manage_permissions(ssh_conn):
    print(Fore.GREEN + "Gestión de permisos:")
    username = input("Ingrese el nombre de usuario: ")
    sudo_access = input("¿Desea dar permisos sudo? (s/n): ")
    if sudo_access.lower() == "s":
        ssh_conn.execute_command(f"sudo usermod -aG sudo {username}")
        print(Fore.GREEN + f"Permisos sudo otorgados a {username}.")
    else:
        ssh_conn.execute_command(f"sudo deluser {username} sudo")
        print(Fore.GREEN + f"Permisos sudo eliminados para {username}.")
EOL

# Crear archivo reporting.py
cat <<EOL > src/reporting/reporting.py
from colorama import Fore

def view_reports(ssh_conn):
    print(Fore.GREEN + "Reportes de actividad:")
    print(Fore.CYAN + "Últimos inicios de sesión:")
    stdout, _ = ssh_conn.execute_command("last")
    print(Fore.YELLOW + stdout)
EOL

echo "Proyecto '$PROJECT_NAME' creado con éxito."


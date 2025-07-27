import subprocess
import sys
import os
import tkinter as tk
from tkinter import messagebox, scrolledtext

# --- Funciones de Utilidad (sin cambios, salvo print por log_message) ---

def log_message(message, color="black"):
    """Muestra un mensaje en el área de texto de la GUI y en la consola."""
    text_area.configure(state='normal')
    text_area.insert(tk.END, message + "\n", color)
    text_area.configure(state='disabled')
    text_area.see(tk.END) # Auto-scroll
    print(message) # También lo imprime en la consola para depuración

def run_command(command, error_message):
    """Ejecuta un comando del sistema y maneja errores, mostrando la salida en la GUI."""
    log_message(f"Ejecutando: {command}", "blue")
    try:
        process = subprocess.run(command, check=True, shell=True, capture_output=True, text=True)
        log_message(f"Salida: {process.stdout}", "gray")
        log_message(f"✅ Comando ejecutado exitosamente.", "green")
        return True
    except subprocess.CalledProcessError as e:
        log_message(f"❌ Error: {error_message}", "red")
        log_message(f"Comando fallido: {command}", "red")
        log_message(f"Salida de error (stdout): {e.stdout}", "red")
        log_message(f"Salida de error (stderr): {e.stderr}", "red")
        messagebox.showerror("Error de Instalación", f"Un comando falló: {error_message}\nVer logs para más detalles.")
        return False

def check_sudo():
    """Verifica si el script se está ejecutando con sudo."""
    if os.geteuid() != 0:
        messagebox.showerror("Error de Permisos", "Este script debe ejecutarse con privilegios de sudo.")
        sys.exit(1)

def install_package(package_name):
    """Instala un paquete APT."""
    log_message(f"\n--- Intentando instalar {package_name} ---")
    if not run_command(f"apt update", f"Error al actualizar la lista de paquetes para {package_name}."):
        return False
    if not run_command(f"apt install -y {package_name}", f"Error al instalar {package_name}."):
        return False
    return True

# --- Funciones de Instalación (Adaptadas para la GUI) ---

def install_apache_gui():
    """Instala y configura Apache2."""
    log_message("\n--- Iniciando Instalación de Apache2 ---")
    if not install_package("apache2"):
        return False
    if not run_command("systemctl enable apache2", "Error al habilitar Apache2."):
        return False
    if not run_command("systemctl start apache2", "Error al iniciar Apache2."):
        return False
    log_message("Apache2 instalado y corriendo.", "green")
    return True

def install_mysql_gui():
    """Instala y configura MySQL Server."""
    log_message("\n--- Iniciando Instalación de MySQL Server ---")
    if not install_package("mysql-server"):
        return False
    log_message("MySQL Server instalado.", "green")
    log_message("¡IMPORTANTE! Por favor, ejecuta 'sudo mysql_secure_installation' manualmente después para asegurar tu instalación de MySQL.", "orange")
    return True

def install_php_version_gui(version):
    """Instala una versión específica de PHP y módulos comunes."""
    log_message(f"\n--- Iniciando Instalación de PHP {version} ---")
    
    # Añadir repositorio PPA para versiones de PHP no nativas en Ubuntu LTS
    # Ajustar según las versiones que necesites
    if version.startswith("8.") or version.startswith("7.4"): 
        log_message("Añadiendo repositorio PPA para PHP...")
        if not run_command("apt update", "Error al actualizar apt después de añadir PPA."):
            return False
        if not run_command("apt install -y software-properties-common", "Error al instalar software-properties-common."):
            return False
        if not run_command("add-apt-repository -y ppa:ondrej/php", "Error al añadir el PPA de PHP."):
            return False
        if not run_command("apt update", "Error al actualizar apt después de añadir PPA."):
            return False
    
    php_packages = [
        f"php{version}",
        f"php{version}-cli",
        f"php{version}-fpm",
        f"php{version}-mysql",
        f"php{version}-mbstring",
        f"php{version}-xml",
        f"php{version}-zip",
        f"php{version}-gd",
        f"php{version}-curl",
    ]
    for pkg in php_packages:
        if not install_package(pkg):
            return False

    log_message(f"Configurando PHP-FPM {version}...", "blue")
    if not run_command(f"systemctl enable php{version}-fpm", f"Error al habilitar php{version}-fpm."):
        return False
    if not run_command(f"systemctl start php{version}-fpm", f"Error al iniciar php{version}-fpm."):
        return False
    log_message(f"PHP {version} instalado y configurado con PHP-FPM.", "green")
    return True

def configure_apache_php_fpm_gui(php_version):
    """Configura Apache para usar PHP-FPM para una versión específica."""
    log_message(f"\n--- Configurando Apache para PHP {php_version} FPM ---", "blue")

    if not run_command("a2enmod proxy_fcgi setenvif", "Error al habilitar módulos proxy_fcgi/setenvif."):
        return False
    # Deshabilitar cualquier otra configuración predeterminada de PHP-FPM para evitar conflictos
    if not run_command("a2disconf 'php*-fpm' --quiet", "Error al deshabilitar configuraciones PHP-FPM antiguas."):
         # Usamos --quiet para que no pida confirmación si el módulo ya no existe
        pass # No consideramos esto un fallo crítico si no hay nada que deshabilitar
    if not run_command(f"a2enconf php{php_version}-fpm", f"Error al habilitar la configuración de php{php_version}-fpm."):
        return False
    if not run_command("systemctl restart apache2", "Error al reiniciar Apache2."):
        return False
    log_message(f"Apache configurado para usar PHP {php_version} FPM.", "green")
    return True

def install_phpmyadmin_gui():
    """Instala y configura phpMyAdmin."""
    log_message("\n--- Iniciando Instalación de phpMyAdmin ---")
    log_message("Intentando instalación no interactiva de phpMyAdmin. Esto puede requerir contraseñas si no se configuran previamente.", "orange")
    
    # Intento de preconfiguración para instalación no interactiva.
    # ADVERTENCIA: Usar contraseñas en el script no es seguro para entornos de producción.
    # En un entorno real, es mejor que el usuario las introduzca o se generen de forma segura.
    run_command("debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'", "Error setting debconf for phpmyadmin (dbconfig-install).")
    run_command("debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password root'", "Error setting debconf for phpmyadmin (app-password-confirm).")
    run_command("debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password root'", "Error setting debconf for phpmyadmin (mysql/admin-pass).")
    run_command("debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password root'", "Error setting debconf for phpmyadmin (mysql/app-pass).")
    run_command("debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'", "Error setting debconf for phpmyadmin (reconfigure-webserver).")
    
    if not install_package("phpmyadmin"):
        return False
    
    if not run_command("ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin", "Error al crear symlink para phpMyAdmin."):
        return False
    if not run_command("systemctl restart apache2", "Error al reiniciar Apache después de phpMyAdmin."):
        return False
    log_message("phpMyAdmin instalado. Acceso en http://your_server_ip/phpmyadmin", "green")
    return True

# --- Lógica Principal de la GUI ---

def start_installation():
    """Función que se ejecuta al presionar el botón de instalación."""
    check_sudo()
    
    log_message("--- Iniciando el proceso de instalación ---", "purple")
    
    # Deshabilitar el botón de instalación para evitar múltiples clics
    install_button.config(state=tk.DISABLED)
    
    # 1. Instalar Apache
    if not install_apache_gui():
        log_message("Instalación de Apache fallida. Abortando.", "red")
        install_button.config(state=tk.NORMAL)
        return

    # 2. Instalar MySQL
    if not install_mysql_gui():
        log_message("Instalación de MySQL fallida. Abortando.", "red")
        install_button.config(state=tk.NORMAL)
        return

    # 3. Instalar Versiones de PHP seleccionadas
    selected_php_versions = []
    if var_php83.get():
        selected_php_versions.append("8.3")
    if var_php82.get():
        selected_php_versions.append("8.2")
    if var_php81.get():
        selected_php_versions.append("8.1")
    if var_php80.get():
        selected_php_versions.append("8.0")
    if var_php74.get():
        selected_php_versions.append("7.4")

    if not selected_php_versions:
        messagebox.showwarning("Advertencia", "No se seleccionó ninguna versión de PHP. Continuando sin instalar PHP.")
    else:
        for version in selected_php_versions:
            if not install_php_version_gui(version):
                log_message(f"Instalación de PHP {version} fallida. Abortando.", "red")
                install_button.config(state=tk.NORMAL)
                return
        
        # Configurar Apache con la primera versión de PHP seleccionada como predeterminada
        log_message(f"Configurando Apache para usar PHP {selected_php_versions[0]} como versión principal.", "purple")
        if not configure_apache_php_fpm_gui(selected_php_versions[0]):
            log_message("Configuración de Apache con PHP-FPM fallida. Abortando.", "red")
            install_button.config(state=tk.NORMAL)
            return

    # 4. Instalar phpMyAdmin
    if var_phpmyadmin.get():
        if not install_phpmyadmin_gui():
            log_message("Instalación de phpMyAdmin fallida. Abortando.", "red")
            install_button.config(state=tk.NORMAL)
            return
    else:
        log_message("Instalación de phpMyAdmin omitida por elección del usuario.", "blue")

    log_message("\n--- Proceso de Instalación Completado Exitosamente ---", "green")
    messagebox.showinfo("Instalación Completa", "¡Todos los componentes seleccionados han sido instalados!")
    log_message("Recuerda ejecutar 'sudo mysql_secure_installation' manualmente.", "orange")
    log_message("Accede a phpMyAdmin (si lo instalaste) en http://your_server_ip/phpmyadmin", "orange")
    install_button.config(state=tk.NORMAL) # Habilitar el botón de nuevo por si se quiere reintentar

# --- Configuración de la Interfaz Gráfica ---

root = tk.Tk()
root.title("Instalador LAMP para Ubuntu")
root.geometry("800x600")

# Marco para las opciones
options_frame = tk.LabelFrame(root, text="Opciones de Instalación", padx=10, pady=10)
options_frame.pack(pady=10, padx=10, fill="x")

# Variables para Checkbuttons de PHP
var_php83 = tk.BooleanVar(value=True) # PHP 8.3 por defecto
var_php82 = tk.BooleanVar(value=False)
var_php81 = tk.BooleanVar(value=False)
var_php80 = tk.BooleanVar(value=False)
var_php74 = tk.BooleanVar(value=False)

# Checkbuttons para PHP
tk.Label(options_frame, text="Selecciona versiones de PHP a instalar:").pack(anchor="w")
tk.Checkbutton(options_frame, text="PHP 8.3", variable=var_php83).pack(anchor="w")
tk.Checkbutton(options_frame, text="PHP 8.2", variable=var_php82).pack(anchor="w")
tk.Checkbutton(options_frame, text="PHP 8.1", variable=var_php81).pack(anchor="w")
tk.Checkbutton(options_frame, text="PHP 8.0", variable=var_php80).pack(anchor="w")
tk.Checkbutton(options_frame, text="PHP 7.4", variable=var_php74).pack(anchor="w")

# Checkbutton para phpMyAdmin
var_phpmyadmin = tk.BooleanVar(value=True) # phpMyAdmin por defecto
tk.Checkbutton(options_frame, text="Instalar phpMyAdmin", variable=var_phpmyadmin).pack(anchor="w", pady=(10,0))

# Botón de instalación
install_button = tk.Button(root, text="Iniciar Instalación", command=start_installation, bg="green", fg="white", font=("Arial", 12, "bold"))
install_button.pack(pady=10)

# Área de texto para logs
log_frame = tk.LabelFrame(root, text="Registro de Actividad", padx=5, pady=5)
log_frame.pack(pady=10, padx=10, fill="both", expand=True)

text_area = scrolledtext.ScrolledText(log_frame, wrap=tk.WORD, width=80, height=20, font=("Courier New", 10))
text_area.pack(fill="both", expand=True)
text_area.tag_config('green', foreground='green')
text_area.tag_config('red', foreground='red')
text_area.tag_config('blue', foreground='blue')
text_area.tag_config('orange', foreground='orange')
text_area.tag_config('purple', foreground='purple')
text_area.configure(state='disabled') # Hacer el área de texto de solo lectura

# Bucle principal de la GUI
root.mainloop()

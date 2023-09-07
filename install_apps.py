import tkinter as tk
import subprocess
import os

# Dictionary mapping official names to package names
software_mapping = {
    "7zip": "7-Zip",
    "adobereader": "Adobe Reader",
    "ccleaner": "CCleaner",
    "choco-upgrade-all-at": "Chocolatey Nightly Upgrade",
    "cpu-z": "CPU-Z",
    "ditto": "Ditto Clipboard Manager",
    "dotnet": ".NET Framework",
    "dotnet3.5": ".NET Framework 3.5",
    "dotnetfx": ".NET Framework 4.8",
    "everything": "Everything File Search",
    "firefox": "Firefox",
    "googlechrome": "Google Chrome",
    "hwinfo": "HWiNFO",
    "javaruntime": "Java Runtime",
    "libreoffice-fresh": "LibreOffice Fresh",
    "lightshot": "Lightshot Screen Capture",
    "microsoft-edge": "Microsoft Edge",
    "mobaxterm": "MobaXterm",
    "mremoteng": "mRemoteNG",
    "naps2": "NAPS2",
    "notepadplusplus": "Notepad++",
    "open-shell": "Open-Shell",
    "openjdk": "OpenJDK",
    "powershell": "PowerShell",
    "powershell-core": "PowerShell 7.x",
    "sysinternals": "Sysinternals Suite",
    "translucenttb": "TranslucentTB",
    "vcredist-all": "Visual C++ Redistributable",
    "vlc": "VLC Media Player",
    "zoom": "Zoom"
}

# List of software items and their installation parameters
software_items = [
    ("7zip", "--force"),
    ("adobereader", "--force --params '/DesktopIcon /UpdateMode:4'"),
    ("ccleaner", "--force"),
    ("choco-upgrade-all-at", "--force"),
    ("cpu-z", "--force"),
    ("ditto", "--force"),
    ("dotnet", "--force"),
    ("dotnet3.5", "--force"),
    ("dotnetfx", "--force"),
    ("everything", "--force"),
    ("firefox", "--force"),
    ("googlechrome", "--force"),
    ("hwinfo", "--force"),
    ("javaruntime", "--force"),
    ("libreoffice-fresh", "--force"),
    ("lightshot", "--force"),
    ("microsoft-edge", "--force"),
    ("mobaxterm", "--force"),
    ("mremoteng", "--force"),
    ("naps2", "--force"),
    ("notepadplusplus", "--force"),
    ("open-shell", "--params=\"/StartMenu\""),
    ("openjdk", "--force"),
    ("powershell", "--force"),
    ("powershell-core", "--force"),
    ("sysinternals", "-y"),
    ("translucenttb", "--force"),
    ("vcredist-all", "--force"),
    ("vlc", "--force"),
    ("zoom", "--force")
]
choco_path = r'c:\ProgramData\chocolatey\choco.exe'  # Chocolatey path

# Function to install selected software
def install_selected():
    for package_name, params, var in checkboxes:
        if var.get():
            subprocess.run([choco_path, "install", package_name, params])

# Create the main window
root = tk.Tk()
root.title("NetworkAbility Software Installer")

# Create a frame for the checkboxes
checkbox_frame = tk.Frame(root)
checkbox_frame.pack(padx=10, pady=10)

# Organize checkboxes into columns
num_columns = 3
checkboxes = []

for i, (package_name, params) in enumerate(software_items):
    var = tk.IntVar()
    official_name = software_mapping.get(package_name, package_name)  # Get the official name or use the package name
    checkbox = tk.Checkbutton(checkbox_frame, text=official_name, variable=var)
    row = i // num_columns
    column = i % num_columns
    checkbox.grid(row=row, column=column, sticky="w", padx=5, pady=5)
    checkboxes.append((package_name, params, var))

# Create install button
install_button = tk.Button(root, text="Install Selected", command=install_selected)
install_button.pack(pady=10)

# Function to exit the application
def exit_app():
    root.destroy()
    os._exit(0)  # Close the console window

# Create exit button
exit_button = tk.Button(root, text="Exit", command=exit_app)
exit_button.pack(pady=10)

# Start the main event loop
root.mainloop()

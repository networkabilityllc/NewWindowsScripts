import tkinter as tk
import subprocess
import os  # Import the os module


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
    ("sysinternals", "-y"),
    ("translucenttb", "--force"),
    ("vcredist-all", "--force"),
    ("vlc", "--force")
]
choco_path = r'c:\ProgramData\chocolatey\choco.exe'  # Chocolatey path

# Function to install selected software
def install_selected():
    for item, params, var in checkboxes:
        if var.get():
            subprocess.run([choco_path, "install", item, params])

# Create the main window
root = tk.Tk()
root.title("Chocolatey Installer")

# Create a frame for the checkboxes
checkbox_frame = tk.Frame(root)
checkbox_frame.pack(padx=10, pady=10)

# Organize checkboxes into columns
num_columns = 3
checkboxes = []

for i, (item, params) in enumerate(software_items):
    var = tk.IntVar()
    checkbox = tk.Checkbutton(checkbox_frame, text=item, variable=var)
    row = i // num_columns
    column = i % num_columns
    checkbox.grid(row=row, column=column, sticky="w", padx=5, pady=5)
    checkboxes.append((item, params, var))

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
# Start the main event loop
root.mainloop()

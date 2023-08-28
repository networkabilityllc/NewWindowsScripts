import tkinter as tk
import subprocess

# List of software items and their installation parameters
software_items = [
    ("7zip", "--force"),
    ("adobereader", "--force --params '/DesktopIcon /UpdateMode:4'"),
    ("ccleaner", "--force"),
    ("choco-upgrade-all-at", "--force"),
    ("cpu-z", "--force"),
    ("dotnet", "--force"),
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
    ("notepadplusplus", "--force"),
    ("open-shell", "--params=\"/StartMenu\""),
    ("openjdk", "--force"),
    ("powershell", "--force"),
    ("sysinternals", "-y"),
    ("vcredist-all", "--force"),
    ("vlc", "--force")
]


# Function to install selected software
def install_selected():
    for item, params, var in checkboxes:
        if var.get():
            subprocess.run(["choco", "install", item, params])

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

# Start the main event loop
root.mainloop()

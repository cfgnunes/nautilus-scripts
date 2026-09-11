import os
import subprocess
import urllib.parse
from gi.repository import Nautilus, GObject

SCRIPTS_DIR = os.path.expanduser("~/.local/share/nautilus/scripts")

class DynamicScriptsExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    def run_script(self, menu_item, script_path, files, current_folder):
        env = os.environ.copy()
        
        file_paths = []
        uris = []
        for f in files:
            if f.is_gone():
                continue
            uri = f.get_uri()
            uris.append(uri)
            if uri.startswith("file://"):
                path = urllib.parse.unquote(uri[7:])
                file_paths.append(path)
                
        env["NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"] = "\n".join(file_paths)
        env["NAUTILUS_SCRIPT_SELECTED_URIS"] = "\n".join(uris)
        
        if current_folder:
            folder_uri = current_folder.get_uri()
            env["NAUTILUS_SCRIPT_CURRENT_URI"] = folder_uri
            if folder_uri.startswith("file://"):
                cwd = urllib.parse.unquote(folder_uri[7:])
            else:
                cwd = os.path.expanduser("~")
        else:
            cwd = os.path.expanduser("~")
            
        subprocess.Popen([script_path], cwd=cwd, env=env)

    def matches_category(self, category, files):
        if not files:
            # Background (empty space) context menu
            return category in ["Clipboard", "Directories and Files", "Network and Internet", "Security and Recovery"]
            
        has_dir = any(f.is_directory() for f in files)
        has_image = any(f.get_mime_type().startswith("image/") for f in files)
        has_audio_video = any(f.get_mime_type().startswith("audio/") or f.get_mime_type().startswith("video/") for f in files)
        has_text = any(f.get_mime_type().startswith("text/") or f.get_mime_type() == "application/x-zerosize" for f in files)
        has_doc = any(
            f.get_mime_type().startswith("application/pdf") or
            f.get_mime_type().startswith("application/msword") or
            "vnd.openxmlformats" in f.get_mime_type() or
            "vnd.oasis.opendocument" in f.get_mime_type()
            for f in files
        )
        
        if category == "Image":
            return has_image
        if category == "Audio and Video":
            return has_audio_video
        if category == "Plain text":
            return has_text
        if category == "Document":
            return has_doc
        if category == "Directories and Files":
            return True
        if category == "Rename files":
            return True
        if category == "Clipboard":
            return True
            
        return True

    def build_menu(self, files, current_folder):
        if not os.path.exists(SCRIPTS_DIR):
            return []
            
        # Get list of categories (immediate subdirectories)
        categories = sorted([d for d in os.listdir(SCRIPTS_DIR) 
                             if os.path.isdir(os.path.join(SCRIPTS_DIR, d)) and not d.startswith(".")])
        
        menu_items = []
        
        for category in categories:
            if not self.matches_category(category, files):
                continue
                
            category_path = os.path.join(SCRIPTS_DIR, category)
            # Find executable scripts in category
            scripts = sorted([s for s in os.listdir(category_path)
                              if os.path.isfile(os.path.join(category_path, s)) 
                              and not s.startswith(".")
                              and os.access(os.path.join(category_path, s), os.X_OK)])
            
            if not scripts:
                continue
                
            # Create a submenu for this category
            sub_menu_item = Nautilus.MenuItem(
                name=f"DynamicScripts::{category}",
                label=category,
                tip=f"Scripts for {category}"
            )
            submenu = Nautilus.Menu()
            sub_menu_item.set_submenu(submenu)
            
            for script in scripts:
                script_path = os.path.join(category_path, script)
                item = Nautilus.MenuItem(
                    name=f"DynamicScripts::{category}::{script}",
                    label=script,
                    tip=f"Run {script}"
                )
                item.connect("activate", self.run_script, script_path, files, current_folder)
                submenu.append_item(item)
                
            menu_items.append(sub_menu_item)
            
        return menu_items

    def get_file_items(self, *args):
        files = args[-1]
        if not files:
            return []
            
        submenus = self.build_menu(files, None)
        if not submenus:
            return []
            
        root_item = Nautilus.MenuItem(
            name="DynamicScripts::Root",
            label="Dynamic Scripts",
            tip="Filter-enabled scripts"
        )
        root_menu = Nautilus.Menu()
        root_item.set_submenu(root_menu)
        for item in submenus:
            root_menu.append_item(item)
            
        return [root_item]

    def get_background_items(self, *args):
        current_folder = args[-1]
        submenus = self.build_menu([], current_folder)
        if not submenus:
            return []
            
        root_item = Nautilus.MenuItem(
            name="DynamicScripts::BgRoot",
            label="Dynamic Scripts",
            tip="Filter-enabled scripts"
        )
        root_menu = Nautilus.Menu()
        root_item.set_submenu(root_menu)
        for item in submenus:
            root_menu.append_item(item)
            
        return [root_item]

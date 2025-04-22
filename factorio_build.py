import json
import os
import zipfile


def get_gitignore_patterns():
    """Read and parse .gitignore file."""
    patterns = []
    if os.path.exists(".gitignore"):
        with open(".gitignore") as f:
            patterns = [
                line.strip()
                for line in f
                if line.strip() and not line.startswith("#")
            ]
    return patterns


def should_exclude(path, patterns):
    """Check if a path should be excluded based on gitignore patterns."""
    path_str = str(path)
    for pattern in patterns:
        if pattern.startswith("/"):
            if path_str.startswith(pattern[1:]):
                return True
        elif pattern.endswith("/"):
            if path_str.startswith(pattern):
                return True
        elif pattern in path_str:
            return True
    return False


def main():
    # Read info.json
    with open("info.json") as f:
        info = json.load(f)

    # Get mod name and version
    mod_name = info["name"]
    factorio_version = info["version"]

    # Create zip filename
    zip_filename = f"{mod_name}_{factorio_version}.zip"

    # Get Factorio mods directory
    appdata = os.getenv("APPDATA")
    if not appdata:
        raise OSError("APPDATA environment variable not found")

    mods_dir = os.path.join(appdata, "Factorio", "mods")
    if not os.path.exists(mods_dir):
        os.makedirs(mods_dir)

    # Get gitignore patterns
    ignore_patterns = get_gitignore_patterns()

    # Create zip file
    zip_path = os.path.join(mods_dir, zip_filename)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk("."):
            # Skip .git directory
            if ".git" in dirs:
                dirs.remove(".git")

            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, ".")

                # Skip if file should be excluded
                if should_exclude(rel_path, ignore_patterns):
                    continue

                # Create the new path inside the mod folder
                zip_path = os.path.join(mod_name, rel_path)

                # Add file to zip with the new path
                zipf.write(file_path, zip_path)

    print(f"Successfully created mod package: {os.path.join(mods_dir, zip_filename)}")


if __name__ == "__main__":
    main()

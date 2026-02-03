import json
import sys

def extract_packages_from_lockfile(lockfile_path, depsKey):
    try:
        with open(lockfile_path, "r", encoding="utf-8") as file:
            data = json.load(file)
            outerpkgs = data.get("packages",{})
            internal_packages =  outerpkgs[""]["workspaces"]

            packages = {}
            for int_pkgs in internal_packages:
                if int_pkgs in outerpkgs:
                    deps = outerpkgs[int_pkgs].get(depsKey, {})
                    for name, version in deps.items():
                        packages[name] = version

            return packages

    except Exception as e:
        print(f"Error reading file: {e}")
        return []

def update_package_json(package_path, depsKey, new_deps):
    try:
        with open(package_path, "r", encoding="utf-8") as file:
            data = json.load(file)
            data[depsKey] = new_deps;

        with open(package_path, "w", encoding="utf-8") as file:
            json.dump(data, file, indent=2)

    except Exception as e:
        print(f"Error reading file: {e}")
        return []


def main():

    lockfile_path = "./package-lock.json"
    package_path = "./package.json"

    pkgs = extract_packages_from_lockfile(lockfile_path, "dependencies")
    devPkgs = extract_packages_from_lockfile(lockfile_path,"devDependencies")

    if not pkgs:
        print("No packages found.")
        sys.exit(1)

    update_package_json(package_path, "dependencies", pkgs)
    update_package_json(package_path, "devDependencies", devPkgs)

if __name__ == "__main__":
    main()

import os
import subprocess
import sys
# ==============================
# Configuration Section
# ==============================

# Use '.' for current directory
# Example custom path:
# target_directory = "Week-02/rtl"
target_directory = "."

FORMATTER = "verible-verilog-format"
SUPPORTED_EXTENSIONS = (".v", ".sv")
IGNORE_DIRS = {
    ".git",
    ".venv",
    ".vscode",
    "__pycache__",
    "node_modules",
    "logs",
    "outputs",
}


def format_rtl_files(root_directory):
    """
    Search recursively through the specified root directory and automatically
    format all supported RTL files using Verible formatter.

    Features:
    - Supports Verilog (.v) and SystemVerilog (.sv)
    - Ignores unnecessary/system directories
    - Tracks successful and failed formatting operations
    - Generates final formatting summary
    """

    # File counters
    v_count = 0
    sv_count = 0

    # Formatting statistics 
    success_count = 0
    fail_count = 0

    print(f"🔍 Scanning directory: {root_directory} for RTL files...\n")

    # Traverse entire directory tree
    for root, dirs, files in os.walk(root_directory):
        # Remove ignored directories from traversal
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        for file in files:
            # Check supported extensions
            if file.endswith(SUPPORTED_EXTENSIONS):
                file_path = os.path.join(root, file)

                # Update extension counters
                if file.endswith(".v"):
                    v_count += 1
                else:
                    sv_count += 1

                print(f"🛠️ Formatting: {file_path}")

                try:
                    # Run Verible formatter
                    subprocess.run(
                        [FORMATTER, "--inplace", file_path],
                        check=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )
                    success_count += 1

                except FileNotFoundError:
                    print(
                        f"\n❌ Error: '{FORMATTER}' tool was not found on your system!"
                    )
                    print("Please make sure it is installed and added to your PATH.")
                    sys.exit(1)

                except Exception as e:
                    fail_count += 1
                    print(f"⚠️ Warning: Failed to format {file}")
                    print(f"   Error: {e.stderr.decode(errors='ignore').strip()}")

    # Final Report
    print("\n" + "=" * 50)
    print("✨ RTL Code Formatting Completed! ✨")
    print("=" * 50)

    print(f"📊 Total Verilog (.v) files found        : {v_count}")
    print(f"📊 Total SystemVerilog (.sv) files found : {sv_count}")
    print(f"✅ Successfully formatted files          : {success_count}")
    print(f"❌ Failed formatting attempts            : {fail_count}")
    print(f"🚀 Total Files Processed                 : {success_count + fail_count}")

    print("=" * 50)


if __name__ == "__main__":
    format_rtl_files(target_directory)

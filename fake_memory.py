#!/usr/bin/env -S auto-claude/.venv/bin/python
"""
Fake Memory Generator for Graphiti
==================================

This script allows you to manually inject "fake" memories into the Graphiti
knowledge graph for testing purposes. It bypasses the agent loop and writes
directly to FalkorDB via the Graphiti Python client.

IMPORTANT: This script must be run from the Auto-Claude project root directory
and uses the Python virtual environment in auto-claude/.venv/

Usage:
    # Add a session insight
    python fake_memory.py --spec-dir .auto-claude/specs/001-test \
        --type insight --content "Successfully implemented authentication using JWT tokens"

    # Add a code pattern
    python fake_memory.py --spec-dir .auto-claude/specs/001-test \
        --type pattern --content "Always validate user input before database queries"

    # Add a gotcha
    python fake_memory.py --spec-dir .auto-claude/specs/001-test \
        --type gotcha --content "Remember to close Redis connections in background workers"

    # Add a discovery
    python fake_memory.py --spec-dir .auto-claude/specs/001-test \
        --type discovery --content "src/auth.py handles JWT token validation" \
        --file-path "src/auth.py"

    # Test connectivity
    python fake_memory.py --test

Alternative if shebang doesn't work:
    auto-claude/.venv/bin/python fake_memory.py --test
"""

import asyncio
import argparse
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

# Load .env file before importing Auto-Claude modules
try:
    from dotenv import load_dotenv
    # Try to load from auto-claude/.env first
    env_path = Path(__file__).parent / "auto-claude" / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        print(f"✓ Loaded environment from {env_path}")
    else:
        # Try current directory
        load_dotenv()
        print("✓ Loaded environment from .env")
except ImportError:
    print("Warning: python-dotenv not installed. Install with: pip install python-dotenv")

# Add auto-claude to sys.path to allow imports from integrations
sys.path.insert(0, os.path.join(os.getcwd(), "auto-claude"))

try:
    from integrations.graphiti.queries_pkg.graphiti import GraphitiMemory
    from integrations.graphiti.queries_pkg.schema import GroupIdMode
    from integrations.graphiti.config import GraphitiConfig, get_graphiti_status
except ImportError as e:
    print(f"Error: Could not find Graphiti modules.")
    print(f"Import error: {e}")
    print()
    print("Make sure you:")
    print("  1. Run this from the Auto-Claude project root directory")
    print("  2. Use the venv Python: auto-claude/.venv/bin/python fake_memory.py --test")
    print("  3. Have installed dependencies: cd auto-claude && uv pip install -r requirements.txt")
    sys.exit(1)


async def test_connectivity():
    """Test connectivity to FalkorDB and Graphiti configuration."""
    print("=" * 70)
    print("  GRAPHITI CONNECTIVITY TEST")
    print("=" * 70)
    print()

    # Check configuration
    config = GraphitiConfig.from_env()
    print(f"✓ Configuration loaded")
    print(f"  - Enabled: {config.enabled}")
    print(f"  - FalkorDB: {config.falkordb_host}:{config.falkordb_port}")
    print(f"  - Database: {config.database}")
    print(f"  - LLM Provider: {config.llm_provider}")
    print(f"  - Embedder Provider: {config.embedder_provider}")
    print()

    # Check if configuration is valid
    if not config.is_valid():
        errors = config.get_validation_errors()
        print("✗ Configuration validation failed:")
        for error in errors:
            print(f"  - {error}")
        return False

    print("✓ Configuration is valid")
    print()

    # Try to connect to FalkorDB
    print("Testing FalkorDB connection...")
    try:
        from falkordb import FalkorDB
        db = FalkorDB(
            host=config.falkordb_host,
            port=config.falkordb_port,
            password=config.falkordb_password or None
        )
        # Try to access the graph
        graph = db.select_graph(config.database)
        print(f"✓ Connected to FalkorDB")
        print(f"  - Graph: {config.database}")
        print()
    except Exception as e:
        print(f"✗ Failed to connect to FalkorDB: {e}")
        return False

    # Check Graphiti status
    print("Checking Graphiti status...")
    status = get_graphiti_status()
    print(f"✓ Graphiti status:")
    print(f"  - Available: {status['available']}")
    print(f"  - Reason: {status.get('reason', 'N/A')}")
    print()

    print("=" * 70)
    print("  ALL CHECKS PASSED ✓")
    print("=" * 70)
    return True


async def create_fake_memory(
    spec_path: str,
    content: str,
    memory_type: str,
    file_path: str | None = None
):
    """Create a fake memory in Graphiti."""
    spec_dir = Path(spec_path)
    project_dir = Path.cwd()

    if not spec_dir.exists():
        print(f"Error: Spec directory {spec_dir} does not exist.")
        print(f"Tried: {spec_dir.absolute()}")
        return False

    print(f"Initializing Graphiti Memory...")
    print(f"  - Spec: {spec_dir.name}")
    print(f"  - Project: {project_dir.name}")
    print()

    # Initialize Graphiti Memory
    memory = GraphitiMemory(
        spec_dir=spec_dir,
        project_dir=project_dir,
        group_id_mode=GroupIdMode.SPEC
    )

    config = memory.config
    print(f"Connecting to Graphiti...")
    print(f"  - FalkorDB: {config.falkordb_host}:{config.falkordb_port}")
    print(f"  - Database: {config.database}")
    print(f"  - Group ID: {memory.group_id}")
    print()

    if not await memory.initialize():
        print("✗ Failed to initialize Graphiti.")
        print()
        print("Troubleshooting:")
        print("  1. Check if FalkorDB is running:")
        print("     docker ps | grep falkordb")
        print("  2. Check if OPENAI_API_KEY is set:")
        print("     echo $OPENAI_API_KEY")
        print("  3. Check configuration:")
        print("     python fake_memory.py --test")
        return False

    try:
        success = False
        timestamp = datetime.now(timezone.utc).isoformat()

        if memory_type == "insight":
            print(f"Adding session insight...")
            success = await memory.save_session_insights(
                session_num=999,  # High number to indicate manual injection
                insights={
                    "subtasks_completed": ["Manual Memory Injection"],
                    "discoveries": {"manual_test": content},
                    "what_worked": ["Direct API injection via fake_memory.py"],
                    "what_failed": [],
                    "recommendations_for_next_session": [
                        "Verify this memory appears in the UI under Context > Memories"
                    ],
                    "timestamp": timestamp
                }
            )

        elif memory_type == "pattern":
            print(f"Adding code pattern...")
            success = await memory.save_pattern(content)

        elif memory_type == "gotcha":
            print(f"Adding gotcha...")
            success = await memory.save_gotcha(content)

        elif memory_type == "discovery":
            print(f"Adding codebase discovery...")
            if file_path:
                success = await memory.save_codebase_discoveries({file_path: content})
            else:
                success = await memory.save_codebase_discoveries({
                    "manual_injection.py": content
                })

        if success:
            print()
            print("=" * 70)
            print("  ✓ MEMORY INJECTED SUCCESSFULLY!")
            print("=" * 70)
            print()
            print("Next steps:")
            print("  1. Open the Auto-Claude UI")
            print("  2. Navigate to: Context > Memories tab")
            print("  3. You should see your injected memory in the 'Recent Memories' list")
            print()
            print(f"Memory details:")
            print(f"  - Type: {memory_type}")
            print(f"  - Content: {content[:80]}{'...' if len(content) > 80 else ''}")
            print(f"  - Spec: {spec_dir.name}")
            print()
            return True
        else:
            print()
            print("✗ Failed to inject memory.")
            print("Check the logs above for details.")
            return False

    except Exception as e:
        print()
        print(f"✗ Error injecting memory: {e}")
        import traceback
        print()
        print("Full traceback:")
        traceback.print_exc()
        return False

    finally:
        await memory.close()


def main():
    parser = argparse.ArgumentParser(
        description="Inject fake memories into Graphiti for testing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test connectivity
  python fake_memory.py --test

  # Add a session insight
  python fake_memory.py --spec-dir .auto-claude/specs/001-auth \\
      --type insight \\
      --content "Successfully implemented JWT authentication with refresh tokens"

  # Add a code pattern
  python fake_memory.py --spec-dir .auto-claude/specs/001-auth \\
      --type pattern \\
      --content "Always hash passwords with bcrypt before storing"

  # Add a gotcha
  python fake_memory.py --spec-dir .auto-claude/specs/001-auth \\
      --type gotcha \\
      --content "JWT tokens must be revoked on logout to prevent replay attacks"

  # Add a file discovery
  python fake_memory.py --spec-dir .auto-claude/specs/001-auth \\
      --type discovery \\
      --file-path "src/api/auth.py" \\
      --content "Handles JWT token generation, validation, and refresh logic"
        """
    )

    parser.add_argument(
        "--test",
        action="store_true",
        help="Test connectivity to Graphiti/FalkorDB without injecting memories"
    )

    parser.add_argument(
        "--spec-dir",
        help="Path to spec directory (e.g. .auto-claude/specs/001-task)"
    )

    parser.add_argument(
        "--content",
        help="The text content of the memory"
    )

    parser.add_argument(
        "--type",
        choices=["insight", "pattern", "gotcha", "discovery"],
        default="insight",
        help="Type of memory to inject (default: insight)"
    )

    parser.add_argument(
        "--file-path",
        help="File path for discovery type (optional, used with --type discovery)"
    )

    args = parser.parse_args()

    # Handle test mode
    if args.test:
        success = asyncio.run(test_connectivity())
        sys.exit(0 if success else 1)

    # Validate required arguments
    if not args.spec_dir:
        print("Error: --spec-dir is required (unless using --test)")
        print()
        print("Usage:")
        print("  python fake_memory.py --test")
        print("  python fake_memory.py --spec-dir .auto-claude/specs/001-task --content 'Memory content'")
        print()
        print("Run 'python fake_memory.py --help' for more examples")
        sys.exit(1)

    if not args.content:
        print("Error: --content is required")
        print()
        print("Example:")
        print("  python fake_memory.py --spec-dir .auto-claude/specs/001-task \\")
        print("      --content 'Successfully implemented authentication'")
        sys.exit(1)

    # Check for OpenAI Key (required for Graphiti)
    if not os.environ.get("OPENAI_API_KEY"):
        print("Warning: OPENAI_API_KEY not found in environment.")
        print("Graphiti requires an OpenAI API key for embeddings.")
        print()
        print("Set it with:")
        print("  export OPENAI_API_KEY=sk-...")
        print()
        response = input("Continue anyway? (y/N): ")
        if response.lower() != 'y':
            sys.exit(1)
        print()

    # Run the memory injection
    success = asyncio.run(
        create_fake_memory(
            args.spec_dir,
            args.content,
            args.type,
            args.file_path
        )
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

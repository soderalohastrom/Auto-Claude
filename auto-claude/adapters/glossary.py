"""Glossary type definitions for framework adapters.

This module provides shared glossary definitions that map framework-specific
terminology to a unified vocabulary. Each adapter provides its own glossary
for UI display while using the unified data model internally.

Story 1.1: Create Adapter Infrastructure (AC: #4)
"""

from typing import TypedDict


class GlossaryTerms(TypedDict):
    """Type definition for framework glossary terms.

    Maps unified concepts to framework-specific display terminology.
    Used by the UI layer to display appropriate terms based on active framework.
    """

    workUnit: str  # "Epic" (BMAD) or "Phase" (Native)
    task: str  # "Story" (BMAD) or "Subtask" (Native)
    checkpoint: str  # "Task" (BMAD) or "Verification" (Native)


# Default glossaries for each supported framework
BMAD_GLOSSARY: GlossaryTerms = {
    "workUnit": "Epic",
    "task": "Story",
    "checkpoint": "Task",
}

NATIVE_GLOSSARY: GlossaryTerms = {
    "workUnit": "Phase",
    "task": "Subtask",
    "checkpoint": "Verification",
}

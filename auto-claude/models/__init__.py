"""Unified data models for cross-framework compatibility.

This package provides framework-agnostic data models that allow the UI
and core components to work with data from any supported planning
framework (BMAD Method, Native track).

Story 1.2: Create Unified Data Model (AC: #3)

Usage:
    ```python
    from models import (
        UnifiedStatus,
        Checkpoint,
        Task,
        WorkUnit,
        ProjectStatus,
        map_bmad_status,
        map_native_status,
    )

    # Create a task
    task = Task(
        id="1-1",
        title="Create adapter infrastructure",
        status=UnifiedStatus.COMPLETED,
    )

    # Map framework-specific status
    unified = map_bmad_status("in-progress")
    assert unified == UnifiedStatus.IN_PROGRESS
    ```
"""

from models.enums import UnifiedStatus
from models.unified import (
    Checkpoint,
    Task,
    WorkUnit,
    ProjectStatus,
    BMAD_STATUS_MAP,
    NATIVE_STATUS_MAP,
    map_bmad_status,
    map_native_status,
)

__all__ = [
    # Enum
    "UnifiedStatus",
    # Data classes
    "Checkpoint",
    "Task",
    "WorkUnit",
    "ProjectStatus",
    # Status mapping
    "BMAD_STATUS_MAP",
    "NATIVE_STATUS_MAP",
    "map_bmad_status",
    "map_native_status",
]

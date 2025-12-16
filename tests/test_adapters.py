"""Tests for the adapters module - Story 1.1: Create Adapter Infrastructure.

Tests validate:
1. FrameworkAdapter is abstract and cannot be instantiated directly
2. Factory raises clear error for unknown frameworks
3. GlossaryTerms has required keys
4. Adapters can be registered and retrieved
"""

import pytest
from pathlib import Path

from adapters import get_adapter, register_adapter, FrameworkAdapter
from adapters.glossary import GlossaryTerms, BMAD_GLOSSARY, NATIVE_GLOSSARY


class TestFrameworkAdapterABC:
    """Tests for the FrameworkAdapter abstract base class."""

    def test_framework_adapter_is_abstract(self):
        """FrameworkAdapter cannot be instantiated directly."""
        with pytest.raises(TypeError, match="Can't instantiate abstract class"):
            FrameworkAdapter()

    def test_framework_adapter_has_required_abstract_methods(self):
        """FrameworkAdapter defines all required abstract methods."""
        abstract_methods = FrameworkAdapter.__abstractmethods__
        assert "name" in abstract_methods
        assert "glossary" in abstract_methods
        assert "parse_work_units" in abstract_methods
        assert "parse_tasks" in abstract_methods
        assert "get_status" in abstract_methods


class TestAdapterFactory:
    """Tests for the adapter factory function."""

    def test_get_adapter_unknown_raises(self):
        """Factory raises ValueError for unknown framework names."""
        with pytest.raises(ValueError, match="Unknown framework"):
            get_adapter("nonexistent")

    def test_get_adapter_error_lists_available(self):
        """Error message includes list of available adapters."""
        try:
            get_adapter("nonexistent")
        except ValueError as e:
            assert "Available:" in str(e)


class TestAdapterRegistration:
    """Tests for adapter registration mechanism."""

    def test_adapter_registration(self):
        """Can register and retrieve adapters."""
        # Create a concrete test adapter
        class TestAdapter(FrameworkAdapter):
            @property
            def name(self) -> str:
                return "test"

            @property
            def glossary(self) -> dict[str, str]:
                return {"workUnit": "Test", "task": "TestTask", "checkpoint": "TestCheck"}

            def parse_work_units(self, project_path: Path) -> list:
                return []

            def parse_tasks(self, work_unit_id: str) -> list:
                return []

            def get_status(self, project_path: Path):
                return None

        # Register and retrieve
        register_adapter("test", TestAdapter)
        adapter = get_adapter("test")

        assert adapter is not None
        assert isinstance(adapter, FrameworkAdapter)
        assert adapter.name == "test"


class TestGlossaryTypes:
    """Tests for glossary type definitions."""

    def test_glossary_terms_has_required_keys(self):
        """GlossaryTerms TypedDict has workUnit, task, checkpoint keys."""
        required_keys = {"workUnit", "task", "checkpoint"}
        assert required_keys <= set(GlossaryTerms.__annotations__.keys())

    def test_bmad_glossary_valid(self):
        """BMAD_GLOSSARY has all required keys with correct values."""
        assert BMAD_GLOSSARY["workUnit"] == "Epic"
        assert BMAD_GLOSSARY["task"] == "Story"
        assert BMAD_GLOSSARY["checkpoint"] == "Task"

    def test_native_glossary_valid(self):
        """NATIVE_GLOSSARY has all required keys with correct values."""
        assert NATIVE_GLOSSARY["workUnit"] == "Phase"
        assert NATIVE_GLOSSARY["task"] == "Subtask"
        assert NATIVE_GLOSSARY["checkpoint"] == "Verification"

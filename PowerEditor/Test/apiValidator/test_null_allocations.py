import ctypes
import pytest

NPPM_ALLOCATECMDID = 2105
NPPM_ALLOCATEMARKER = 2106
NPPM_ALLOCATEINDICATOR = 2137

def get_npp_window():
    """Gets the window handle of the active Notepad++ instance."""
    hwnd = ctypes.windll.user32.FindWindowW("Notepad++", None)
    if not hwnd:
        pytest.fail("Notepad++ is not running.")
    return hwnd

def test_allocate_cmd_id_null():
    hwnd = get_npp_window()
    # Send the allocation message with null lParam (0)
    # Under fixed behavior, this returns FALSE (0) without crashing the editor
    result = ctypes.windll.user32.SendMessageW(hwnd, NPPM_ALLOCATECMDID, 1, 0)
    assert result == 0, "NPPM_ALLOCATECMDID should return 0 (FALSE)"
    
    # Assert that the window is still responsive/active (did not crash)
    assert ctypes.windll.user32.FindWindowW("Notepad++", None) != 0, "Notepad++ crashed"

def test_allocate_marker_null():
    hwnd = get_npp_window()
    result = ctypes.windll.user32.SendMessageW(hwnd, NPPM_ALLOCATEMARKER, 1, 0)
    assert result == 0, "NPPM_ALLOCATEMARKER should return 0 (FALSE)"
    assert ctypes.windll.user32.FindWindowW("Notepad++", None) != 0, "Notepad++ crashed"

def test_allocate_indicator_null():
    hwnd = get_npp_window()
    result = ctypes.windll.user32.SendMessageW(hwnd, NPPM_ALLOCATEINDICATOR, 1, 0)
    assert result == 0, "NPPM_ALLOCATEINDICATOR should return 0 (FALSE)"
    assert ctypes.windll.user32.FindWindowW("Notepad++", None) != 0, "Notepad++ crashed"

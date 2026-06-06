#include <windows.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE previous,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  MessageBoxW(nullptr, L"HeiTang Knowledge Workbench Flutter Windows scaffold", L"HeiTang Workbench", MB_OK);
  return 0;
}

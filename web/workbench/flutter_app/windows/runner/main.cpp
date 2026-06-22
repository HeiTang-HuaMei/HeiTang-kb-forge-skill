#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <memory>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kSingleInstanceMutexName[] =
    L"Local\\HeiTangKnowledgeWorkbenchSingleInstance";
constexpr wchar_t kWindowTitleNeedle[] = L"HeiTang Workbench";

struct HandleCloser {
  void operator()(HANDLE handle) const {
    if (handle != nullptr) {
      ::CloseHandle(handle);
    }
  }
};

using UniqueHandle =
    std::unique_ptr<std::remove_pointer<HANDLE>::type, HandleCloser>;

BOOL CALLBACK ActivateExistingWindow(HWND hwnd, LPARAM lparam) {
  if (!::IsWindowVisible(hwnd)) {
    return TRUE;
  }

  wchar_t title[256] = {};
  ::GetWindowTextW(hwnd, title, static_cast<int>(std::size(title)));
  if (wcsstr(title, kWindowTitleNeedle) == nullptr) {
    return TRUE;
  }

  DWORD target_process_id = static_cast<DWORD>(lparam);
  DWORD window_process_id = 0;
  ::GetWindowThreadProcessId(hwnd, &window_process_id);
  if (window_process_id == target_process_id) {
    return TRUE;
  }

  if (::IsIconic(hwnd)) {
    ::ShowWindow(hwnd, SW_RESTORE);
  } else {
    ::ShowWindow(hwnd, SW_SHOWNORMAL);
  }
  ::SetForegroundWindow(hwnd);
  return FALSE;
}

bool ActivateAlreadyRunningInstance() {
  const DWORD current_process_id = ::GetCurrentProcessId();
  ::EnumWindows(ActivateExistingWindow,
                static_cast<LPARAM>(current_process_id));
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  UniqueHandle single_instance_mutex(
      ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName));
  if (!single_instance_mutex) {
    return EXIT_FAILURE;
  }
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ActivateAlreadyRunningInstance();
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"HeiTang Workbench", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

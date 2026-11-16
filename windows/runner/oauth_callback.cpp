#include "oauth_callback.h"

#include <algorithm>
#include <string>

namespace {

constexpr wchar_t kOAuthReceiver[] = L"Oculum.OAuthCallbackReceiver";
constexpr size_t kMaxCallbackBytes = 8192;

struct CallbackProtocol {
  const wchar_t* scheme;
  const char* redirect;
};

std::wstring ExecutablePath() {
  std::wstring path(32768, L'\0');
  const auto length = GetModuleFileNameW(
      nullptr, path.data(), static_cast<DWORD>(path.size()));
  if (length == 0 || length >= path.size()) return {};
  path.resize(length);
  return path;
}

CallbackProtocol ProtocolFor(const std::wstring& path) {
  const auto name = path.substr(path.find_last_of(L"\\/") + 1);
  if (CompareStringOrdinal(name.c_str(), -1, L"Oculum-Test.exe", -1, TRUE) ==
      CSTR_EQUAL) {
    return {L"com.mich.oculum.test", "com.mich.oculum.test://login-callback"};
  }
  return {L"com.mich.oculum", "com.mich.oculum://login-callback"};
}

bool IsCallback(std::string_view uri, std::string_view redirect) {
  if (uri.size() <= redirect.size() || uri.size() >= kMaxCallbackBytes ||
      uri.substr(0, redirect.size()) != redirect) {
    return false;
  }
  uri.remove_prefix(redirect.size());
  if (uri.front() == '/') uri.remove_prefix(1);
  return uri.size() > 1 && (uri.front() == '?' || uri.front() == '#') &&
         std::none_of(uri.begin(), uri.end(), [](unsigned char character) {
           return character <= ' ' || character >= 127 || character == '"';
         });
}

bool SetProtocolValue(const std::wstring& path, const wchar_t* value_name,
                      const std::wstring& value) {
  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return false;
  }
  const auto status = RegSetValueExW(
      key, value_name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
  return status == ERROR_SUCCESS;
}

struct OAuthReceiverSearch {
  std::wstring executable;
  HWND window = nullptr;
  ULONG_PTR registration = 0;
};

BOOL CALLBACK FindOAuthReceiver(HWND window, LPARAM argument) {
  auto& search = *reinterpret_cast<OAuthReceiverSearch*>(argument);
  const auto registration =
      reinterpret_cast<ULONG_PTR>(GetPropW(window, kOAuthReceiver));
  if (registration == 0 || registration <= search.registration) return TRUE;

  DWORD pid = 0;
  GetWindowThreadProcessId(window, &pid);
  HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (process == nullptr) return TRUE;

  std::wstring path(32768, L'\0');
  DWORD length = static_cast<DWORD>(path.size());
  const bool found = QueryFullProcessImageNameW(process, 0, path.data(), &length);
  CloseHandle(process);
  if (found &&
      CompareStringOrdinal(path.data(), static_cast<int>(length),
                           search.executable.c_str(),
                           static_cast<int>(search.executable.size()),
                           TRUE) == CSTR_EQUAL) {
    search.window = window;
    search.registration = registration;
  }
  return TRUE;
}

}  // namespace

bool RegisterOculumOAuthCallback(HWND window, std::string_view redirect) {
  const auto executable = ExecutablePath();
  if (window == nullptr || executable.empty()) return false;
  const auto protocol = ProtocolFor(executable);
  if (redirect != protocol.redirect) return false;

  const std::wstring key =
      L"Software\\Classes\\" + std::wstring(protocol.scheme);
  const std::wstring command = L"\"" + executable + L"\" \"%1\"";
  if (!SetProtocolValue(key, nullptr, L"URL:Oculum sign-in") ||
      !SetProtocolValue(key, L"URL Protocol", L"") ||
      !SetProtocolValue(key + L"\\shell\\open\\command", nullptr, command)) {
    return false;
  }
  const auto registration = static_cast<ULONG_PTR>(GetTickCount64()) | 1;
  return SetPropW(window, kOAuthReceiver,
                  reinterpret_cast<HANDLE>(registration)) != FALSE;
}

void UnregisterOculumOAuthReceiver(HWND window) {
  if (window != nullptr) RemovePropW(window, kOAuthReceiver);
}

bool IsOculumOAuthCallbackArgument(std::string_view uri) {
  const auto executable = ExecutablePath();
  return !executable.empty() && IsCallback(uri, ProtocolFor(executable).redirect);
}

bool ForwardOculumOAuthCallback(std::string_view uri) {
  OAuthReceiverSearch search{ExecutablePath()};
  if (search.executable.empty() ||
      !IsCallback(uri, ProtocolFor(search.executable).redirect)) {
    return false;
  }
  EnumWindows(FindOAuthReceiver, reinterpret_cast<LPARAM>(&search));
  if (search.window == nullptr) return false;

  std::string payload(uri);
  COPYDATASTRUCT data{};
  data.dwData = kOculumAppLinksMessage;
  data.cbData = static_cast<DWORD>(payload.size() + 1);
  data.lpData = payload.data();
  DWORD_PTR result = 0;
  if (!SendMessageTimeoutW(search.window, WM_COPYDATA, 0,
                           reinterpret_cast<LPARAM>(&data),
                           SMTO_ABORTIFHUNG | SMTO_BLOCK, 1500, &result) ||
      result != TRUE) {
    return false;
  }
  if (IsIconic(search.window)) ShowWindow(search.window, SW_RESTORE);
  SetForegroundWindow(search.window);
  return true;
}

bool IsOculumOAuthCallbackMessage(HWND window, const COPYDATASTRUCT& data) {
  if (GetPropW(window, kOAuthReceiver) == nullptr ||
      data.dwData != kOculumAppLinksMessage || data.lpData == nullptr ||
      data.cbData < 2 || data.cbData > kMaxCallbackBytes) {
    return false;
  }
  const auto* text = static_cast<const char*>(data.lpData);
  if (text[data.cbData - 1] != '\0') return false;
  return IsOculumOAuthCallbackArgument(std::string_view(text, data.cbData - 1));
}
